import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/core/widgets/gear_logo.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/cubits/settings_cubit.dart';
import 'package:gearguard/domain/ppe_item.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _Group(
            title: 'Site',
            children: [
              _EditTile(
                icon: Icons.person_rounded,
                label: 'Supervisor',
                value: settings.supervisor,
                onSave: cubit.setSupervisor,
              ),
              _EditTile(
                icon: Icons.location_city_rounded,
                label: 'Site name',
                value: settings.siteName,
                onSave: cubit.setSiteName,
              ),
            ],
          ),
          _Group(
            title: 'Required equipment',
            footer:
                'Scans are marked as violations when a required item '
                'is not detected. At least one item must stay selected.',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in PpeItem.values)
                      FilterChip(
                        selected: settings.required.contains(item),
                        onSelected: (_) => cubit.toggleRequired(item),
                        avatar: Icon(item.icon, size: 18),
                        label: Text(item.label),
                      ),
                  ],
                ),
              ),
            ],
          ),
          _Group(
            title: 'Detection',
            footer:
                'Higher values are stricter: the detector must be more '
                'confident before an item counts as worn.',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Confidence threshold')),
                        Text(
                          formatPercent(settings.threshold),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.threshold,
                      min: 0.3,
                      max: 0.95,
                      divisions: 13,
                      label: formatPercent(settings.threshold),
                      onChanged: cubit.setThreshold,
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_rounded),
                title: const Text('Violation alerts'),
                subtitle: const Text('Highlight scans with missing PPE'),
                value: settings.notifications,
                onChanged: (v) => cubit.setNotifications(enabled: v),
              ),
            ],
          ),
          _Group(
            title: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('Auto'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => cubit.setThemeMode(s.first),
                  ),
                ),
              ),
            ],
          ),
          _Group(
            title: 'Data',
            children: [
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text('Reload demo data'),
                subtitle: const Text('Restore the sample team and history'),
                onTap: () => _confirm(
                  context,
                  title: 'Reload demo data?',
                  message: 'This replaces your current team and scans.',
                  action: 'Reload',
                  onConfirm: context.read<SafetyCubit>().resetDemoData,
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppColors.danger,
                ),
                title: const Text('Clear scan history'),
                subtitle: const Text('Employees are kept'),
                onTap: () => _confirm(
                  context,
                  title: 'Clear all scans?',
                  message: 'Every stored scan will be permanently deleted.',
                  action: 'Clear',
                  destructive: true,
                  onConfirm: context.read<SafetyCubit>().clearScans,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const GearLogo(),
                const SizedBox(height: 10),
                Text('GearGuard 1.0.0', style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  'Designed & built with Flutter',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    required Future<void> Function() onConfirm,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              action,
              style: destructive
                  ? const TextStyle(color: AppColors.danger)
                  : null,
            ),
          ),
        ],
      ),
    );
    if (ok ?? false) await onConfirm();
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children, this.footer});

  final String title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditTile extends StatelessWidget {
  const _EditTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onSave,
  });

  final IconData icon;
  final String label;
  final String value;
  final Future<void> Function(String) onSave;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_rounded, size: 18),
      onTap: () async {
        final controller = TextEditingController(text: value);
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(label),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 28,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        controller.dispose();
        if (result != null) await onSave(result);
      },
    );
  }
}
