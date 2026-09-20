import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/core/widgets/safety_widgets.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/features/archive/archive_page.dart';
import 'package:gearguard/features/employees/employee_detail_page.dart';

class ScanDetailPage extends StatelessWidget {
  const ScanDetailPage({required this.recordId, super.key});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<SafetyCubit>().state;
    final matches = state.scans.where((s) => s.id == recordId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This scan no longer exists.')),
      );
    }
    final record = matches.first;
    final employee = state.employee(record.employeeId);
    final color = record.compliant ? AppColors.success : AppColors.danger;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan result'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => exportReport(context, [record]),
          ),
          IconButton(
            tooltip: 'Delete scan',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final cubit = context.read<SafetyCubit>();
              final navigator = Navigator.of(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this scan?'),
                  content: const Text('It will be removed from the archive.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
              if (ok ?? false) {
                await cubit.deleteScan(record.id);
                navigator.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                ComplianceRing(
                  value: record.score,
                  size: 88,
                  stroke: 9,
                  color: color,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill.compliance(compliant: record.compliant),
                      const SizedBox(height: 8),
                      Text(
                        record.compliant
                            ? 'All required PPE detected'
                            : '${record.missing.length} item'
                                  "${record.missing.length == 1 ? '' : 's'} missing",
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        formatStamp(record.time),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (employee != null)
            Card(
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: EmployeeAvatar(employee: employee),
                title: Text(employee.name, style: theme.textTheme.titleMedium),
                subtitle: Text('${employee.code} · ${employee.department}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EmployeeDetailPage(employeeId: employee.id),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text('Equipment check', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Detection threshold ${formatPercent(record.threshold)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                for (final item in record.required)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        PpeChip(item: item, ok: record.isDetected(item)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '${formatPercent(record.scores[item] ?? 0)}  ·  '
                          '${record.isDetected(item) ? 'Detected' : 'Missing'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: readableColor(
                              context,
                              record.isDetected(item)
                                  ? AppColors.success
                                  : AppColors.danger,
                              tint: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
