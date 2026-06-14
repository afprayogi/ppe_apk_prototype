import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_constants.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/yolo_service.dart';
import '../error/error_screen.dart';
import '../../models/detection_model.dart';
import '../../models/employee_model.dart';
import '../../providers/detection_provider.dart';
import '../../providers/employee_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

const _uuid = Uuid();

// ── Top-level compute function (harus di luar class) ─────────────────────────
Uint8List _yuv420ToRgbaCompute(Map<String, dynamic> args) {
  final Uint8List yp = args['y'] as Uint8List;
  final Uint8List up = args['u'] as Uint8List;
  final Uint8List vp = args['v'] as Uint8List;
  final int w           = args['w'] as int;
  final int h           = args['h'] as int;
  final int yStride     = args['yStride'] as int;
  final int uvStride    = args['uvStride'] as int;
  final int uvPixel     = args['uvPixel'] as int;

  final rgba = Uint8List(w * h * 4);
  for (int row = 0; row < h; row++) {
    for (int col = 0; col < w; col++) {
      final yIdx  = row * yStride + col;
      final uvIdx = (row >> 1) * uvStride + (col >> 1) * uvPixel;
      final yVal  = yp[yIdx];
      final uVal  = up[uvIdx] - 128;
      final vVal  = vp[uvIdx] - 128;

      final i = (row * w + col) * 4;
      rgba[i]     = (yVal + 1.402   * vVal).round().clamp(0, 255);
      rgba[i + 1] = (yVal - 0.34414 * uVal - 0.71414 * vVal).round().clamp(0, 255);
      rgba[i + 2] = (yVal + 1.772   * uVal).round().clamp(0, 255);
      rgba[i + 3] = 255;
    }
  }
  return rgba;
}

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  CameraController? _cam;
  bool   _cameraReady  = false;
  bool   _isProcessing = false;
  String _statusMsg    = 'Menginisialisasi kamera...';
  List<DetectionResult> _detections = [];
  DateTime _lastInference = DateTime(0);

  // Karyawan yang dipilih untuk scan (opsional)
  EmployeeModel? _selectedEmployee;

  // Adaptive throttle: mulai 1200ms, turun ke min 300ms sesuai kecepatan HP
  static const int _throttleMin = 300;
  static const int _throttleMax = 1200;
  int _throttleMs = 1000;

  @override
  void initState() {
    super.initState();
    _initCamera();
    // Cek karyawan setelah frame pertama render
    WidgetsBinding.instance.addPostFrameCallback((_) => _cekKaryawan());
  }

  Future<void> _cekKaryawan() async {
    if (!mounted) return;
    final employees = ref.read(employeeProvider).employees;
    if (employees.isEmpty) {
      // Belum ada karyawan → arahkan ke register
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Belum Ada Karyawan'),
          content: const Text('Daftarkan karyawan terlebih dahulu sebelum melakukan scan.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(_);
                Navigator.pushReplacementNamed(context, AppConstants.routeRegister);
              },
              child: const Text('Daftar Sekarang'),
            ),
          ],
        ),
      );
    } else {
      // Ada karyawan → paksa pilih jika belum ada yang dipilih
      if (_selectedEmployee == null) await _pickEmployee();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) { _setStatus('Tidak ada kamera'); return; }

      // ResolutionPreset.low (~320×240) → YUV frame lebih kecil, lebih cepat diproses
      // takePicture() tetap menggunakan resolusi kamera penuh secara native
      _cam = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cam!.initialize();
      if (!mounted) return;
      setState(() {
        _cameraReady = true;
        final svc = YoloService.instance;
        _statusMsg   = svc.isReady
            ? 'AI aktif | shape:${svc.outputShape} fmt:${svc.modelFormat}'
            : 'Model AI tidak aktif — periksa file best.tflite';
      });
      if (YoloService.instance.isReady) {
        await _cam!.startImageStream(_onFrame);
      }
    } catch (e, st) {
      _showError(e, st, 'Init Kamera');
    }
  }

  // ── Live detection — adaptive throttle ───────────────────────────────────
  Future<void> _onFrame(CameraImage image) async {
    if (_isProcessing) return;
    if (DateTime.now().difference(_lastInference).inMilliseconds < _throttleMs) return;
    _lastInference = DateTime.now();
    _isProcessing  = true;
    try {
      // Salin bytes sebelum await — kamera bisa reclaim buffer kapan saja
      final yBytes = Uint8List.fromList(image.planes[0].bytes);
      final uBytes = Uint8List.fromList(image.planes[1].bytes);
      final vBytes = Uint8List.fromList(image.planes[2].bytes);

      // Android NV21: plane[1]=V, plane[2]=U → swap agar jadi U,V yang benar
      // NV12 / iOS  : plane[1]=U, plane[2]=V → urutan sudah benar
      // Indikator: bytesPerPixel==2 berarti interleaved (Android → NV21)
      final uvInterleaved = (image.planes[1].bytesPerPixel ?? 1) == 2;

      final rgba = await compute(_yuv420ToRgbaCompute, {
        'y': yBytes,
        'u': uvInterleaved ? vBytes : uBytes,
        'v': uvInterleaved ? uBytes : vBytes,
        'w': image.width,  'h': image.height,
        'yStride':  image.planes[0].bytesPerRow,
        'uvStride': image.planes[1].bytesPerRow,
        'uvPixel':  image.planes[1].bytesPerPixel ?? 2,
      });
      final results = await YoloService.instance.detectFromRgba(
        rgbaBytes: rgba, srcWidth: image.width, srcHeight: image.height,
      );

      // Adaptive throttle: throttle = 1.5× inference time, clamp [min, max]
      final inf = YoloService.instance.lastInferenceMs;
      if (inf > 0) {
        _throttleMs = ((inf * 1.5).round())
            .clamp(_throttleMin, _throttleMax);
      }

      // Debug: lihat raw values dari output tensor
      final raw = YoloService.instance.debugFirstDetections;
      if (mounted) setState(() {
        _detections = results;
        _statusMsg  = raw.isNotEmpty ? raw : (YoloService.instance.isReady
            ? 'AI aktif — ${inf}ms${results.isEmpty ? " (tdk ada APD)" : " · ${results.length} objek"}'
            : 'Model AI tidak aktif');
      });
    } catch (e, st) {
      await _cam?.stopImageStream();
      _showError(e, st, 'Live Detection');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _cam?.stopImageStream().catchError((_) {});
    _cam?.dispose();
    super.dispose();
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMsg = msg);
  }

  Future<void> _pickEmployee() async {
    final employees = ref.read(employeeProvider).employees;
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada karyawan terdaftar')),
      );
      return;
    }

    final picked = await showModalBottomSheet<EmployeeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeePickerSheet(
        employees: employees,
        selected: _selectedEmployee,
      ),
    );

    if (picked != null && mounted) {
      // id kosong = user memilih "Tanpa Karyawan"
      setState(() => _selectedEmployee = picked.id.isEmpty ? null : picked);
    }
  }

  void _showError(Object e, StackTrace st, String ctx) {
    if (!mounted) return;
    setState(() { _isProcessing = false; _statusMsg = 'Error: $e'; });
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ErrorScreen(error: e, stackTrace: st, context: ctx),
    ));
  }

  // ── Pick dari galeri ─────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    if (_selectedEmployee == null) { await _pickEmployee(); return; }
    // Hentikan stream DULU sebelum buka gallery — OS sering melepas resource
    // kamera saat Activity berpindah, sehingga controller bisa jadi disposed.
    try { await _cam?.stopImageStream(); } catch (_) {}

    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);

    if (xFile == null || !mounted) {
      // User batal pilih — resume stream kembali
      if (_cameraReady && YoloService.instance.isReady) {
        try { await _cam?.startImageStream(_onFrame); } catch (_) {}
      }
      return;
    }

    _isProcessing = true;
    _setStatus('Memproses gambar dari galeri...');
    try {
      final bytes = await xFile.readAsBytes();
      final finalDetections = await YoloService.instance.detectFromBytes(bytes);
      if (finalDetections.isNotEmpty) _detections = finalDetections;
      await _processDetectionsAndNavigate(bytes);
    } catch (e, st) {
      _isProcessing = false;
      _showError(e, st, 'Gallery Pick');
      if (_cameraReady) {
        try { await _cam?.startImageStream(_onFrame); } catch (_) {}
      }
    }
  }

  // ── Capture & inference ───────────────────────────────────────────────────
  Future<void> _capture() async {
    if (_selectedEmployee == null) { await _pickEmployee(); return; }
    if (!_cameraReady || _cam == null) return;
    _isProcessing = true; // blok _onFrame selama capture
    _setStatus('Mengambil gambar...');
    try {
      await _cam!.stopImageStream();
      final xFile = await _cam!.takePicture();
      _setStatus('Memproses AI — mohon tunggu...');
      final bytes = await xFile.readAsBytes();

      final finalDetections = await YoloService.instance.detectFromBytes(bytes);
      if (finalDetections.isNotEmpty) _detections = finalDetections;
      await _processDetectionsAndNavigate(bytes);
    } catch (e, st) {
      _isProcessing = false;
      _showError(e, st, 'Capture');
      if (_cameraReady) await _cam?.startImageStream(_onFrame);
    }
  }

  // ── Shared: proses hasil deteksi → simpan → navigate ─────────────────────
  Future<void> _processDetectionsAndNavigate(Uint8List bytes) async {
    // requiredPpe = APD yang WAJIB dimiliki karyawan (dari data registrasi)
    final requiredPpe = _selectedEmployee?.requiredPpe ?? [];
    final detected = _detections
        .where((d) => d.isPpeDetected).map((d) => d.ppeName!).toSet().toList();
    // missing = hanya dari yang diwajibkan, bukan semua APD
    final missing = requiredPpe.where((p) => !detected.contains(p)).toList();
    final conf = _detections.isEmpty
        ? 0.0
        : _detections.map((d) => d.confidence).reduce((a, b) => a + b) /
            _detections.length;

    final overlaidBytes = await _drawOverlayOnJpeg(bytes, _detections);
    final recordId      = _uuid.v4();
    final imageToSave   = overlaidBytes ?? bytes;

    String? savedPath;
    try {
      savedPath = await ImageStorageService.saveScanImage(imageToSave, recordId);
    } catch (_) {}

    final record = DetectionRecord(
      id:           recordId,
      employeeId:   _selectedEmployee?.id   ?? 'unknown',
      employeeName: _selectedEmployee?.name ?? 'SCAN LANGSUNG',
      nia:          _selectedEmployee?.nia  ?? '-',
      detectedAt:   DateTime.now(),
      detectedPpe:  detected,
      missingPpe:   missing,
      status: missing.isEmpty
          ? DetectionStatus.complete
          : DetectionStatus.progress,
      overallConfidence: conf * 100,
      imageUrl: savedPath,
    );
    // Preview dulu — tidak langsung simpan ke DB
    ref.read(detectionProvider.notifier)
        .previewScan(record, imageBytes: imageToSave);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.routeResult);
    }
  }

  // Gambar bounding box di atas JPEG hasil capture
  Future<Uint8List?> _drawOverlayOnJpeg(
      Uint8List jpegBytes, List<DetectionResult> dets) async {
    try {
      final codec    = await ui.instantiateImageCodec(jpegBytes);
      final frame    = await codec.getNextFrame();
      final img      = frame.image;
      final recorder = ui.PictureRecorder();
      final canvas   = Canvas(recorder);
      canvas.drawImage(img, Offset.zero, Paint());

      final w = img.width.toDouble();
      final h = img.height.toDouble();
      final boxPaint = Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 3;

      for (final d in dets) {
        boxPaint.color = d.isMissing ? Colors.red : Colors.greenAccent;
        final rect = Rect.fromLTWH(
          d.left * w, d.top * h, d.width * w, d.height * h);
        canvas.drawRect(rect, boxPaint);

        // Label
        final tp = TextPainter(
          text: TextSpan(
            text: '${d.label} ${(d.confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: d.isMissing ? Colors.red : Colors.greenAccent,
              fontSize: 14, fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: rect.width + 60);
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top - 18, tp.width + 4, 18),
          Paint()..color = Colors.black54,
        );
        tp.paint(canvas, Offset(rect.left + 2, rect.top - 17));
      }

      img.dispose();
      final picture  = recorder.endRecording();
      final rendered = await picture.toImage(img.width, img.height);
      final bd       = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      return bd?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('VIVATPASS AI', style: AppTextStyles.headlineOnGreen),
        actions: [
          // Badge GPU / CPU
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: YoloService.instance.isReady
                    ? Colors.greenAccent.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: YoloService.instance.isReady
                      ? Colors.greenAccent : Colors.grey,
                  width: 1,
                ),
              ),
              child: Text(
                YoloService.instance.isReady
                    ? (YoloService.instance.lastInferenceMs > 0
                        ? '${YoloService.instance.lastInferenceMs}ms' : 'AI')
                    : 'OFF',
                style: TextStyle(
                  color: YoloService.instance.isReady
                      ? Colors.greenAccent : Colors.grey,
                  fontSize: 10.sp, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(right: 12.w),
            child: CircleAvatar(radius: 18.r,
              backgroundColor: AppColors.amber,
              child: Icon(Icons.person, color: AppColors.darkGreen, size: 20.sp))),
        ],
      ),
      body: Stack(children: [
        // Camera preview
        if (_cameraReady && _cam != null)
          SizedBox.expand(child: CameraPreview(_cam!))
        else
          Container(color: Colors.black87,
            child: const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))),

        // Bounding boxes live
        if (_detections.isNotEmpty)
          Positioned.fill(child: CustomPaint(painter: _BBoxPainter(detections: _detections))),

        // Date badge
        Positioned(top: 12, left: 14, child: _DateBadge()),

        // Employee badge — tap untuk ganti
        Positioned(
          top: 12, right: 70,
          child: GestureDetector(
            onTap: _pickEmployee,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _selectedEmployee != null
                    ? AppColors.darkGreen.withValues(alpha: 0.9)
                    : Colors.black54,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: _selectedEmployee != null
                      ? Colors.greenAccent
                      : Colors.white38,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedEmployee != null
                        ? Icons.person
                        : Icons.person_add_outlined,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _selectedEmployee != null
                        ? _selectedEmployee!.name.split(' ').first
                        : 'Pilih Pekerja',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: Colors.white, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Latensi badge kiri bawah area kamera
        if (YoloService.instance.isReady && YoloService.instance.lastInferenceMs > 0)
          Positioned(
            bottom: 52, left: 14,
            child: _LatencyBadge(ms: YoloService.instance.lastInferenceMs),
          ),

        // PPE chips — selalu tampil agar terlihat mana yang belum terdeteksi (merah)
        Positioned(top: 8, right: 8, child: _PpeStatusChips(
          detections: _detections,
          requiredPpe: _selectedEmployee?.requiredPpe ?? [],
        )),

        // Model tidak aktif — tampilkan alasan error
        if (!YoloService.instance.isReady)
          Positioned(top: 50, left: 14, right: 14,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8.w),
                    Text('Model AI Tidak Aktif',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                  if (YoloService.instance.lastError.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      YoloService.instance.lastError.length > 120
                          ? '${YoloService.instance.lastError.substring(0, 120)}...'
                          : YoloService.instance.lastError,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white70, fontSize: 9.sp),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () async {
                      _setStatus('Memuat ulang model AI...');
                      try {
                        await YoloService.instance.initialize();
                        if (mounted) {
                          setState(() {});
                          if (YoloService.instance.isReady && _cameraReady) {
                            await _cam?.startImageStream(_onFrame);
                          }
                        }
                      } catch (_) {
                        if (mounted) setState(() {});
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text('🔄 Coba Muat Ulang',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            )),

        // Processing spinner
        if (_isProcessing)
          Positioned(bottom: 90, right: 14,
            child: SizedBox(width: 18.w, height: 18.w,
              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))),

        // Status bar — warna sesuai kondisi
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            color: (_isProcessing
                ? Colors.blueGrey
                : YoloService.instance.isReady
                    ? AppColors.primaryGreen
                    : Colors.orange).withValues(alpha: 0.92),
            child: Text(_statusMsg,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          )),
      ]),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          switch (i) {
            case 0: Navigator.pop(context);
            case 1: Navigator.pushNamed(context, AppConstants.routeAbsensi);
            case 3: Navigator.pushNamed(context, AppConstants.routeTrain);
            case 4: Navigator.pushNamed(context, AppConstants.routeInfo);
          }
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tombol galeri
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: _isProcessing ? null : _pickFromGallery,
            backgroundColor: Colors.black54,
            mini: true,
            child: Icon(Icons.photo_library, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 16.w),
          // Tombol capture utama
          FloatingActionButton(
            heroTag: 'capture',
            onPressed: _isProcessing ? null : _capture,
            backgroundColor:
                _isProcessing ? Colors.grey : AppColors.primaryGreen,
            child: Icon(
                _isProcessing ? Icons.hourglass_top : Icons.camera_alt,
                color: Colors.white,
                size: 28.sp),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Latency Badge ─────────────────────────────────────────────────────────────
class _LatencyBadge extends StatelessWidget {
  final int ms;
  const _LatencyBadge({required this.ms});
  @override
  Widget build(BuildContext context) {
    final Color color = ms < 200
        ? Colors.greenAccent
        : ms < 500
            ? Colors.amber
            : Colors.redAccent;
    final String label = ms < 200
        ? '⚡ ${ms}ms'
        : ms < 500
            ? '🟡 ${ms}ms'
            : '🐢 ${ms}ms';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1),
      ),
      child: Text(label,
        style: TextStyle(color: color, fontSize: 10.sp,
            fontWeight: FontWeight.bold)),
    );
  }
}

