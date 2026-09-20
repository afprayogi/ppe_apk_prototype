import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/core/widgets/common.dart';
import 'package:gearguard/core/widgets/safety_widgets.dart';
import 'package:gearguard/cubits/nav_cubit.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/domain/employee.dart';
import 'package:gearguard/domain/scan_record.dart';
import 'package:gearguard/features/archive/scan_detail_page.dart';
import 'package:gearguard/features/employees/employee_detail_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late DateTime _day = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final safety = context.watch<SafetyCubit>().state;
    final today = DateUtils.dateOnly(DateTime.now());
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];

    final rows =
        [
          for (final e in safety.employees) (e, safety.checkIn(e.id, _day)),
        ]..sort((a, b) {
          // Violations first, then pending, then compliant.
          int rank(ScanRecord? s) => s == null ? 1 : (s.compliant ? 2 : 0);
          return rank(a.$2).compareTo(rank(b.$2));
        });

    final present = rows.where((r) => r.$2 != null).length;
    final ok = rows.where((r) => r.$2?.compliant ?? false).length;
    final bad = present - ok;
    final isToday = DateUtils.isSameDay(_day, today);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attendance', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  formatDayHeader(_day),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = days[i];
                final selected = DateUtils.isSameDay(d, _day);
                final rate = safety.complianceOn(d);
                return Semantics(
                  button: true,
                  selected: selected,
                  label: formatDayHeader(d),
                  child: GestureDetector(
                    onTap: () => setState(() => _day = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primary
                            : scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekdayShort(d),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${d.day}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: selected ? scheme.onPrimary : null,
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: rate == null
                                  ? Colors.transparent
                                  : selected
                                  ? scheme.onPrimary
                                  : complianceColor(rate),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Expanded(
                  child: _Mini(
                    label: 'Present',
                    value: '$present/${rows.length}',
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Mini(
                    label: 'Compliant',
                    value: '$ok',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Mini(
                    label: 'Violations',
                    value: '$bad',
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No employees',
                    message: 'Add your team to start tracking attendance.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _AttendanceRow(
                      employee: rows[i].$1,
                      record: rows[i].$2,
                      canScan: isToday,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: readableColor(context, color),
            ),
          ),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.employee,
    required this.record,
    required this.canScan,
  });

  final Employee employee;
  final ScanRecord? record;
  final bool canScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = record;

    return Pressable(
      semanticLabel: employee.name,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => r == null
              ? EmployeeDetailPage(employeeId: employee.id)
              : ScanDetailPage(recordId: r.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: r != null && !r.compliant
                ? AppColors.danger.withValues(alpha: 0.5)
                : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            EmployeeAvatar(employee: employee),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    r == null
                        ? employee.department
                        : 'In at ${formatTime(r.time)} · '
                              '${employee.department}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (r != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final item in r.required)
                          PpeChip(item: item, ok: r.isDetected(item)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (r != null)
              StatusPill.compliance(compliant: r.compliant)
            else if (canScan)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  context.read<ScanTargetCubit>().select(employee.id);
                  context.read<NavCubit>().go(AppTab.scan);
                },
                child: const Text('Scan'),
              )
            else
              const StatusPill(label: 'Absent', color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
