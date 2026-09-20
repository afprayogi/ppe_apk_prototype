import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:gearguard/domain/ppe_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.supervisor = 'Supervisor',
    this.siteName = 'Main Site',
    this.onboardingDone = false,
    this.threshold = 0.6,
    this.required = PpeItem.defaults,
    this.notifications = true,
  });

  final ThemeMode themeMode;
  final String supervisor;
  final String siteName;
  final bool onboardingDone;

  /// Minimum detector confidence (0–1) to count an item as worn.
  final double threshold;
  final Set<PpeItem> required;
  final bool notifications;

  /// Required items in a stable display order.
  List<PpeItem> get requiredList =>
      PpeItem.values.where(required.contains).toList(growable: false);

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? supervisor,
    String? siteName,
    bool? onboardingDone,
    double? threshold,
    Set<PpeItem>? required,
    bool? notifications,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    supervisor: supervisor ?? this.supervisor,
    siteName: siteName ?? this.siteName,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    threshold: threshold ?? this.threshold,
    required: required ?? this.required,
    notifications: notifications ?? this.notifications,
  );
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(_read(_prefs));

  static const _kTheme = 'settings.themeMode';
  static const _kSupervisor = 'settings.supervisor';
  static const _kSite = 'settings.site';
  static const _kOnboarding = 'settings.onboardingDone';
  static const _kThreshold = 'settings.threshold';
  static const _kRequired = 'settings.required';
  static const _kNotifications = 'settings.notifications';

  final SharedPreferences _prefs;

  static SettingsState _read(SharedPreferences p) {
    final stored = p.getStringList(_kRequired);
    return SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(_kTheme),
        orElse: () => ThemeMode.system,
      ),
      supervisor: p.getString(_kSupervisor) ?? 'Supervisor',
      siteName: p.getString(_kSite) ?? 'Main Site',
      onboardingDone: p.getBool(_kOnboarding) ?? false,
      threshold: p.getDouble(_kThreshold) ?? 0.6,
      required: stored == null
          ? PpeItem.defaults
          : {
              for (final i in PpeItem.values)
                if (stored.contains(i.name)) i,
            },
      notifications: p.getBool(_kNotifications) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setSupervisor(String name) async {
    final v = name.trim();
    if (v.isEmpty) return;
    emit(state.copyWith(supervisor: v));
    await _prefs.setString(_kSupervisor, v);
  }

  Future<void> setSiteName(String name) async {
    final v = name.trim();
    if (v.isEmpty) return;
    emit(state.copyWith(siteName: v));
    await _prefs.setString(_kSite, v);
  }

  Future<void> completeOnboarding() async {
    emit(state.copyWith(onboardingDone: true));
    await _prefs.setBool(_kOnboarding, true);
  }

  Future<void> setThreshold(double value) async {
    final v = value.clamp(0.3, 0.95);
    emit(state.copyWith(threshold: v));
    await _prefs.setDouble(_kThreshold, v);
  }

  /// Toggles an item; at least one item must stay required.
  Future<void> toggleRequired(PpeItem item) async {
    final next = {...state.required};
    if (!next.remove(item)) next.add(item);
    if (next.isEmpty) return;
    emit(state.copyWith(required: next));
    await _prefs.setStringList(_kRequired, [for (final i in next) i.name]);
  }

  Future<void> setNotifications({required bool enabled}) async {
    emit(state.copyWith(notifications: enabled));
    await _prefs.setBool(_kNotifications, enabled);
  }
}
