import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'settings_service.dart';

// ── Labels ────────────────────────────────────────────────────────────────────
const List<String> kLabels = [
  'Gloves', 'Vest', 'goggles', 'helmet', 'mask', 'safety_shoe',
];
const Map<String, String> kPpeLabelMap = {
  'Gloves': 'Gloves',
  'Vest'  : 'Vest',
  'goggles': 'Glass',
  'helmet': 'Helmet',
  'mask'  : 'Mask',
  'safety_shoe': 'Boots',
};
const Map<String, String> kMissingLabelMap = {};

// ── DetectionResult ───────────────────────────────────────────────────────────
class DetectionResult {
  final String label;
  final double confidence;
  final double left, top, right, bottom;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double  get width         => right - left;
  double  get height        => bottom - top;
  bool    get isPpeDetected => kPpeLabelMap.containsKey(label);
  bool    get isMissing     => kMissingLabelMap.containsKey(label);
  String? get ppeName       => kPpeLabelMap[label] ?? kMissingLabelMap[label];
}

// ── Crash Report ──────────────────────────────────────────────────────────────
class CrashReportService {
  static const MethodChannel _ch = MethodChannel('com.vivatpass/crash');
  static Future<String?> getLastCrash() async {
    try   { return await _ch.invokeMethod<String>('getLastCrash'); }
    catch (_) { return null; }
  }
}