// ── PPE chips ─────────────────────────────────────────────────────────────────
class _PpeStatusChips extends StatelessWidget {
  final List<DetectionResult> detections;
  final List<String> requiredPpe; // display names dari karyawan
  const _PpeStatusChips({required this.detections, required this.requiredPpe});

  @override
  Widget build(BuildContext context) {
    final detected = detections.where((d) => d.isPpeDetected)
        .map((d) => d.ppeName!).toSet();

    // Jika karyawan sudah dipilih → tampilkan sesuai requiredPpe karyawan
    // Jika belum → tampilkan dari enabled labels settings sebagai fallback
    final List<String> items = requiredPpe.isNotEmpty
        ? requiredPpe
        : kPpeLabelMap.entries
            .where((e) => SettingsService.instance.enabledLabels.contains(e.key))
            .map((e) => e.value)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: items.map((ppeName) {
        final ok = detected.contains(ppeName);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: ok
                ? Colors.green.withValues(alpha: 0.90)
                : Colors.red.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: ok ? Colors.greenAccent : Colors.redAccent,
              width: ok ? 1 : 1.5,
            ),
            boxShadow: ok ? null : [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 11.sp,
              ),
              SizedBox(width: 4.w),
              Text(ppeName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: ok ? FontWeight.w600 : FontWeight.w800,
                )),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DateBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: AppColors.primaryGreen.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(6.r)),
    child: Text(
      'Surabaya, ${DateFormat('dd - MM - yyyy').format(DateTime.now())}',
      style: AppTextStyles.labelSmall.copyWith(color: AppColors.white)),
  );
}

