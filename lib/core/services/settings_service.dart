import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // ── Defaults ──────────────────────────────────────────────────────────────
  static const _kDarkMode      = 'dark_mode';
  static const _kCompanyName   = 'company_name';
  static const _kConfThreshold = 'conf_threshold';
  static const _kIouThreshold  = 'iou_threshold';
  static const _kAutoSave      = 'auto_save_image';
  static const _kScanInterval  = 'scan_interval_ms';

  // ── APD label keys — default: hanya helmet, vest, safety_shoe aktif ───────
  static const _kLabelPrefix = 'label_enabled_';
  // Model label → default enabled
  static const Map<String, bool> kLabelDefaults = {
    'Gloves'     : false,
    'Vest'       : true,
    'goggles'    : false,
    'helmet'     : true,
    'mask'       : false,
    'safety_shoe': true,
  };

  // ── State ─────────────────────────────────────────────────────────────────
  bool   get darkMode      => _prefs.getBool(_kDarkMode)      ?? false;
  String get companyName   => _prefs.getString(_kCompanyName) ?? 'PT Vivatpass';
  double get confThreshold => _prefs.getDouble(_kConfThreshold) ?? 0.20;
  double get iouThreshold  => _prefs.getDouble(_kIouThreshold)  ?? 0.45;
  bool   get autoSave      => _prefs.getBool(_kAutoSave)        ?? true;
  int    get scanIntervalMs => _prefs.getInt(_kScanInterval)    ?? 1000;

  bool isLabelEnabled(String label) =>
      _prefs.getBool('$_kLabelPrefix$label') ?? (kLabelDefaults[label] ?? true);

  Set<String> get enabledLabels =>
      kLabelDefaults.keys.where(isLabelEnabled).toSet();

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<void> setDarkMode(bool v) async {
    await _prefs.setBool(_kDarkMode, v);
    notifyListeners();
  }

  Future<void> setCompanyName(String v) async {
    await _prefs.setString(_kCompanyName, v.trim().isEmpty ? 'PT Vivatpass' : v);
    notifyListeners();
  }

  Future<void> setConfThreshold(double v) async {
    await _prefs.setDouble(_kConfThreshold, v.clamp(0.05, 0.95));
    notifyListeners();
  }

  Future<void> setIouThreshold(double v) async {
    await _prefs.setDouble(_kIouThreshold, v.clamp(0.1, 0.9));
    notifyListeners();
  }

  Future<void> setAutoSave(bool v) async {
    await _prefs.setBool(_kAutoSave, v);
    notifyListeners();
  }

  Future<void> setScanInterval(int ms) async {
    await _prefs.setInt(_kScanInterval, ms.clamp(300, 3000));
    notifyListeners();
  }

  Future<void> setLabelEnabled(String label, bool v) async {
    await _prefs.setBool('$_kLabelPrefix$label', v);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _prefs.clear();
    notifyListeners();
  }
}