// ── Output format ─────────────────────────────────────────────────────────────
enum _OutputFmt {
  rawYoloHWC,      // [1, nRows, nAnch]  e.g. [1,10,8400]
  rawYoloCHW,      // [1, nAnch, nRows]  e.g. [1,8400,10]
  postNms6,        // [1, nDet, 6]       x1,y1,x2,y2,conf,cls
  postNmsMultiCls, // [1, nDet, 5+nCls]  x1,y1,x2,y2,conf,cls0..N
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-level functions — harus di luar class agar bisa dipanggil di compute
// ─────────────────────────────────────────────────────────────────────────────

/// Preprocess: RGBA bytes → Float32 HWC [H×W×3] normalized 0..1
/// Stretch ke 640×640 — sesuai cara Roboflow menyiapkan training data (semua sudah 640×640)
Float32List _preprocessCompute(Map<String, dynamic> args) {
  final Uint8List rgba = args['rgba'] as Uint8List;
  final int srcW = args['srcW'] as int;
  final int srcH = args['srcH'] as int;
  final int dstW = args['dstW'] as int;
  final int dstH = args['dstH'] as int;

  final out      = Float32List(dstH * dstW * 3);
  const inv255   = 1.0 / 255.0;

  if (srcW == dstW && srcH == dstH) {
    for (int i = 0, j = 0; i < srcW * srcH * 4; i += 4, j += 3) {
      out[j]     = rgba[i]     * inv255;
      out[j + 1] = rgba[i + 1] * inv255;
      out[j + 2] = rgba[i + 2] * inv255;
    }
  } else {
    final scaleX = srcW / dstW;
    final scaleY = srcH / dstH;
    for (int y = 0; y < dstH; y++) {
      final sy      = (y * scaleY).toInt().clamp(0, srcH - 1);
      final rowBase = sy * srcW;
      final dstRow  = y * dstW;
      for (int x = 0; x < dstW; x++) {
        final sx  = (x * scaleX).toInt().clamp(0, srcW - 1);
        final src = (rowBase + sx) * 4;
        final dst = (dstRow + x) * 3;
        out[dst]     = rgba[src]     * inv255;
        out[dst + 1] = rgba[src + 1] * inv255;
        out[dst + 2] = rgba[src + 2] * inv255;
      }
    }
  }
  return out;
}

/// Parse output tensor + NMS → List<DetectionResult>
List<DetectionResult> _parseAndNmsCompute(Map<String, dynamic> args) {
  final Float32List flat  = args['flat']  as Float32List;
  final int  fmtIdx       = args['fmt']   as int;
  final int  dim1         = args['dim1']  as int;
  final int  dim2         = args['dim2']  as int;
  final double confThr    = args['conf']  as double;
  final double iouThr     = args['iou']   as double;
  final bool normalized   = args['normalized'] as bool? ?? true;
  final bool swapped      = args['swapped']    as bool? ?? false;
  final Map<String, double> clsOverride =
      (args['clsOverride'] as Map?)?.cast<String, double>() ?? {};
  final Map<String, int> clsMaxDet =
      (args['clsMaxDet'] as Map?)?.cast<String, int>() ?? {};
  final _OutputFmt fmt    = _OutputFmt.values[fmtIdx];

  final boxes = <_Box>[];

  switch (fmt) {

    // ── [nDet × 6]: x1,y1,x2,y2,conf,classId ───────────────────────────────
    case _OutputFmt.postNms6:
      final clsCounts = <int, int>{}; // track jumlah per class
      for (int i = 0; i < dim1; i++) {
        final base = i * 6;
        if (base + 5 >= flat.length) break;
        final conf = swapped ? flat[base + 5] : flat[base + 4];
        final cls  = (swapped ? flat[base + 4] : flat[base + 5])
            .round().clamp(0, kLabels.length - 1);
        if (conf < confThr) continue;
        // Per-class confidence threshold
        final thr = clsOverride[cls.toString()] ?? confThr;
        if (conf < thr) continue;
        // Per-class max deteksi (cegah spam class bias)
        final maxDet = clsMaxDet[cls.toString()];
        if (maxDet != null) {
          final current = clsCounts[cls] ?? 0;
          if (current >= maxDet) continue;
        }
        clsCounts[cls] = (clsCounts[cls] ?? 0) + 1;
        final x1 = flat[base];     final y1 = flat[base + 1];
        final x2 = flat[base + 2]; final y2 = flat[base + 3];
        boxes.add(_Box(
          label: kLabels[cls], conf: conf,
          l: x1.clamp(0.0, 1.0), t: y1.clamp(0.0, 1.0),
          r: x2.clamp(0.0, 1.0), b: y2.clamp(0.0, 1.0),
        ));
      }
      // Post-NMS sudah di-NMS model → langsung return
      return _toResults(boxes);

    // ── [nDet × (5+nCls)]: x1,y1,x2,y2,conf,cls0..N ────────────────────────
    case _OutputFmt.postNmsMultiCls:
      final nCls = dim2 - 5;
      for (int i = 0; i < dim1; i++) {
        final base = i * dim2;
        if (base + dim2 - 1 >= flat.length) break;
        final conf = flat[base + 4];
        if (conf < confThr) continue;
        int bestCls = 0; double best = 0;
        for (int c = 0; c < nCls; c++) {
          final s = flat[base + 5 + c];
          if (s > best) { best = s; bestCls = c; }
        }
        if (bestCls >= kLabels.length) continue;
        final x1 = flat[base]; final y1 = flat[base + 1];
        final x2 = flat[base + 2]; final y2 = flat[base + 3];
        final sc = normalized ? 1.0 : 640.0;
        boxes.add(_Box(
          label: kLabels[bestCls], conf: conf,
          l: (x1 / sc).clamp(0.0, 1.0), t: (y1 / sc).clamp(0.0, 1.0),
          r: (x2 / sc).clamp(0.0, 1.0), b: (y2 / sc).clamp(0.0, 1.0),
        ));
      }
      return _toResults(boxes);

    // ── [nRows × nAnch]: cx,cy,w,h,cls0..N (transposed) — YOLOv8 [1,10,8400]
    case _OutputFmt.rawYoloHWC:
      final nAnch  = dim2;
      final numCls = dim1 - 4;
      final fHWC   = normalized ? 1.0 : 640.0;
      final clsCountsHWC = <int, int>{};
      for (int a = 0; a < nAnch; a++) {
        double maxConf = 0; int cls = 0;
        for (int c = 0; c < numCls; c++) {
          final idx = (4 + c) * nAnch + a;
          if (idx >= flat.length) break;
          final s = flat[idx];
          if (s > maxConf) { maxConf = s; cls = c; }
        }
        if (cls >= kLabels.length) continue;
        // Per-class confidence threshold
        final thr = clsOverride[cls.toString()] ?? confThr;
        if (maxConf < thr) continue;
        // Per-class max detections
        final maxDet = clsMaxDet[cls.toString()];
        if (maxDet != null && (clsCountsHWC[cls] ?? 0) >= maxDet) continue;
        clsCountsHWC[cls] = (clsCountsHWC[cls] ?? 0) + 1;
        final cx = flat[0 * nAnch + a];
        final cy = flat[1 * nAnch + a];
        final w  = flat[2 * nAnch + a];
        final h  = flat[3 * nAnch + a];
        boxes.add(_Box(
          label: kLabels[cls], conf: maxConf,
          l: ((cx - w / 2) / fHWC).clamp(0.0, 1.0),
          t: ((cy - h / 2) / fHWC).clamp(0.0, 1.0),
          r: ((cx + w / 2) / fHWC).clamp(0.0, 1.0),
          b: ((cy + h / 2) / fHWC).clamp(0.0, 1.0),
        ));
      }
      return _nms(boxes, iouThr);

    // ── [nAnch × nRows]: cx,cy,w,h,cls0..N (anchors-first) — YOLOv8 [1,8400,10]
    case _OutputFmt.rawYoloCHW:
      final nAnch  = dim1;
      final numCls = dim2 - 4;
      final fCHW   = normalized ? 1.0 : 640.0;
      final clsCountsCHW = <int, int>{};
      for (int a = 0; a < nAnch; a++) {
        final base = a * dim2;
        if (base + dim2 - 1 >= flat.length) break;
        double maxConf = 0; int cls = 0;
        for (int c = 0; c < numCls; c++) {
          final s = flat[base + 4 + c];
          if (s > maxConf) { maxConf = s; cls = c; }
        }
        if (cls >= kLabels.length) continue;
        final thr = clsOverride[cls.toString()] ?? confThr;
        if (maxConf < thr) continue;
        final maxDet = clsMaxDet[cls.toString()];
        if (maxDet != null && (clsCountsCHW[cls] ?? 0) >= maxDet) continue;
        clsCountsCHW[cls] = (clsCountsCHW[cls] ?? 0) + 1;
        final cx = flat[base]; final cy = flat[base + 1];
        final w  = flat[base + 2]; final h  = flat[base + 3];
        boxes.add(_Box(
          label: kLabels[cls], conf: maxConf,
          l: ((cx - w / 2) / fCHW).clamp(0.0, 1.0),
          t: ((cy - h / 2) / fCHW).clamp(0.0, 1.0),
          r: ((cx + w / 2) / fCHW).clamp(0.0, 1.0),
          b: ((cy + h / 2) / fCHW).clamp(0.0, 1.0),
        ));
      }
      return _nms(boxes, iouThr);
  }
}

List<DetectionResult> _toResults(List<_Box> boxes) =>
    boxes.map((b) => DetectionResult(
      label: b.label, confidence: b.conf,
      left: b.l, top: b.t, right: b.r, bottom: b.b,
    )).toList();

List<DetectionResult> _nms(List<_Box> boxes, double iouThr) {
  boxes.sort((a, b) => b.conf.compareTo(a.conf));
  final kept = <_Box>[];
  final used = List.filled(boxes.length, false);
  for (int i = 0; i < boxes.length; i++) {
    if (used[i]) continue;
    kept.add(boxes[i]);
    for (int j = i + 1; j < boxes.length; j++) {
      if (!used[j] && boxes[i].label == boxes[j].label &&
          _iou(boxes[i], boxes[j]) > iouThr) used[j] = true;
    }
  }
  return _toResults(kept);
}

double _iou(_Box a, _Box b) {
  final ix1  = a.l > b.l ? a.l : b.l;
  final iy1  = a.t > b.t ? a.t : b.t;
  final ix2  = a.r < b.r ? a.r : b.r;
  final iy2  = a.b < b.b ? a.b : b.b;
  final inter = (ix2 - ix1).clamp(0.0, 1.0) * (iy2 - iy1).clamp(0.0, 1.0);
  final union = (a.r - a.l) * (a.b - a.t) + (b.r - b.l) * (b.b - b.t) - inter;
  return union <= 0 ? 0 : inter / union;
}

// ── YoloService ───────────────────────────────────────────────────────────────
class YoloService {
  YoloService._();
  static final YoloService instance = YoloService._();

