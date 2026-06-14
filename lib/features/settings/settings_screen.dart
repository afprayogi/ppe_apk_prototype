import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/yolo_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _svc = SettingsService.instance;
  late TextEditingController _companyCtrl;

  @override
  void initState() {
    super.initState();
    _companyCtrl = TextEditingController(text: _svc.companyName);
    _svc.addListener(_onChanged);
  }

  void _onChanged() => setState(() {
        _companyCtrl.text = _svc.companyName;
      });

  @override
  void dispose() {
    _svc.removeListener(_onChanged);
    _companyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _svc.darkMode;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF333333) : AppColors.divider;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pengaturan', style: AppTextStyles.headlineOnGreen),
      ),
      body: ListView(
        padding: EdgeInsets.all(14.r),
        children: [
          // ── Tampilan ───────────────────────────────────────────────────────
          _SectionHeader('Tampilan'),
          _SettingCard(
            cardColor: cardColor,
            borderColor: borderColor,
            child: SwitchListTile(
              value: isDark,
              onChanged: (v) => _svc.setDarkMode(v),
              activeColor: AppColors.primaryGreen,
              title: Text('Dark Mode', style: AppTextStyles.titleMedium),
              subtitle: Text(isDark ? 'Tema Gelap aktif' : 'Tema Terang aktif',
                  style: AppTextStyles.bodyMedium),
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // ── Perusahaan ─────────────────────────────────────────────────────
          _SectionHeader('Identitas'),
          _SettingCard(
            cardColor: cardColor,
            borderColor: borderColor,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama Perusahaan', style: AppTextStyles.titleMedium),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _companyCtrl,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'PT Vivatpass',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: AppColors.primaryGreen),
                        onPressed: () {
                          _svc.setCompanyName(_companyCtrl.text);
                          FocusScope.of(context).unfocus();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama disimpan')));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // ── AI Konfigurasi ──────────────────────────────────────────────────
          _SectionHeader('Konfigurasi AI'),
          _SettingCard(
            cardColor: cardColor,
            borderColor: borderColor,
            child: Padding(
              padding: EdgeInsets.all(14.r),
              child: Column(
                children: [
                  _SliderRow(
                    label: 'Confidence Threshold',
                    value: _svc.confThreshold,
                    min: 0.05, max: 0.90, divisions: 17,
                    format: (v) => '${(v * 100).toInt()}%',
                    hint: 'Rendah = lebih sensitif, Tinggi = lebih presisi',
                    onChanged: (v) => _svc.setConfThreshold(v),
                  ),
                  const Divider(),
                  _SliderRow(
                    label: 'IoU Threshold (NMS)',
                    value: _svc.iouThreshold,
                    min: 0.1, max: 0.9, divisions: 16,
                    format: (v) => '${(v * 100).toInt()}%',
                    hint: 'Rendah = lebih sedikit duplikat bbox',
                    onChanged: (v) => _svc.setIouThreshold(v),
                  ),
                  const Divider(),
                  _SliderRow(
                    label: 'Interval Scan Live',
                    value: _svc.scanIntervalMs.toDouble(),
                    min: 300, max: 3000, divisions: 27,
                    format: (v) => '${v.toInt()}ms',
                    hint: 'Lebih kecil = lebih responsif tapi berat',
                    onChanged: (v) => _svc.setScanInterval(v.toInt()),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // ── APD yang Dipindai ──────────────────────────────────────────────
          _SectionHeader('APD yang Dipindai'),
          _SettingCard(
            cardColor: cardColor,
            borderColor: borderColor,
            child: Column(
              children: SettingsService.kLabelDefaults.entries.map((e) {
                final label    = e.key;
                final display  = kPpeLabelMap[label] ?? label;
                final enabled  = _svc.isLabelEnabled(label);
                return SwitchListTile(
                  dense: true,
                  value: enabled,
                  onChanged: (v) => _svc.setLabelEnabled(label, v),
                  activeColor: AppColors.primaryGreen,
                  title: Text(display, style: AppTextStyles.bodyMedium),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 8.h),

          // ── Penyimpanan ─────────────────────────────────────────────────────
          _SectionHeader('Penyimpanan'),
          _SettingCard(
            cardColor: cardColor,
            borderColor: borderColor,
            child: SwitchListTile(
              value: _svc.autoSave,
              onChanged: (v) => _svc.setAutoSave(v),
              activeColor: AppColors.primaryGreen,
              title: Text('Auto-simpan Foto Hasil Scan',
                  style: AppTextStyles.titleMedium),
              subtitle: Text(_svc.autoSave
                  ? 'Foto disimpan otomatis ke penyimpanan lokal'
                  : 'Foto tidak disimpan',
                  style: AppTextStyles.bodyMedium),
              secondary: const Icon(Icons.save_alt,
                  color: AppColors.primaryGreen),
            ),
          ),
          SizedBox(height: 16.h),

          // ── Reset ───────────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Reset Pengaturan?'),
                  content: const Text(
                      'Semua pengaturan akan dikembalikan ke default.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) {
                await _svc.resetAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengaturan direset')));
                }
              }
            },
            icon: const Icon(Icons.restore, color: Colors.red),
            label: Text('Reset ke Default',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 6.h, top: 8.h),
        child: Text(text,
            style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
      );
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  final Color cardColor, borderColor;
  const _SettingCard(
      {required this.child,
      required this.cardColor,
      required this.borderColor});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
}

class _SliderRow extends StatelessWidget {
  final String label, hint;
  final double value, min, max;
  final int divisions;
  final String Function(double) format;
  final void Function(double) onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(format(value),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min, max: max, divisions: divisions,
          activeColor: AppColors.primaryGreen,
          onChanged: onChanged,
        ),
        Text(hint,
            style: AppTextStyles.labelSmall.copyWith(color: Colors.grey)),
        SizedBox(height: 4.h),
      ],
    );
  }
}
