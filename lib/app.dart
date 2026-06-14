import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'constants/app_constants.dart';
import 'core/services/settings_service.dart';
import 'main.dart' show navigatorKey;
import 'features/absensi/absensi_screen.dart';
import 'features/archive/archive_screen.dart';
import 'features/home/home_screen.dart';
import 'features/info/info_screen.dart';
import 'features/rank/rank_screen.dart';
import 'features/register/register_screen.dart';
import 'features/scanner/detail_screen.dart';
import 'features/scanner/result_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/error/error_screen.dart';
import 'features/train/train_screen.dart';
import 'features/employee/employee_history_screen.dart';
import 'models/detection_model.dart';
import 'models/employee_model.dart';
import 'theme/app_theme.dart';

class VivatPassApp extends StatefulWidget {
  const VivatPassApp({super.key});

  @override
  State<VivatPassApp> createState() => _VivatPassAppState();
}

class _VivatPassAppState extends State<VivatPassApp> {
  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChange);
  }

  void _onSettingsChange() => setState(() {});

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        navigatorKey: navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme:      AppTheme.light,
        darkTheme:  AppTheme.dark,
        themeMode:  SettingsService.instance.themeMode,
        initialRoute: AppConstants.routeSplash,
        routes: {
          AppConstants.routeSplash:    (_) => const SplashScreen(),
          AppConstants.routeHome:      (_) => const HomeScreen(),
          AppConstants.routeRegister:  (_) => const RegisterScreen(),
          AppConstants.routeAbsensi:   (_) => const AbsensiScreen(),
          AppConstants.routeScanner:   (_) => const ScannerScreen(),
          AppConstants.routeResult:    (_) => const ResultScreen(),
          AppConstants.routeRank:      (_) => const RankScreen(),
          AppConstants.routeArchive:   (_) => const ArchiveScreen(),
          AppConstants.routeTrain:     (_) => const TrainScreen(),
          AppConstants.routeInfo:      (_) => const InfoScreen(),
          AppConstants.routeSettings:  (_) => const SettingsScreen(),
          '/error': (ctx) {
            final args = ModalRoute.of(ctx)?.settings.arguments
                as Map<String, dynamic>?;
            return ErrorScreen(
              error:      args?['error'],
              stackTrace: args?['stackTrace'] as StackTrace?,
              context:    args?['context'] as String?,
            );
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppConstants.routeDetail) {
            final record = settings.arguments as DetectionRecord;
            return MaterialPageRoute(
                builder: (_) => DetailScreen(record: record));
          }
          if (settings.name == AppConstants.routeEmployeeHistory) {
            final employee = settings.arguments as EmployeeModel;
            return MaterialPageRoute(
                builder: (_) => EmployeeHistoryScreen(employee: employee));
          }
          return null;
        },
      ),
    );
  }
}
