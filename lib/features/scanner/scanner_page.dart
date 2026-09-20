import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/core/widgets/common.dart';
import 'package:gearguard/core/widgets/safety_widgets.dart';
import 'package:gearguard/cubits/nav_cubit.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/cubits/settings_cubit.dart';
import 'package:gearguard/data/ppe_detector.dart';
import 'package:gearguard/domain/employee.dart';
import 'package:gearguard/domain/ppe_item.dart';
import 'package:gearguard/features/scanner/person_painter.dart';

enum _Phase { idle, analyzing, done }

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  final _scroll = ScrollController();

  _Phase _phase = _Phase.idle;
  String? _employeeId;
  Map<PpeItem, double>? _scores;

  @override
  void dispose() {
    _sweep.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Employee? _effectiveEmployee(SafetyState state, String? target) {
    final id = target ?? _employeeId;
    final chosen = id == null ? null : state.employee(id);
    if (chosen != null) return chosen;
    final today = DateTime.now();
    for (final e in state.employees) {
      if (state.checkIn(e.id, today) == null) return e;
    }
    return state.employees.isEmpty ? null : state.employees.first;
  }

  Future<void> _start(SettingsState settings) async {
    setState(() {
      _phase = _Phase.analyzing;
      _scores = null;
    });
    unawaited(_sweep.repeat(reverse: true));
    final scores = await context.read<PpeDetector>().detect();
    if (!mounted) return;
    _sweep.stop();
    setState(() {
      _scores = scores;
      _phase = _Phase.done;
    });
    // Bring the verdict into view once the result card has been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      unawaited(
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  Future<void> _save(Employee employee, SettingsState settings) async {
    final messenger = ScaffoldMessenger.of(context);
    final safety = context.read<SafetyCubit>();
    final scanTarget = context.read<ScanTargetCubit>();
    final record = await safety.recordScan(
      employeeId: employee.id,
      scores: _scores!,
      required: settings.requiredList,
      threshold: settings.threshold,
    );
    if (!mounted) return;
    scanTarget.select(null);
    setState(() {
      _phase = _Phase.idle;
      _scores = null;
      _employeeId = null;
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: record.compliant ? null : AppColors.danger,
          content: Text(
            record.compliant
                ? 'Saved: ${employee.name} is fully compliant'
                : settings.notifications
                ? 'Alert: ${employee.name} is missing '
                      '${record.missing.map((m) => m.label).join(', ')}'
                : 'Saved with violations for ${employee.name}',
          ),
        ),
      );
  }

  void _discard() => setState(() {
    _phase = _Phase.idle;
    _scores = null;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = context.watch<SettingsCubit>().state;
    final safety = context.watch<SafetyCubit>().state;
    final target = context.watch<ScanTargetCubit>().state;
    final employee = _effectiveEmployee(safety, target);

    final scores = _scores;
    final boxes = <PpeItem, bool>{
      if (scores != null)
        for (final item in settings.requiredList)
          item: (scores[item] ?? 0) >= settings.threshold,
    };

    return SafeArea(
      bottom: false,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('PPE scan', style: theme.textTheme.headlineMedium),
              ),
              StatusPill(
                label: 'Demo detector',
                color: scheme.primary,
                icon: Icons.science_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (employee == null)
            const _NoEmployees()
          else ...[
            _EmployeePicker(
              employee: employee,
              enabled: _phase != _Phase.analyzing,
              onChanged: (e) {
                context.read<ScanTargetCubit>().select(null);
                setState(() {
                  _employeeId = e.id;
                  _phase = _Phase.idle;
                  _scores = null;
                });
              },
            ),
            const SizedBox(height: 14),
            _RequiredRow(
              items: settings.requiredList,
              scores: scores,
              settings: settings,
            ),
            const SizedBox(height: 14),
            _Viewfinder(
              phase: _phase,
              sweep: _sweep,
              boxes: boxes,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (_phase) {
                _Phase.idle => FilledButton.icon(
                  key: const ValueKey('start'),
                  onPressed: () => _start(settings),
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  label: const Text('Start scan'),
                ),
                _Phase.analyzing => const FilledButton(
                  key: ValueKey('busy'),
                  onPressed: null,
                  child: Text('Analyzing…'),
                ),
                _Phase.done => _ResultCard(
                  key: const ValueKey('result'),
                  employee: employee,
                  scores: scores!,
                  settings: settings,
                  onSave: () => _save(employee, settings),
                  onRescan: () => _start(settings),
                  onDiscard: _discard,
                ),
              },
            ),
            if (_phase == _Phase.idle) ...[
              const SizedBox(height: 14),
              Text(
                'Point the camera at the worker, then tap Start scan. '
                'This build uses a simulated detector; a real on-device '
                'model plugs in through the PpeDetector interface.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _NoEmployees extends StatelessWidget {
  const _NoEmployees();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: EmptyState(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Add your team first',
        message: 'Register at least one employee so scans can be assigned.',
        action: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(180, 52)),
          onPressed: () => context.read<NavCubit>().go(AppTab.employees),
          child: const Text('Go to team'),
        ),
      ),
    );
  }
}

class _EmployeePicker extends StatelessWidget {
  const _EmployeePicker({
    required this.employee,
    required this.enabled,
    required this.onChanged,
  });

  final Employee employee;
  final bool enabled;
  final ValueChanged<Employee> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      semanticLabel: 'Scanning ${employee.name}. Tap to change employee',
      onTap: () async {
        if (!enabled) return;
        final picked = await showModalBottomSheet<Employee>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => BlocProvider.value(
            value: context.read<SafetyCubit>(),
            child: const _PickerSheet(),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            EmployeeAvatar(employee: employee),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCANNING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(employee.name, style: theme.textTheme.titleMedium),
                  Text(
                    '${employee.code} · ${employee.department}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.unfold_more_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet();

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SafetyCubit>().state;
    final today = DateTime.now();
    final list = [
      for (final e in state.employees)
        if (e.name.toLowerCase().contains(_query.toLowerCase()) ||
            e.code.toLowerCase().contains(_query.toLowerCase()))
          e,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search name or ID',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final e = list[i];
                final done = state.checkIn(e.id, today) != null;
                return ListTile(
                  leading: EmployeeAvatar(employee: e, radius: 20),
                  title: Text(e.name),
                  subtitle: Text('${e.code} · ${e.department}'),
                  trailing: done
                      ? const StatusPill(
                          label: 'Scanned today',
                          color: AppColors.success,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(e),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredRow extends StatelessWidget {
  const _RequiredRow({
    required this.items,
    required this.scores,
    required this.settings,
  });

  final List<PpeItem> items;
  final Map<PpeItem, double>? scores;
  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Required',
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(item.label, style: theme.textTheme.labelMedium),
              ],
            ),
          ),
      ],
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.phase,
    required this.sweep,
    required this.boxes,
  });

  final _Phase phase;
  final Animation<double> sweep;
  final Map<PpeItem, bool> boxes;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.02,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E293B), Color(0xFF0B1120)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _GridPainter()),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 22, 40, 56),
                child: CustomPaint(
                  painter: PersonPainter(
                    figure: Colors.white.withValues(alpha: 0.10),
                    boxes: boxes,
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CustomPaint(painter: _CornersPainter()),
                ),
              ),
              if (phase == _Phase.analyzing)
                AnimatedBuilder(
                  animation: sweep,
                  builder: (context, _) => Align(
                    alignment: Alignment(
                      0,
                      -0.9 + 1.8 * Curves.easeInOut.transform(sweep.value),
                    ),
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.7),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: _Hint(
                    text: switch (phase) {
                      _Phase.idle => 'Align the worker within the frame',
                      _Phase.analyzing => 'Detecting equipment…',
                      _Phase.done => 'Detection complete',
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const l = 28.0;
    final w = size.width;
    final h = size.height;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, l)
          ..lineTo(0, 0)
          ..lineTo(l, 0),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(w - l, 0)
          ..lineTo(w, 0)
          ..lineTo(w, l),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(0, h - l)
          ..lineTo(0, h)
          ..lineTo(l, h),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(w - l, h)
          ..lineTo(w, h)
          ..lineTo(w, h - l),
        p,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.employee,
    required this.scores,
    required this.settings,
    required this.onSave,
    required this.onRescan,
    required this.onDiscard,
    super.key,
  });

  final Employee employee;
  final Map<PpeItem, double> scores;
  final SettingsState settings;
  final VoidCallback onSave;
  final VoidCallback onRescan;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final required = settings.requiredList;
    final missing = [
      for (final i in required)
        if ((scores[i] ?? 0) < settings.threshold) i,
    ];
    final ok = missing.isEmpty;
    final color = ok ? AppColors.success : AppColors.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(
                ok ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ok ? 'All PPE detected' : 'PPE violation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: readableColor(context, color),
                      ),
                    ),
                    Text(
                      ok
                          ? '${employee.name} may enter the work area.'
                          : 'Missing: '
                                '${missing.map((m) => m.label).join(', ')}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (final item in required)
                _ChecklistRow(
                  item: item,
                  confidence: scores[item] ?? 0,
                  threshold: settings.threshold,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_alt_rounded),
          label: const Text('Save to archive'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRescan,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Rescan'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: onDiscard,
                child: const Text('Discard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Scanned ${formatTime(DateTime.now())}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.confidence,
    required this.threshold,
  });

  final PpeItem item;
  final double confidence;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ok = confidence >= threshold;
    final color = ok ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          PpeChip(item: item, ok: ok),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    minHeight: 6,
                    color: color,
                    backgroundColor: theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              formatPercent(confidence),
              textAlign: TextAlign.right,
              style: theme.textTheme.labelLarge?.copyWith(
                color: readableColor(context, color, tint: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
