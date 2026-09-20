import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/core/widgets/common.dart';
import 'package:gearguard/core/widgets/gear_logo.dart';
import 'package:gearguard/core/widgets/safety_widgets.dart';
import 'package:gearguard/cubits/nav_cubit.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/cubits/settings_cubit.dart';
import 'package:gearguard/domain/ppe_item.dart';
import 'package:gearguard/features/archive/archive_page.dart';
import 'package:gearguard/features/settings/settings_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Good morning';
    if (h < 15) return 'Good afternoon';
    if (h < 19) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = context.watch<SettingsCubit>().state;
    final safety = context.watch<SafetyCubit>().state;

    final today = DateUtils.dateOnly(DateTime.now());
    final todayScans = safety.scansOn(today);
    final scannedIds = {for (final s in todayScans) s.employeeId};
    final violations = todayScans.where((s) => !s.compliant).length;
    final pending = safety.employees.length - scannedIds.length;
    final rate = safety.complianceOn(today);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final weekly = [for (final d in days) safety.complianceOn(d)];
    final misses = safety.missCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final recent = safety.scans.take(4).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              const GearWordmark(size: 30),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '${_greeting()}, ${settings.supervisor.split(' ').first}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${settings.siteName} · ${formatDayHeader(today)}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            child: _HeroCard(
              rate: rate,
              scanned: scannedIds.length,
              total: safety.employees.length,
              onScan: () => context.read<NavCubit>().go(AppTab.scan),
            ),
          ),
          if (violations > 0) ...[
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 1,
              child: _AlertBanner(
                count: violations,
                onTap: () => context.read<NavCubit>().go(AppTab.attendance),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FadeSlideIn(
            index: 2,
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Checked in',
                    value: '${scannedIds.length}',
                    color: AppColors.success,
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
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Pending',
                    value: '$pending',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Compliance this week'),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 3,
            child: _Panel(
              child: WeeklyChart(days: days, values: weekly),
            ),
          ),
          if (misses.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: 'Most missed equipment'),
            const SizedBox(height: 12),
            _Panel(child: _MissedList(entries: misses.take(4).toList())),
          ],
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Recent scans',
            action: 'View all',
            onAction: () => context.read<NavCubit>().go(AppTab.archive),
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const EmptyState(
              icon: Icons.center_focus_weak_rounded,
              title: 'No scans yet',
              message: 'Run your first PPE scan to see results here.',
            )
          else
            for (final s in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ScanTile(record: s),
              ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.rate,
    required this.scanned,
    required this.total,
    required this.onScan,
  });

  final double? rate;
  final int scanned;
  final int total;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // The card is always dark, so the ring must use the dark theme
          // even when the app is in light mode.
          Theme(
            data: AppTheme.dark(),
            child: ComplianceRing(value: rate, size: 118, caption: 'today'),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PPE compliance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Add your team to begin.'
                      : '$scanned of $total workers checked in',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: onScan,
                  icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                  label: const Text('Start scan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$count violations today. Open attendance',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count ${count == 1 ? 'worker has' : 'workers have'} '
                'missing PPE today',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _MissedList extends StatelessWidget {
  const _MissedList({required this.entries});

  final List<MapEntry<PpeItem, int>> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = entries.first.value;
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(e.key.icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: Text(e.key.label, style: theme.textTheme.bodyMedium),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: e.value / maxCount,
                      minHeight: 8,
                      color: AppColors.danger,
                      backgroundColor: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${e.value}×', style: theme.textTheme.labelLarge),
              ],
            ),
          ),
      ],
    );
  }
}
