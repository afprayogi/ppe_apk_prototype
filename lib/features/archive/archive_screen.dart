import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/pdf_service.dart';
import '../../models/detection_model.dart';
import '../../providers/detection_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_search_bar.dart';
import '../scanner/detail_screen.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

enum _Filter { all, complete, nonSafety }

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  String  _query  = '';
  _Filter _filter = _Filter.all;

  List<DetectionRecord> _apply(List<DetectionRecord> records) {
    var list = _query.isEmpty
        ? records
        : records.where((r) =>
            r.employeeName.toLowerCase().contains(_query.toLowerCase()) ||
            r.nia.contains(_query)).toList();
    if (_filter == _Filter.complete)   list = list.where((r) => r.missingPpe.isEmpty).toList();
    if (_filter == _Filter.nonSafety)  list = list.where((r) => r.missingPpe.isNotEmpty).toList();
    return list;
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Semua?'),
        content: const Text('Semua riwayat deteksi akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(detectionProvider.notifier).clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua data dihapus')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(detectionProvider);
    final filtered = _apply(state.records);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Archive Deteksi', style: AppTextStyles.headlineOnGreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.white),
            tooltip: 'Export PDF',
            onPressed: state.records.isEmpty
                ? null
                : () => PdfService.instance.exportLaporanDeteksi(state.records),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppColors.white),
            tooltip: 'Hapus Semua',
            onPressed: state.records.isEmpty ? null : _confirmDeleteAll,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () => ref.read(detectionProvider.notifier).reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 6.h),
            child: AppSearchBar(
              hint: 'Cari nama / NIA...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                _FilterChip(label: 'Semua',      selected: _filter == _Filter.all,
                    onTap: () => setState(() => _filter = _Filter.all)),
                SizedBox(width: 8.w),
                _FilterChip(label: 'Complete',   selected: _filter == _Filter.complete,
                    color: AppColors.progressGreen,
                    onTap: () => setState(() => _filter = _Filter.complete)),
                SizedBox(width: 8.w),
                _FilterChip(label: 'Non-Safety', selected: _filter == _Filter.nonSafety,
                    color: AppColors.progressRed,
                    onTap: () => setState(() => _filter = _Filter.nonSafety)),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // Summary bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Total',      value: '${filtered.length}'),
                _Stat(label: 'Non-Safety', value: '${filtered.where((r) => r.missingPpe.isNotEmpty).length}'),
                _Stat(label: 'Complete',   value: '${filtered.where((r) => r.missingPpe.isEmpty).length}'),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : filtered.isEmpty
                    ? Center(child: Text('Tidak ada data', style: AppTextStyles.bodyMedium))
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final record = filtered[i];
                          return Dismissible(
                            key: ValueKey(record.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20.w),
                              margin: EdgeInsets.only(bottom: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.delete, color: Colors.white),
                                  Text('Hapus', style: AppTextStyles.labelSmall
                                      .copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Hapus record ini?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Batal')),
                                    TextButton(onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Hapus',
                                            style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) {
                              ref.read(detectionProvider.notifier).deleteRecord(record.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${record.employeeName} dihapus'),
                                  action: SnackBarAction(
                                    label: 'OK',
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                            child: _ArchiveCard(
                              record: record,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => DetailScreen(record: record))),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
      required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? c : c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: c, width: selected ? 0 : 1),
        ),
        child: Text(label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? Colors.white : c,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.headlineMedium
                .copyWith(color: AppColors.white)),
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.white)),
      ],
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final DetectionRecord record;
  final VoidCallback onTap;
  const _ArchiveCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isComplete = record.missingPpe.isEmpty;
    final dateStr    = DateFormat('dd/MM/yyyy HH:mm').format(record.detectedAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isComplete ? AppColors.progressGreen : AppColors.progressAmber,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail foto atau icon status
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: record.imageUrl != null &&
                      File(record.imageUrl!).existsSync()
                  ? Image.file(
                      File(record.imageUrl!),
                      width: 52.w, height: 52.w,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 52.w, height: 52.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: isComplete
                            ? AppColors.progressGreen.withValues(alpha: 0.15)
                            : AppColors.progressAmber.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        isComplete ? Icons.check_circle : Icons.warning_amber,
                        color: isComplete
                            ? AppColors.progressGreen
                            : AppColors.progressAmber,
                        size: 28.sp,
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.employeeName,
                      style: AppTextStyles.titleMedium),
                  Text('NIA: ${record.nia}  |  ${record.overallConfidence.toStringAsFixed(1)}% conf',
                      style: AppTextStyles.bodyMedium),
                  Text(dateStr, style: AppTextStyles.labelSmall),
                  if (record.missingPpe.isNotEmpty)
                    Text('Missing: ${record.missingPpe.join(", ")}',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.progressRed)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