  // ── Model constants ────────────────────────────────────────────────────────
  static const int    _inH     = 640;
  static const int    _inW     = 640;
  static const double _conf    = 0.25;  // model baru sudah benar, standar 0.25
  static const double _iouThr  = 0.45;
  static const int    _threads = 4;

  // ── State ──────────────────────────────────────────────────────────────────
  Interpreter? _interp;
  bool         _useGpu          = false;
  bool         _isReady         = false;
  bool         get isReady      => _isReady;
  int          lastInferenceMs  = 0;
  String       lastError        = '';

  // Info model — bisa ditampilkan di UI
  String       modelName        = '';
  String       modelFormat      = '';  // "postNms6", "rawYoloHWC", etc.
  bool         coordNormalized  = true; // true=0..1, false=pixel
  List<int>    outputShape      = [];
  String       debugFirstDetections = '';
  String       debugRawDetections   = '';
  bool         clsConfSwapped       = false; // true = kolom 4=cls, 5=conf (swap)

  // Per-class confidence threshold (index sesuai kLabels)
  // Model [1,10,8400] rawYoloHWC: class score langsung tanpa objectness
  static const Map<int, double> _clsConfOverride = {
    // 0=Gloves  : disabled via settings, tidak perlu threshold
    1: 0.30,  // Vest         — 30% cukup untuk kamera HP
    3: 0.25,  // helmet       — standar
    5: 0.25,  // safety_shoe  — standar
  };
  static const Map<int, int> _clsMaxDet = {
    3: 3,     // helmet — max 3 (hindari spam)
    5: 4,     // safety_shoe — max 4
  };

