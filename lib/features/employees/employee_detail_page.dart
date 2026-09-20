import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/core/widgets/common.dart';
import 'package:gearguard/core/widgets/safety_widgets.dart';
import 'package:gearguard/cubits/nav_cubit.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/features/archive/archive_page.dart';

class EmployeeDetailPage extends StatelessWidget {
  const EmployeeDetailPage({required this.employeeId, super.key});

  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<SafetyCubit>().state;
    final employee = state.employee(employeeId);
    if (employee == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Employee not found.')),
      );
    }
    final scans = state.scansFor(employeeId);
    final rate = state.complianceOf(employeeId);
    final violations = scans.where((s) => !s.compliant).length;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: scans.isEmpty
                ? null
                : () => exportReport(context, scans),
          ),
          IconButton(
            tooltip: 'Remove employee',
            icon: const Icon(Icons.person_remove_alt_1_rounded),
            onPressed: () async {
              final cubit = context.read<SafetyCubit>();
              final navigator = Navigator.of(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Remove ${employee.name}?'),
                  content: const Text(
                    'Their profile and all scan history will be deleted.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
              if (ok ?? false) {
                navigator.pop();
                await cubit.deleteEmployee(employeeId);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                EmployeeAvatar(employee: employee, radius: 44),
                const SizedBox(height: 12),
                Text(employee.name, style: theme.textTheme.headlineSmall),
                Text(
                  '${employee.code} · ${employee.department}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.verified_user_rounded,
                  label: 'Compliance',
                  value: rate == null ? '–' : formatPercent(rate),
                  color: complianceColor(rate),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Scans',
                  value: '${scans.length}',
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.report_rounded,
                  label: 'Violations',
                  value: '$violations',
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              context.read<ScanTargetCubit>().select(employeeId);
              context.read<NavCubit>().go(AppTab.scan);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.center_focus_strong_rounded),
            label: const Text('Scan now'),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'History'),
          const SizedBox(height: 8),
          if (scans.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No scans yet',
              message: 'Scan results for this employee will appear here.',
            )
          else
            for (final s in scans)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ScanTile(record: s),
              ),
        ],
      ),
    );
  }
}
