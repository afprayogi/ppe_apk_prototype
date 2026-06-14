import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorScreen extends StatelessWidget {
  final Object? error;
  final StackTrace? stackTrace;
  final String? context;

  const ErrorScreen({
    super.key,
    this.error,
    this.stackTrace,
    this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final errorText = error?.toString() ?? 'Unknown error';
    final stackText = stackTrace?.toString() ?? '';
    final fullLog   = '=== ERROR ===\n$errorText\n\n=== CONTEXT ===\n${context ?? "-"}\n\n=== STACK TRACE ===\n$stackText';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: const Text('App Crashed', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: 'Copy log',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: fullLog));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Log disalin ke clipboard')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.redAccent, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Terjadi Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (context != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Context: $context',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  errorText,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Stack Trace:',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      stackText.isEmpty ? '(no stack trace)' : stackText,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Kembali ke Home', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(ctx).pushNamedAndRemoveUntil('/home', (_) => false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