  // Hasil diagnostik terakhir
  ModelDiagnostic? lastDiagnostic;

  // Output metadata — set setelah baca tensor shape
  late _OutputFmt _fmt;
  late int        _dim1;
  late int        _dim2;

  // Pre-alloc input buffer — hindari alokasi tiap frame
  final Float32List _inBuf = Float32List(_inH * _inW * 3);

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize({String modelName = 'best.tflite'}) async {
    _safeClose();
    _isReady = false;
    lastError = '';

    // Coba delegate: GPU (Android) → XNNPACK → plain CPU
    bool loaded = false;
    if (Platform.isAndroid) {
      try {
        final opts = InterpreterOptions()..threads = _threads;
        opts.addDelegate(GpuDelegateV2());
        _interp = await Interpreter.fromAsset('assets/models/$modelName', options: opts);
        _interp!.allocateTensors();
        _useGpu = true;
        loaded = true;
        debugPrint('YoloService: GPU delegate OK');
      } catch (e) {
        debugPrint('YoloService: GPU gagal ($e)');
        _safeClose();
      }
    }
    if (!loaded) {
      try {
        final opts = InterpreterOptions()..threads = _threads;
        opts.addDelegate(XNNPackDelegate());
        _interp = await Interpreter.fromAsset('assets/models/$modelName', options: opts);
        _interp!.allocateTensors();
        loaded = true;
        debugPrint('YoloService: XNNPACK delegate OK');
      } catch (e) {
        debugPrint('YoloService: XNNPACK gagal ($e)');
        _safeClose();
      }
    }
    if (!loaded) {
      // Plain CPU sebagai last resort
      final opts = InterpreterOptions()..threads = _threads;
      _interp = await Interpreter.fromAsset('assets/models/$modelName', options: opts);
      _interp!.allocateTensors();
      debugPrint('YoloService: plain CPU');
    }

    try {
      final outShapeList = _interp!.getOutputTensor(0).shape;
      outputShape = List<int>.from(outShapeList);
      debugPrint('YoloService: output=$outputShape');

      _detectOutputFormat(outputShape);
      modelFormat = '$_fmt  [$_dim1×$_dim2]';

      // Model ini: rawYoloHWC [1,10,8400] — koordinat sudah normalized 0..1
      coordNormalized = true;
      clsConfSwapped  = false;

      _isReady = true;
      await _warmup();

    } catch (e, st) {
      _isReady  = false;
      lastError = e.toString();
      debugPrint('YoloService ERROR: $e\n$st');
      rethrow;
    }
  }

