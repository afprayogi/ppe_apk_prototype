import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../core/services/yolo_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

// Gambar validasi bawaan untuk pengujian per-class
const _validationAssets = [
  'assets/validasi/helm.jpeg',
  'assets/validasi/helm 2.jpeg',
  'assets/validasi/helm 3.jpeg',
  'assets/validasi/vest.jpeg',
  'assets/validasi/vest 2.jpeg',
  'assets/validasi/Sepatu Safety K3.jpeg',
];

class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});
  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  bool             _running   = false;
  ModelDiagnostic? _diag;
  String           _phase     = '';

  @override
  void initState() {
    super.initState();
    // Tampilkan diagnostik terakhir jika sudah pernah dijalankan
    _diag = YoloService.instance.lastDiagnostic;
  }

  Future<void> _runDiagnostic() async {
    setState(() { _running = true; _phase = 'Memeriksa model...'; });
    try {
      if (!YoloService.instance.isReady) {
        setState(() => _phase = 'Memuat model...');
        await YoloService.instance.initialize();
      }
      setState(() => _phase = 'Menguji ${_validationAssets.length} gambar validasi...');
      final diag = await YoloService.instance.runDiagnostic(
        validationAssets: _validationAssets,
      );
      if (mounted) setState(() { _diag = diag; _running = false; _phase = ''; });
    } catch (e) {
      if (mounted) setState(() {
        _running = false;
        _phase   = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Diagnostik Model AI', style: AppTextStyles.headlineOnGreen),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tombol Jalankan ──────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _running ? null : _runDiagnostic,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
              icon: _running
                  ? SizedBox(width: 18.w, height: 18.w,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.biotech, color: Colors.white),
              label: Text(
                _running ? _phase : 'Jalankan Diagnostik Lengkap',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ),
            SizedBox(height: 14.h),

            if (_diag == null && !_running)
              _InfoCard(
                icon: Icons.info_outline,
                color: Colors.blueGrey,
                title: 'Belum ada hasil',
                body: 'Tekan tombol di atas untuk memeriksa kompatibilitas '
                    'model dengan perangkat ini.',
              ),

            if (_diag != null) ..._buildResults(_diag!),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i == 3) return;
          switch (i) {
            case 0: Navigator.pushNamedAndRemoveUntil(
                context, AppConstants.routeHome, (_) => false);
            case 1: Navigator.pushNamed(context, AppConstants.routeAbsensi);
            case 2: Navigator.pushNamed(context, AppConstants.routeScanner);
            case 4: Navigator.pushNamed(context, AppConstants.routeInfo);
          }
        },
      ),
    );
  }

  List<Widget> _buildResults(ModelDiagnostic d) {
    return [
      // ── Status keseluruhan ─────────────────────────────────────────────────
      _InfoCard(
        icon: d.isHealthy ? Icons.check_circle : Icons.error,
        color: d.isHealthy ? AppColors.progressGreen : AppColors.progressRed,
        title: d.isHealthy ? 'Model KOMPATIBEL dengan perangkat ini'
                           : 'Model BERMASALAH — periksa poin merah di bawah',
        body: '',
      ),
      SizedBox(height: 10.h),

      // ── Info tensor ───────────────────────────────────────────────────────
      _SectionTitle('Tensor Info'),
      _Row('Input shape',    d.inputShape.toString()),
      _Row('Output shape',   d.outputShape.toString()),
      _Row('Input dtype',    d.inputDtype),
      _Row('Output dtype',   d.outputDtype),
      _Row('Output tensors', d.numOutputTensors.toString(),
          warn: d.numOutputTensors > 1
              ? '⚠ Model punya ${d.numOutputTensors} output tensor — '
                'hanya tensor [0] yang dibaca. Pastikan ini benar.'
              : null),
      SizedBox(height: 10.h),

      // ── Format & koordinat ────────────────────────────────────────────────
      _SectionTitle('Format Deteksi'),
      _Row('Output format',  d.outputFormat),
      _Row('Koordinat',      d.coordNormalized ? 'Normalized (0–1)' : 'Pixel (0–640)'),
      _Row('Cls/Conf swap',  d.clsConfSwapped ? 'YA — sudah di-auto-fix ✓' : 'Tidak'),
      _Row('GPU aktif',      d.gpuActive ? 'Ya' : 'Tidak (CPU)'),
      _Row('Inferensi',      '${d.inferenceMs} ms',
          warn: d.inferenceMs > 1500
              ? '⚠ Terlalu lambat (${d.inferenceMs}ms). HP mungkin tidak kuat.'
              : null),
      SizedBox(height: 10.h),

      // ── Hasil uji per-class ───────────────────────────────────────────────
      _SectionTitle('Hasil Uji ${_validationAssets.length} Gambar Validasi'),
      if (d.classResults.every((c) => c.count == 0))
        _InfoCard(
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          title: 'Tidak ada class yang terdeteksi dari gambar validasi',
          body: 'Kemungkinan:\n'
              '• Threshold terlalu tinggi (turunkan conf dari 0.20)\n'
              '• Model belum terlatih baik untuk class ini\n'
              '• Format gambar tidak sesuai ekspektasi model',
        )
      else
        ...d.classResults.map((c) => _ClassBar(c,
            totalAllClass: d.classResults.fold(0, (s, x) => s + x.count))),
      SizedBox(height: 10.h),

      // ── Saran perbaikan ───────────────────────────────────────────────────
      _SectionTitle('Saran Perbaikan Model'),
      ..._buildSuggestions(d),
      SizedBox(height: 80.h),
    ];
  }

  List<Widget> _buildSuggestions(ModelDiagnostic d) {
    final suggestions = <Widget>[];
    final total = d.classResults.fold(0, (s, c) => s + c.count);

    if (total > 0) {
      // Deteksi bias ekstrem (>80% satu class)
      for (final c in d.classResults) {
        final ratio = c.count / total;
        if (ratio > 0.80) {
          suggestions.add(_SuggestionCard(
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            title: '⚠ BIAS KRITIS: ${c.label} = ${(ratio*100).toInt()}% dari semua deteksi',
            body: 'Model hampir tidak bisa membedakan class lain.\n\n'
                'PENYEBAB UTAMA:\n'
                '• Dataset training tidak seimbang (terlalu banyak foto ${c.label})\n'
                '• Class lain tidak cukup terwakili\n\n'
                'SOLUSI WAJIB (harus retrain):\n'
                '1. Pastikan tiap class punya 200–500 foto labeled\n'
                '2. Hapus atau kurangi foto ${c.label} ke jumlah yang sama\n'
                '3. Gunakan Roboflow → Train → export YOLOv8 TFLite\n'
                '4. Ganti best.tflite dengan model baru',
          ));
        }
      }

      // Class tidak terdeteksi sama sekali
      final zeroCls = d.classResults.where((c) => c.count == 0).toList();
      if (zeroCls.isNotEmpty) {
        suggestions.add(_SuggestionCard(
          icon: Icons.visibility_off,
          color: Colors.orange,
          title: 'Class tidak terdeteksi: ${zeroCls.map((c) => c.label).join(", ")}',
          body: 'Kemungkinan:\n'
              '• Gambar validasi tidak memiliki class ini (tambah foto uji)\n'
              '• Model tidak punya data training untuk class ini\n'
              '• Threshold terlalu tinggi (sudah diturunkan ke 10%)\n\n'
              'Solusi: tambah 200+ foto tiap class yang kosong ke dataset.',
        ));
      }
    } else {
      // Tidak ada deteksi sama sekali
      suggestions.add(_SuggestionCard(
        icon: Icons.search_off,
        color: Colors.red,
        title: 'Nol deteksi dari semua gambar validasi',
        body: 'Threshold sudah diturunkan ke 10% tapi tetap tidak ada deteksi.\n\n'
            'Kemungkinan besar:\n'
            '• Model output format tidak sesuai kode parser\n'
            '• Model belum dilatih dengan benar\n'
            '• File best.tflite corrupt atau kosong\n\n'
            'Coba: export ulang model dari Ultralytics dengan\n'
            'YOLO("best.pt").export(format="tflite", nms=True, imgsz=640)',
      ));
    }

    if (d.inferenceMs > 1500) {
      suggestions.add(_SuggestionCard(
        icon: Icons.speed,
        color: Colors.red,
        title: 'Inferensi terlalu lambat (${d.inferenceMs}ms)',
        body: 'Export model lebih kecil:\n'
            'YOLO("best.pt").export(format="tflite", imgsz=320, int8=True)\n'
            'imgsz=320 dan int8 membuat model 4× lebih cepat.',
      ));
    }

    if (d.numOutputTensors > 1) {
      suggestions.add(_SuggestionCard(
        icon: Icons.device_hub,
        color: Colors.orange,
        title: 'Model punya ${d.numOutputTensors} output tensor',
        body: 'Export ulang tanpa NMS bawaan:\n'
            'YOLO("best.pt").export(format="tflite", nms=False)\n'
            'Atau gunakan nms=True agar output jadi satu tensor [1,300,6].',
      ));
    }

    if (suggestions.isEmpty) {
      suggestions.add(_SuggestionCard(
        icon: Icons.thumb_up,
        color: AppColors.progressGreen,
        title: 'Model terlihat sehat!',
        body: 'Tidak ditemukan masalah konfigurasi. '
            'Jika deteksi masih kurang akurat, fokus pada kualitas dataset training.',
      ));
    }

    return suggestions;
  }
}

