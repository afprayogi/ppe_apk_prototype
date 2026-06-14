import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/detection_model.dart';
import '../../providers/detection_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/ppe_item_card.dart';

void _showFullImage(BuildContext context, String path) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(_),
        ),
        title: const Text('Foto Deteksi',
            style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5, maxScale: 4.0,
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    ),
  ));
}

/// Detail screen untuk satu DetectionRecord
class DetailScreen extends ConsumerWidget {
  final DetectionRecord record;
  const DetailScreen({super.key, required this.record});

  Future<void> _hapus(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus record ini?'),
        content: Text('Data deteksi ${record.employeeName} akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(detectionProvider.notifier).deleteRecord(record.id);
      if (context.mounted) Navigator.pop(context); // kembali ke archive
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm WIB').format(record.detectedAt);
    final isOk    = record.missingPpe.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detail Deteksi', style: AppTextStyles.headlineOnGreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.white),
            tooltip: 'Hapus',
            onPressed: () => _hapus(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isOk ? AppColors.progressGreen : AppColors.progressAmber,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(
                    isOk ? Icons.verified : Icons.warning_amber_rounded,
                    color: AppColors.white,
                    size: 48.sp,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isOk ? 'APD LENGKAP' : 'APD TIDAK LENGKAP',
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: AppColors.white),
                  ),
                  Text(
                    'Confidence: ${record.overallConfidence.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Employee info card
            _Card(
              title: 'Data Karyawan',
              child: Column(
                children: [
                  _Row(label: 'Nama',   value: record.employeeName),
                  _Row(label: 'NIA',    value: record.nia),
                  _Row(label: 'Tanggal', value: dateStr),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Detected PPE
            _Card(
              title: 'APD Terdeteksi',
              child: record.detectedPpe.isEmpty
                  ? Text('Tidak ada APD terdeteksi',
                      style: AppTextStyles.bodyMedium)
                  : Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: record.detectedPpe.map((ppe) => _PpeBadge(
                            label: ppe,
                            icon: ppeIconMap[ppe] ?? Icons.shield_outlined,
                            detected: true,
                          )).toList(),
                    ),
            ),
            SizedBox(height: 12.h),

            // Missing PPE
            if (record.missingPpe.isNotEmpty) ...[
              _Card(
                title: 'APD Tidak Ditemukan',
                borderColor: AppColors.progressRed,
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: record.missingPpe.map((ppe) => _PpeBadge(
                        label: ppe,
                        icon: ppeIconMap[ppe] ?? Icons.shield_outlined,
                        detected: false,
                      )).toList(),
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Foto hasil deteksi dari storage lokal
            _Card(
              title: 'Foto Deteksi',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: record.imageUrl != null &&
                        File(record.imageUrl!).existsSync()
                    ? GestureDetector(
                        onTap: () => _showFullImage(context, record.imageUrl!),
                        child: Stack(
                          children: [
                            Image.file(
                              File(record.imageUrl!),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 6, right: 6,
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: const Icon(Icons.fullscreen,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 160.h,
                        color: AppColors.surfaceGreen,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_not_supported,
                                  color: AppColors.primaryGreen, size: 40.sp),
                              SizedBox(height: 8.h),
                              Text('Foto tidak tersedia',
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? borderColor;
  const _Card({required this.title, required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor ?? AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.primaryGreen)),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Text('$label :',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _PpeBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool detected;
  const _PpeBadge(
      {required this.label, required this.icon, required this.detected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: detected
            ? AppColors.progressGreen.withValues(alpha: 0.1)
            : AppColors.progressRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: detected ? AppColors.progressGreen : AppColors.progressRed),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16.sp,
              color: detected ? AppColors.progressGreen : AppColors.progressRed),
          SizedBox(width: 4.w),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                  color: detected
                      ? AppColors.progressGreen
                      : AppColors.progressRed)),
        ],
      ),
    );
  }
}