class _BBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;
  const _BBoxPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final color = d.isMissing ? Colors.red : Colors.greenAccent;
      final rect  = Rect.fromLTWH(
        d.left  * size.width,  d.top    * size.height,
        d.width * size.width,  d.height * size.height,
      );

      // Kotak utama — tebal & solid
      canvas.drawRect(rect, Paint()
        ..color = color ..style = PaintingStyle.stroke ..strokeWidth = 3);

      // Corner accents (pojok lebih tebal)
      final cLen = (rect.shortestSide * 0.15).clamp(8.0, 24.0);
      final cPaint = Paint()..color = color..strokeWidth = 5..style = PaintingStyle.stroke;
      _drawCorners(canvas, rect, cLen, cPaint);

      // Label background + text
      final label = '${d.label}  ${(d.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(
          color: Colors.white, fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
        )),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: size.width);

      final bgRect = Rect.fromLTWH(
          rect.left, rect.top - 20, tp.width + 8, 20);
      canvas.drawRect(bgRect, Paint()..color = color.withAlpha(200));
      tp.paint(canvas, Offset(rect.left + 4, rect.top - 18));
    }
  }

  void _drawCorners(Canvas c, Rect r, double len, Paint p) {
    // TL
    c.drawLine(r.topLeft, r.topLeft + Offset(len, 0), p);
    c.drawLine(r.topLeft, r.topLeft + Offset(0, len), p);
    // TR
    c.drawLine(r.topRight, r.topRight + Offset(-len, 0), p);
    c.drawLine(r.topRight, r.topRight + Offset(0, len), p);
    // BL
    c.drawLine(r.bottomLeft, r.bottomLeft + Offset(len, 0), p);
    c.drawLine(r.bottomLeft, r.bottomLeft + Offset(0, -len), p);
    // BR
    c.drawLine(r.bottomRight, r.bottomRight + Offset(-len, 0), p);
    c.drawLine(r.bottomRight, r.bottomRight + Offset(0, -len), p);
  }

  @override
  bool shouldRepaint(_BBoxPainter old) => old.detections != detections;
}

