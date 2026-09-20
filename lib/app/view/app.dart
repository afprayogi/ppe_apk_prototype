import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/cubits/nav_cubit.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/cubits/settings_cubit.dart';
import 'package:gearguard/data/ppe_detector.dart';
import 'package:gearguard/data/safety_repository.dart';
import 'package:gearguard/features/onboarding/onboarding_page.dart';
import 'package:gearguard/features/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget {
  const App({required this.prefs, this.detector, super.key});

  final SharedPreferences prefs;

  /// Override to plug in a real model (or a fast fake in tests).
  final PpeDetector? detector;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<PpeDetector>(
      create: (_) => detector ?? SimulatedDetector(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(prefs)),
          BlocProvider(create: (_) => SafetyCubit(SafetyRepository(prefs))),
          BlocProvider(create: (_) => NavCubit()),
          BlocProvider(create: (_) => ScanTargetCubit()),
        ],
        child: const _GearGuardApp(),
      ),
    );
  }
}

class _GearGuardApp extends StatelessWidget {
  const _GearGuardApp();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    return MaterialApp(
      title: 'GearGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
          child: child!,
        );
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: settings.onboardingDone
            ? const AppShell(key: ValueKey('shell'))
            : const OnboardingPage(key: ValueKey('onboarding')),
      ),
    );
  }
}