// ── Widgets helper ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 6.h, top: 4.h),
    child: Text(text,
        style: AppTextStyles.titleMedium
            .copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  final String? warn;
  const _Row(this.label, this.value, {this.warn});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: warn != null
            ? Colors.orange.withValues(alpha: 0.08)
            : AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: warn != null ? Colors.orange : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodyMedium),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primaryGreen)),
              ),
            ],
          ),
          if (warn != null) ...[
            SizedBox(height: 4.h),
            Text(warn!, style: AppTextStyles.labelSmall
                .copyWith(color: Colors.orange.shade800)),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, body;
  const _InfoCard({required this.icon, required this.color,
      required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium.copyWith(color: color)),
              if (body.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(body, style: AppTextStyles.bodyMedium),
              ],
            ],
          )),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, body;
  const _SuggestionCard({required this.icon, required this.color,
      required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              SizedBox(height: 4.h),
              Text(body, style: AppTextStyles.bodyMedium),
            ],
          )),
        ],
      ),
    );
  }
}

class _ClassBar extends StatelessWidget {
  final ClsDiag c;
  final int totalAllClass; // total semua class untuk normalisasi
  const _ClassBar(this.c, {required this.totalAllClass});
  @override
  Widget build(BuildContext context) {
    // Normalisasi bar relatif terhadap total seluruh deteksi
    final frac  = totalAllClass == 0
        ? 0.0
        : (c.count / totalAllClass).clamp(0.0, 1.0);
    final pct   = totalAllClass == 0 ? 0 : (c.count / totalAllClass * 100).round();
    final conf  = c.avgConf.clamp(0.0, 1.0); // pastikan 0-1

    // Warna: merah=tidak ada, orange=sedikit, hijau=wajar
    final color = c.count == 0
        ? Colors.red.shade300
        : pct > 80
            ? Colors.orange  // dominasi tidak wajar
            : c.count >= 2
                ? AppColors.progressGreen
                : Colors.orange;

    final isBiased = pct > 80 && c.count > 5;

    return Container(
      margin: EdgeInsets.only(bottom: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isBiased
            ? Colors.orange.withValues(alpha: 0.06)
            : Theme.of(context).cardTheme.color ?? AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: isBiased ? Colors.orange : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(c.label, style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
                if (isBiased) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.warning_amber_rounded,
                      size: 14.sp, color: Colors.orange),
                ],
              ]),
              Text(
                c.count == 0
                    ? '✗ Tidak terdeteksi'
                    : '${c.count} deteksi ($pct%) | conf ${(conf * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 6.h,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (isBiased) ...[
            SizedBox(height: 4.h),
            Text('⚠ Class ini mendominasi ${pct}% — kemungkinan bias training',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.orange.shade800, fontSize: 9.sp)),
          ],
        ],
      ),
    );
  }
}
