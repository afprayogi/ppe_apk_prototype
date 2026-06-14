import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Info Aplikasi', style: AppTextStyles.headlineOnGreen),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // App logo card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Icon(Icons.security, size: 60.sp, color: AppColors.white),
                  SizedBox(height: 12.h),
                  Text('VIVATPASS',
                      style: AppTextStyles.headlineLarge
                          .copyWith(color: AppColors.white, fontSize: 28.sp)),
                  SizedBox(height: 4.h),
                  Text('Scan. Detect. Protect.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.white)),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text('Version 1.0.0',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            _InfoSection(title: 'Tentang Aplikasi', items: const [
              _InfoItem(
                icon: Icons.info_outline,
                label: 'Deskripsi',
                value:
                    'VivatPass adalah sistem deteksi APD (Alat Pelindung Diri) berbasis AI '
                    'yang membantu memantau keselamatan kerja di lingkungan industri.',
              ),
              _InfoItem(
                icon: Icons.verified_user,
                label: 'Standar',
                value: 'ISO 45001 – Sistem Manajemen Keselamatan Kerja',
              ),
            ]),
            SizedBox(height: 12.h),

            _InfoSection(title: 'APD yang Dideteksi', items: const [
              _InfoItem(icon: Icons.engineering, label: 'Helmet', value: 'Helm keselamatan standar SNI'),
              _InfoItem(icon: Icons.checkroom,   label: 'Vest',   value: 'Rompi keselamatan berreflector'),
              _InfoItem(icon: Icons.safety_divider, label: 'Boots', value: 'Sepatu safety steel toe'),
              _InfoItem(icon: Icons.back_hand_outlined, label: 'Gloves', value: 'Sarung tangan anti-cut'),
              _InfoItem(icon: Icons.remove_red_eye_outlined, label: 'Glass', value: 'Kacamata keselamatan / face shield'),
            ]),
            SizedBox(height: 12.h),

            _InfoSection(title: 'Teknologi', items: const [
              _InfoItem(icon: Icons.phone_android, label: 'Framework', value: 'Flutter 3.x'),
              _InfoItem(icon: Icons.memory, label: 'AI Engine', value: 'TensorFlow Lite (YOLOv8)'),
              _InfoItem(icon: Icons.storage, label: 'Database', value: 'SQLite (sqflite)'),
              _InfoItem(icon: Icons.camera_alt, label: 'Camera', value: 'Real-time 30fps inference'),
            ]),
            SizedBox(height: 24.h),

            Text(
              '© 2026 VivatPass. All rights reserved.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        onTap: (i) => Navigator.pop(context),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Text(title,
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.primaryGreen)),
          ),
          const Divider(height: 1),
          ...items.map((item) => Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon,
                        size: 20.sp, color: AppColors.primaryGreen),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: AppTextStyles.titleMedium
                                  .copyWith(fontSize: 13.sp)),
                          SizedBox(height: 2.h),
                          Text(item.value,
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}