  // ── Deteksi format output dari shape tensor ────────────────────────────────
  void _detectOutputFormat(List<int> shape) {
    // shape selalu [1, dim1, dim2] atau [1, dim1]
    final s1 = shape.length > 1 ? shape[1] : 0;
    final s2 = shape.length > 2 ? shape[2] : 0;

    debugPrint('YoloService: _detectOutputFormat s1=$s1 s2=$s2');

    if (s2 == 6) {
      // [nDet, 6]: x1,y1,x2,y2,conf,classId — post-NMS
      _fmt = _OutputFmt.postNms6;
      _dim1 = s1; _dim2 = 6;
    } else if (s1 > 0 && s1 <= 20 && s2 > 100) {
      // [4+nCls, nAnch]: YOLOv8 raw transposed — e.g. [10, 8400]
      _fmt = _OutputFmt.rawYoloHWC;
      _dim1 = s1; _dim2 = s2;
    } else if (s1 > 100 && s2 > 4 && s2 <= 20) {
      // [nAnch, 4+nCls]: YOLOv8 raw anchors-first — e.g. [8400, 10]
      _fmt = _OutputFmt.rawYoloCHW;
      _dim1 = s1; _dim2 = s2;
    } else if (s2 > 6 && s2 <= 85 && s1 <= 300) {
      // [nDet, 5+nCls]: post-NMS multi-class (sedikit deteksi)
      _fmt = _OutputFmt.postNmsMultiCls;
      _dim1 = s1; _dim2 = s2;
    } else {
      // Fallback: anggap anchors-first
      _fmt = _OutputFmt.rawYoloCHW;
      _dim1 = s1; _dim2 = s2 > 0 ? s2 : 1;
    }
    debugPrint('YoloService: format=$_fmt  dim1=$_dim1  dim2=$_dim2');
  }

  // ── Warmup + validasi koordinat + auto-detect swap ────────────────────────
  Future<void> _warmup() async {
    try {
      for (int i = 0; i < 2; i++) {
        _inBuf.fillRange(0, _inBuf.length, 0.0);
        final t0  = DateTime.now().millisecondsSinceEpoch;
        final out = _runInferenceSync();
        if (i == 1) {
          lastInferenceMs = DateTime.now().millisecondsSinceEpoch - t0;
          _detectCoordFormat(out);
          // clsConfSwapped TIDAK di-auto-detect — warmup pakai input zeros
          // sehingga col4=0.0 (integer-like) dan col5=1.0 → false positive swap.
          // Model sudah dikonfirmasi: col4=conf(0-1), col5=cls(integer). Hardcode false.
          final preview = out.take(12).map((v) => v.toStringAsFixed(3)).join(', ');
          debugPrint('YoloService: out[0..11]=[$preview]');
        }
      }
      debugPrint('YoloService: warmup OK ${lastInferenceMs}ms '
          'coords=${coordNormalized?"norm":"px"} swap=$clsConfSwapped gpu=$_useGpu');
    } catch (e) {
      debugPrint('YoloService: warmup error (non-fatal): $e');
    }
  }

