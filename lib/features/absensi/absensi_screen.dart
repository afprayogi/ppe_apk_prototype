import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../models/detection_model.dart';
import '../../providers/detection_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/employee_card.dart';
import 'tabs/graph_tab.dart';
import 'tabs/personalia_tab.dart';

class AbsensiScreen extends HookConsumerWidget {
  const AbsensiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabCtrl = useTabController(initialLength: 3);
    final searchQuery = useState('');
    final state = ref.watch(detectionProvider);

    List<DetectionRecord> filtered() {
      if (searchQuery.value.isEmpty) return state.records;
      final q = searchQuery.value.toLowerCase();
      return state.records
          .where((r) =>
              r.employeeName.toLowerCase().contains(q) || r.nia.contains(q))
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Absensi', style: AppTextStyles.headlineOnGreen),
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(46.h),
          child: _TabBar(controller: tabCtrl),
        ),
      ),
      body: TabBarView(
        controller: tabCtrl,
        children: [
          // ── Absensi Tab ──
          Builder(
            builder: (context) {
              final records = filtered();
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12.r),
                    child: AppSearchBar(
                      hint: 'Cari nama / NIA',
                      onChanged: (v) => searchQuery.value = v,
                    ),
                  ),
                  Expanded(
                    child: records.isEmpty
                        ? Center(
                            child: Text('Belum ada data deteksi',
                                style: AppTextStyles.bodyMedium))
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            itemCount: records.length,
                            itemBuilder: (_, i) => EmployeeDetectionCard(
                              record: records[i],
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppConstants.routeDetail,
                                arguments: records[i],
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          // ── Graph Tab ──
          const GraphTab(),
          // ── Personalia Tab ──
          const PersonaliaTab(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i == 1) return;
          switch (i) {
            case 0: Navigator.pop(context);
            case 2: Navigator.pushNamed(context, AppConstants.routeScanner);
            case 3: Navigator.pushNamed(context, AppConstants.routeTrain);
            case 4: Navigator.pushNamed(context, AppConstants.routeInfo);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _TabBar extends StatelessWidget {
  final TabController controller;

  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkGreen,
      child: TabBar(
        controller: controller,
        labelColor: AppColors.darkGreen,
        unselectedLabelColor: AppColors.white,
        indicator: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        indicatorPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
        tabs: const [
          Tab(text: 'ABSENSI'),
          Tab(text: 'Graph'),
          Tab(text: 'Personalia'),
        ],
        labelStyle: AppTextStyles.labelLarge.copyWith(
          color: AppColors.darkGreen,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}
