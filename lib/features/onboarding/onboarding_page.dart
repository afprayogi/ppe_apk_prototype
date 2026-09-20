import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/widgets/gear_logo.dart';
import 'package:gearguard/core/widgets/safety_widgets.dart';
import 'package:gearguard/cubits/settings_cubit.dart';
import 'package:gearguard/domain/ppe_item.dart';
import 'package:gearguard/features/scanner/person_painter.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const List<({String body, String title})> _slides = [
    (
      title: 'Safer sites,\nstarting at the gate.',
      body:
          'GearGuard checks every worker for the right protective '
          'equipment before they step onto the job.',
    ),
    (
      title: 'Scan in a\nsingle tap.',
      body:
          'Helmet, vest, gloves, boots — see what is worn and what is '
          'missing, with a confidence score for each item.',
    ),
    (
      title: 'Reports you can\nactually use.',
      body:
          'Track attendance, spot repeat offenders and export a clean '
          'PDF for your safety audits.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      unawaited(context.read<SettingsCubit>().completeOnboarding());
    } else {
      unawaited(
        _controller.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  const GearWordmark(size: 28),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: last ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: last
                          ? null
                          : () => context
                                .read<SettingsCubit>()
                                .completeOnboarding(),
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(child: _Illustration(index: i)),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _slides[i].title,
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _slides[i].body,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Row(
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(150, 56),
                    ),
                    onPressed: _next,
                    child: Text(last ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => const _ShieldHero(),
      1 => const _ScanPreview(),
      _ => const _ReportPreview(),
    };
  }
}

class _ShieldHero extends StatelessWidget {
  const _ShieldHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final (d, a) in const [
          (300.0, 0.05),
          (230.0, 0.08),
          (160.0, 0.12),
        ])
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: a),
            ),
          ),
        const GearLogo(size: 120),
      ],
    );
  }
}

class _ScanPreview extends StatelessWidget {
  const _ScanPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 300,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0B1120)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.25),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
      child: CustomPaint(
        painter: PersonPainter(
          figure: Colors.white.withValues(alpha: 0.10),
          labelStyle: Theme.of(context).textTheme.labelSmall,
          boxes: const {
            PpeItem.helmet: true,
            PpeItem.vest: true,
            PpeItem.gloves: false,
            PpeItem.boots: true,
          },
        ),
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = DateTime.now();
    return Container(
      width: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const ComplianceRing(value: 0.92, size: 84, stroke: 9),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This week', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    const StatusPill(
                      label: '+6% vs last',
                      color: AppColors.success,
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          WeeklyChart(
            days: [
              for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
            ],
            values: const [0.8, 0.95, 0.7, 1, 0.9, 0.85, 0.96],
          ),
        ],
      ),
    );
  }
}