  void _detectCoordFormat(Float32List flat) {
    double maxCoord = 0;

    if (_fmt == _OutputFmt.postNms6 || _fmt == _OutputFmt.postNmsMultiCls) {
      // Format post-NMS: cek kolom x2, y2 (index 2 & 3)
      final step = _fmt == _OutputFmt.postNms6 ? 6 : _dim2;
      for (int i = 0; i < _dim1; i++) {
        final base = i * step;
        if (base + 3 >= flat.length) break;
        if (flat[base + 2] > maxCoord) maxCoord = flat[base + 2];
        if (flat[base + 3] > maxCoord) maxCoord = flat[base + 3];
      }
    } else if (_fmt == _OutputFmt.rawYoloHWC) {
      // Format [rows × anchors]: row 0=cx, row 2=w — cek nilai cx
      final nAnch = _dim2;
      for (int a = 0; a < nAnch && a < 200; a++) {
        final cx = flat[0 * nAnch + a];
        if (cx > maxCoord) maxCoord = cx;
      }
    } else if (_fmt == _OutputFmt.rawYoloCHW) {
      // Format [anchors × rows]: col 0=cx
      for (int a = 0; a < _dim1 && a < 200; a++) {
        final cx = flat[a * _dim2];
        if (cx > maxCoord) maxCoord = cx;
      }
    }

    coordNormalized = maxCoord <= 1.5;
    debugPrint('YoloService: maxCoord=$maxCoord normalized=$coordNormalized fmt=$_fmt');
  }


  // ── Detect dari RGBA bytes (live camera) ──────────────────────────────────
  Future<List<DetectionResult>> detectFromRgba({
    required Uint8List rgbaBytes,
    required int srcWidth,
    required int srcHeight,
  }) async {
    if (!_isReady || _interp == null) return [];

    // Preprocess: stretch ke 640×640 (sesuai cara Roboflow training — semua 640×640)
    final inF32 = await compute(_preprocessCompute, {
      'rgba': rgbaBytes,
      'srcW': srcWidth, 'srcH': srcHeight,
      'dstW': _inW,     'dstH': _inH,
    });
    _inBuf.setAll(0, inF32);

    // Inference (sync — GPU/XNNPACK sudah cepat)
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final outCopy = _runInferenceSync();  // ← copy buffer, bukan view
    lastInferenceMs = DateTime.now().millisecondsSinceEpoch - t0;

    // Debug: tunjukkan 3 baris pertama dari output tensor
    debugFirstDetections = _buildDebugStr(outCopy);

    final enabled = SettingsService.instance.enabledLabels;

    // Parse + NMS off-main-thread (padX=0/padY=0 karena pakai stretch bukan letterbox)
    final raw = await compute(_parseAndNmsCompute, {
      'flat'        : outCopy,
      'fmt'         : _fmt.index,
      'dim1'        : _dim1,
      'dim2'        : _dim2,
      'conf'        : _conf,
      'iou'         : _iouThr,
      'normalized'  : coordNormalized,
      'clsOverride' : _clsConfOverride.map((k, v) => MapEntry(k.toString(), v)),
      'clsMaxDet'   : _clsMaxDet.map((k, v) => MapEntry(k.toString(), v)),
      'swapped'     : clsConfSwapped,
    });
    return enabled.isEmpty
        ? raw
        : raw.where((d) => enabled.contains(d.label)).toList();
  }

