import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/core/widgets/common.dart';
import 'package:gearguard/core/widgets/safety_widgets.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/domain/employee.dart';
import 'package:gearguard/features/employees/add_employee_sheet.dart';
import 'package:gearguard/features/employees/employee_detail_page.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  bool _ranking = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final safety = context.watch<SafetyCubit>().state;
    final q = _query.trim().toLowerCase();
    final base = _ranking ? safety.ranking : safety.employees;
    final list = [
      for (final e in base)
        if (q.isEmpty ||
            e.name.toLowerCase().contains(q) ||
            e.code.toLowerCase().contains(q) ||
            e.department.toLowerCase().contains(q))
          e,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddEmployeeSheet(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Team', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${safety.employees.length} registered employees',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search name, ID or department',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.groups_rounded),
                          label: Text('Everyone'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.emoji_events_rounded),
                          label: Text('Ranking'),
                        ),
                      ],
                      selected: {_ranking},
                      onSelectionChanged: (s) =>
                          setState(() => _ranking = s.first),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(
                      icon: Icons.groups_outlined,
                      title: q.isEmpty ? 'No employees yet' : 'No matches',
                      message: q.isEmpty
                          ? 'Register your first worker to start scanning.'
                          : 'Try a different search.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _EmployeeTile(
                        employee: list[i],
                        rank: _ranking && q.isEmpty ? i + 1 : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee, this.rank});

  final Employee employee;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final safety = context.watch<SafetyCubit>().state;
    final rate = safety.complianceOf(employee.id);
    final scans = safety.scansFor(employee.id).length;

    return Pressable(
      semanticLabel: '${employee.name}, ${employee.department}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EmployeeDetailPage(employeeId: employee.id),
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
            if (rank != null)
              SizedBox(
                width: 34,
                child: rank! <= 3
                    ? Icon(
                        Icons.emoji_events_rounded,
                        color: const [
                          Color(0xFFF59E0B),
                          Color(0xFF94A3B8),
                          Color(0xFFB45309),
                        ][rank! - 1],
                      )
                    : Text(
                        '$rank',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
            EmployeeAvatar(employee: employee),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name, style: theme.textTheme.titleSmall),
                  Text(
                    '${employee.code} · ${employee.department}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rate == null ? '–' : formatPercent(rate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: readableColor(
                      context,
                      complianceColor(rate),
                      tint: 0,
                    ),
                  ),
                ),
                Text(
                  '$scans scans',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
