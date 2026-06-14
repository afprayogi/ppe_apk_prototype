import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'core/services/settings_service.dart';
import 'core/services/yolo_service.dart';
import 'features/error/error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Global Flutter error handler ---
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _navigateToError(details.exception, details.stack, details.context?.toDescription());
  };

  // --- PlatformDispatcher: catch async errors outside Flutter tree ---
  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    // Abaikan error font network – bukan crash fatal
    _navigateToError(error, stack, 'PlatformDispatcher');
    return true;
  };

  // --- Uncaught async errors (Isolate) ---
  Isolate.current.addErrorListener(RawReceivePort((List<dynamic> pair) {
    final error = pair[0];
    final stack = pair[1] != null ? StackTrace.fromString(pair[1] as String) : null;
    _navigateToError(error, stack, 'Isolate');
  }).sendPort);

  // Init settings (dark mode, threshold, dll)
  await SettingsService.instance.init();

  // Request kamera & storage permissions
  await [Permission.camera, Permission.storage].request();

  // Inisialisasi TFLite – error ditampilkan di error screen
  try {
    await YoloService.instance.initialize();
  } catch (e, st) {
    _pendingError = (e, st);
  }

  runApp(
    const ProviderScope(
      child: VivatPassApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

(Object, StackTrace?)? _pendingError;

void _navigateToError(Object error, StackTrace? stack, String? context) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => ErrorScreen(
        error: error,
        stackTrace: stack,
        context: context,
      ),
    ),
  );
}

/// Dipanggil dari app.dart setelah navigator siap
void flushPendingError() {
  final err = _pendingError;
  if (err == null) return;
  _pendingError = null;
  Future.delayed(const Duration(milliseconds: 500), () {
    _navigateToError(err.$1, err.$2, 'TFLite Initialize');
  });
}