  // ── Detect dari JPEG (capture sekali) ────────────────────────────────────
  Future<List<DetectionResult>> detectFromBytes(Uint8List jpegBytes) async {
    if (!_isReady || _interp == null) return [];

    final codec    = await ui.instantiateImageCodec(
        jpegBytes, targetWidth: _inW, targetHeight: _inH);
    final frame    = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();

    if (byteData == null) throw Exception('Gagal decode JPEG → RGBA');

    final rgba = byteData.buffer.asUint8List();

    // Preprocess → inference (1x saja)
    _inBuf.setAll(0, await compute(_preprocessCompute, {
      'rgba': rgba, 'srcW': _inW, 'srcH': _inH, 'dstW': _inW, 'dstH': _inH,
    }));
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final outCopy = _runInferenceSync();
    lastInferenceMs = DateTime.now().millisecondsSinceEpoch - t0;
    debugRawDetections = _buildDebugRaw(outCopy);
    debugFirstDetections = _buildDebugStr(outCopy);

    final enabled = SettingsService.instance.enabledLabels;
    final raw = await compute(_parseAndNmsCompute, {
      'flat'        : outCopy,
      'fmt'         : _fmt.index,
      'dim1'        : _dim1,
      'dim2'        : _dim2,
      'conf'        : _conf,
      'iou'         : _iouThr,
      'normalized'  : coordNormalized,
      'clsOverride' : _clsConfOverride.map((k, v) => MapEntry(k.toString(), v)),
      'clsMaxDet'   : _clsMaxDet.map((k, v) => MapEntry(k.toString(), v)),
      'swapped'     : clsConfSwapped,
    });
    return enabled.isEmpty
        ? raw
        : raw.where((d) => enabled.contains(d.label)).toList();
  }

  // ── Run inference SYNC — kembalikan COPY (bukan view native tensor) ───────
  Float32List _runInferenceSync() {
    // Set input: tulis _inBuf langsung ke tensor
    final inputTensor = _interp!.getInputTensor(0);
    inputTensor.data = _inBuf.buffer.asUint8List();

    // Invoke
    _interp!.invoke();

    // Baca output — COPY agar aman dikirim ke compute isolate
    final raw = _interp!.getOutputTensor(0).data.buffer.asFloat32List();
    return Float32List.fromList(raw);   // ← COPY, bukan view
  }

  // ── Debug helpers ─────────────────────────────────────────────────────────
  String _buildDebugStr(Float32List flat) {
    final buf = StringBuffer();
    int shown = 0;
    if (_fmt == _OutputFmt.rawYoloHWC) {
      final nAnch = _dim2; final numCls = _dim1 - 4;
      for (int a = 0; a < nAnch && shown < 3; a++) {
        double mc = 0; int cls = 0;
        for (int c = 0; c < numCls; c++) {
          final s = flat[(4 + c) * nAnch + a];
          if (s > mc) { mc = s; cls = c; }
        }
        if (mc < 0.05) continue;
        buf.write('[${kLabels[cls]}:${mc.toStringAsFixed(2)}] ');
        shown++;
      }
    } else if (_fmt == _OutputFmt.postNms6) {
      for (int i = 0; i < _dim1 && shown < 3; i++) {
        final base = i * 6;
        if (base + 5 >= flat.length) break;
        final conf = flat[base + 4];
        if (conf < 0.05) continue;
        buf.write('[${conf.toStringAsFixed(2)}] ');
        shown++;
      }
    }
    return buf.toString();
  }

  String _buildDebugRaw(Float32List flat) {
    if (_fmt == _OutputFmt.rawYoloHWC) {
      final nAnch = _dim2; final numCls = _dim1 - 4;
      final buf = StringBuffer();
      final top = <(double, int, int)>[];
      for (int a = 0; a < nAnch; a++) {
        double mc = 0; int cls = 0;
        for (int c = 0; c < numCls; c++) {
          final s = flat[(4 + c) * nAnch + a];
          if (s > mc) { mc = s; cls = c; }
        }
        if (mc >= 0.05) top.add((mc, cls, a));
      }
      top.sort((a, b) => b.$1.compareTo(a.$1));
      for (final t in top.take(5)) {
        final a = t.$3;
        final cx=flat[0*nAnch+a]; final cy=flat[1*nAnch+a];
        final w=flat[2*nAnch+a];  final h=flat[3*nAnch+a];
        buf.writeln('${kLabels[t.$2]} conf=${t.$1.toStringAsFixed(3)} '
            'box=[${(cx-w/2).toStringAsFixed(2)},${(cy-h/2).toStringAsFixed(2)},'
            '${(cx+w/2).toStringAsFixed(2)},${(cy+h/2).toStringAsFixed(2)}]');
      }
      return buf.isEmpty ? 'tidak ada deteksi' : buf.toString();
    }
    return 'fmt=$_fmt';
  }

