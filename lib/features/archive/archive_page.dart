import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/core/widgets/common.dart';
import 'package:gearguard/core/widgets/safety_widgets.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/cubits/settings_cubit.dart';
import 'package:gearguard/data/report_pdf.dart';
import 'package:gearguard/domain/employee.dart';
import 'package:gearguard/domain/scan_record.dart';
import 'package:gearguard/features/archive/scan_detail_page.dart';
import 'package:printing/printing.dart';

enum _Filter { all, compliant, violations }

Future<void> exportReport(
  BuildContext context,
  List<ScanRecord> scans,
) async {
  final safety = context.read<SafetyCubit>().state;
  final settings = context.read<SettingsCubit>().state;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await buildReportPdf(
      siteName: settings.siteName,
      supervisor: settings.supervisor,
      scans: scans,
      employeeOf: safety.employee,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'gearguard-report.pdf');
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not create the PDF report')),
    );
  }
}

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final safety = context.watch<SafetyCubit>().state;

    final q = _query.trim().toLowerCase();
    final filtered = [
      for (final s in safety.scans)
        if (switch (_filter) {
              _Filter.all => true,
              _Filter.compliant => s.compliant,
              _Filter.violations => !s.compliant,
            } &&
            (q.isEmpty ||
                (safety
                        .employee(s.employeeId)
                        ?.name
                        .toLowerCase()
                        .contains(q) ??
                    false)))
          s,
    ];

    // Group by day, keeping newest first.
    final groups = <DateTime, List<ScanRecord>>{};
    for (final s in filtered) {
      groups.putIfAbsent(DateUtils.dateOnly(s.time), () => []).add(s);
    }
    final days = groups.keys.toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Archive', style: theme.textTheme.headlineMedium),
                ),
                IconButton.filledTonal(
                  tooltip: 'Export PDF report',
                  onPressed: filtered.isEmpty
                      ? null
                      : () => exportReport(context, filtered),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              '${safety.scans.length} scans stored on this device',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by employee',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Filter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _Filter.all, label: Text('All')),
                  ButtonSegment(
                    value: _Filter.compliant,
                    label: Text('Compliant'),
                  ),
                  ButtonSegment(
                    value: _Filter.violations,
                    label: Text('Violations'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nothing here',
                    message: 'No scans match these filters yet.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: days.length,
                    itemBuilder: (context, i) {
                      final day = days[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 14, 0, 8),
                            child: Text(
                              '${relativeDay(day)} · ${formatShortDate(day)}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          for (final s in groups[day]!)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ScanTile(record: s),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One row in a scan list.
class ScanTile extends StatelessWidget {
  const ScanTile({required this.record, super.key});

  final ScanRecord record;

  String get _missingList =>
      record.missing.map((m) => m.label.toLowerCase()).join(', ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final employee = context.select<SafetyCubit, Employee?>(
      (c) => c.state.employee(record.employeeId),
    );
    final name = employee?.name ?? 'Removed employee';

    return Pressable(
      semanticLabel: '$name, ${record.compliant ? 'compliant' : 'violation'}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ScanDetailPage(recordId: record.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 46,
              decoration: BoxDecoration(
                color: record.compliant ? AppColors.success : AppColors.danger,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.compliant
                        ? formatStamp(record.time)
                        : 'Missing $_missingList',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: record.compliant
                          ? scheme.onSurfaceVariant
                          : readableColor(context, AppColors.danger, tint: 0),
                    ),
                  ),
                  if (!record.compliant)
                    Text(
                      formatStamp(record.time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill.compliance(compliant: record.compliant),
          ],
        ),
      ),
    );
  }
}