// ── Employee Picker Bottom Sheet ──────────────────────────────────────────────
class _EmployeePickerSheet extends StatefulWidget {
  final List<EmployeeModel> employees;
  final EmployeeModel? selected;
  const _EmployeePickerSheet(
      {required this.employees, required this.selected});

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.employees
        : widget.employees
            .where((e) =>
                e.name.toLowerCase().contains(_query.toLowerCase()) ||
                e.nia.contains(_query))
            .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Expanded(
                  child: Text('Pilih Karyawan',
                      style: AppTextStyles.titleLarge),
                ),
                // Clear selection
                if (widget.selected != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context,
                        EmployeeModel(
                            id: '', name: '', nia: '', address: '',
                            shift: '', requiredPpe: [])),
                    child: Text('Tanpa Karyawan',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.progressRed)),
                  ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama / NIA...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding: EdgeInsets.symmetric(
                    vertical: 8.h, horizontal: 12.w),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final emp      = filtered[i];
                final isActive = widget.selected?.id == emp.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive
                        ? AppColors.primaryGreen
                        : AppColors.surfaceGreen,
                    child: Icon(Icons.person,
                        color: isActive
                            ? AppColors.white
                            : AppColors.primaryGreen),
                  ),
                  title: Text(emp.name,
                      style: AppTextStyles.titleMedium),
                  subtitle: Text(
                      'NIA: ${emp.nia}  |  ${emp.shift}',
                      style: AppTextStyles.bodyMedium),
                  trailing: isActive
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primaryGreen)
                      : null,
                  onTap: () => Navigator.pop(context, emp),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