  // ── Diagnostic lengkap ────────────────────────────────────────────────────
  Future<ModelDiagnostic> runDiagnostic({
    List<String> validationAssets = const [],
  }) async {
    final interp = _interp;
    if (!_isReady || interp == null) {
      return ModelDiagnostic(
        inputShape: [], outputShape: [], outputFormat: 'NOT_LOADED',
        coordNormalized: false, clsConfSwapped: false,
        inferenceMs: 0, gpuActive: false, numOutputTensors: 0,
        inputDtype: '-', outputDtype: '-', classResults: [],
      );
    }

    final inShape  = List<int>.from(interp.getInputTensor(0).shape);
    final outShape = List<int>.from(interp.getOutputTensor(0).shape);
    final numOut   = interp.getOutputTensors().length;
    final inDtype  = interp.getInputTensor(0).type.toString();
    final outDtype = interp.getOutputTensor(0).type.toString();

    // Hitung per-class dari gambar validasi
    final classCounts = <int, int>{};
    final classConfs  = <int, double>{};
    for (final assetPath in validationAssets) {
      try {
        final data  = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();
        final dets  = await detectFromBytes(bytes);
        for (final d in dets) {
          final idx = kLabels.indexOf(d.label);
          if (idx < 0) continue;
          classCounts[idx] = (classCounts[idx] ?? 0) + 1;
          classConfs[idx]  = (classConfs[idx]  ?? 0) + d.confidence;
        }
      } catch (_) {}
    }

    final classResults = List.generate(kLabels.length, (i) {
      final cnt = classCounts[i] ?? 0;
      final avg = cnt > 0 ? (classConfs[i] ?? 0) / cnt : 0.0;
      return ClsDiag(kLabels[i], cnt, avg);
    });

    final diag = ModelDiagnostic(
      inputShape:      inShape,
      outputShape:     outShape,
      outputFormat:    modelFormat,
      coordNormalized: coordNormalized,
      clsConfSwapped:  clsConfSwapped,
      inferenceMs:     lastInferenceMs,
      gpuActive:       _useGpu,
      numOutputTensors: numOut,
      inputDtype:      inDtype,
      outputDtype:     outDtype,
      classResults:    classResults,
    );
    lastDiagnostic = diag;
    return diag;
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────
  void _safeClose() {
    try { _interp?.close(); } catch (_) {}
    _interp = null;
  }

  void dispose() {
    _safeClose();
    _isReady = false;
  }
}

// ── ModelDiagnostic ───────────────────────────────────────────────────────────
class ModelDiagnostic {
  final List<int>   inputShape;
  final List<int>   outputShape;
  final String      outputFormat;
  final bool        coordNormalized;
  final bool        clsConfSwapped;
  final int         inferenceMs;
  final bool        gpuActive;
  final int         numOutputTensors;
  final String      inputDtype;
  final String      outputDtype;
  final List<ClsDiag> classResults; // per-class hasil validasi image

  const ModelDiagnostic({
    required this.inputShape,
    required this.outputShape,
    required this.outputFormat,
    required this.coordNormalized,
    required this.clsConfSwapped,
    required this.inferenceMs,
    required this.gpuActive,
    required this.numOutputTensors,
    required this.inputDtype,
    required this.outputDtype,
    required this.classResults,
  });

  bool get isHealthy =>
      inputShape.length == 4 &&
      outputShape.isNotEmpty &&
      inferenceMs < 3000 &&
      numOutputTensors >= 1;
}

class ClsDiag {
  final String label;
  final int    count;
  final double avgConf;
  const ClsDiag(this.label, this.count, this.avgConf);
}

// ── Helper class ──────────────────────────────────────────────────────────────
class _Box {
  final String label;
  final double conf, l, t, r, b;
  const _Box({
    required this.label, required this.conf,
    required this.l, required this.t,
    required this.r, required this.b,
  });
}
