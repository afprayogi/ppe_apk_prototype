import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../providers/detection_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_search_bar.dart';
import 'widgets/home_header_card.dart';
import 'widgets/marquee_banner.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/recently_detect_card.dart';
import 'widgets/trend_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _navIndex = 0;

  void _onNavTap(int index) {
    switch (index) {
      case 0: setState(() => _navIndex = 0);
      case 1: Navigator.pushNamed(context, AppConstants.routeAbsensi);
      case 2: Navigator.pushNamed(context, AppConstants.routeScanner);
      case 3: Navigator.pushNamed(context, AppConstants.routeTrain);
      case 4: Navigator.pushNamed(context, AppConstants.routeInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(detectionProvider);
    final trend = ref.watch(trendDataProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      // ── Drawer ──────────────────────────────────────────────────────────
      drawer: _AppDrawer(
        onNavigate: (route) {
          Navigator.pop(context); // tutup drawer
          Navigator.pushNamed(context, route);
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text('Home', style: AppTextStyles.headlineOnGreen),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.amber,
              child: Icon(Icons.person, color: AppColors.darkGreen, size: 20.sp),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeaderCard(nonSafetyCount: state.nonSafetyCount),
                  SizedBox(height: 12.h),
                  const MarqueeBanner(),
                  SizedBox(height: 12.h),
                  AppSearchBar(
                    hint: 'Search Fitur',
                    showEditButton: true,
                    onEditTap: () =>
                        Navigator.pushNamed(context, AppConstants.routeRegister),
                  ),
                  SizedBox(height: 14.h),
                  QuickActionsRow(
                    onRegist: () =>
                        Navigator.pushNamed(context, AppConstants.routeRegister),
                    onRanked: () =>
                        Navigator.pushNamed(context, AppConstants.routeRank),
                    onArchive: () =>
                        Navigator.pushNamed(context, AppConstants.routeArchive),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RecentlyDetectCard(
                          records: state.records,
                          onDetail: (rec) => Navigator.pushNamed(
                              context, AppConstants.routeDetail,
                              arguments: rec),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(child: TrendCard(trendData: trend)),
                    ],
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ── App Drawer ──────────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final void Function(String route) onNavigate;
  const _AppDrawer({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.darkGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: AppColors.amber,
                  child: Icon(Icons.engineering,
                      color: AppColors.darkGreen, size: 32.sp),
                ),
                SizedBox(height: 8.h),
                Text('VivatPass',
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: AppColors.white)),
                Text('Scan. Detect. Protect.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.white)),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.home,
            label: 'Beranda',
            onTap: () => Navigator.pop(context),
          ),
          _DrawerItem(
            icon: Icons.person_add_alt_1,
            label: 'Daftar Karyawan',
            onTap: () => onNavigate(AppConstants.routeRegister),
          ),
          _DrawerItem(
            icon: Icons.checklist_rounded,
            label: 'Absensi & Statistik',
            onTap: () => onNavigate(AppConstants.routeAbsensi),
          ),
          _DrawerItem(
            icon: Icons.camera_alt,
            label: 'Scan APD',
            onTap: () => onNavigate(AppConstants.routeScanner),
          ),
          _DrawerItem(
            icon: Icons.archive_outlined,
            label: 'Arsip Deteksi',
            onTap: () => onNavigate(AppConstants.routeArchive),
          ),
          _DrawerItem(
            icon: Icons.bar_chart_rounded,
            label: 'Ranking',
            onTap: () => onNavigate(AppConstants.routeRank),
          ),
          _DrawerItem(
            icon: Icons.auto_fix_high,
            label: 'Model & Training',
            onTap: () => onNavigate(AppConstants.routeTrain),
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.settings,
            label: 'Pengaturan',
            onTap: () => onNavigate(AppConstants.routeSettings),
          ),
          _DrawerItem(
            icon: Icons.info_outline,
            label: 'Tentang Aplikasi',
            onTap: () => onNavigate(AppConstants.routeInfo),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(label, style: AppTextStyles.bodyLarge),
      onTap: onTap,
    );
  }
}
