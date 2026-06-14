import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../main.dart' show flushPendingError;
import '../../core/services/yolo_service.dart' show CrashReportService;
import '../error/error_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      flushPendingError();
      // Cek crash dari launch sebelumnya
      final crash = await CrashReportService.getLastCrash();
      if (crash != null && crash.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ErrorScreen(
              error: crash,
              stackTrace: null,
              context: 'Native Crash (launch sebelumnya)',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dark green top blob
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkGreen,
              ),
            ),
          ),
          // Dark green bottom blob
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 260.w,
              height: 260.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkGreen,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo card
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Stack untuk membungkus gambar logo dan tombol setting
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // GANTI: Bagian ini sekarang menampilkan Gambar
                              Container(
                                width: 180.w,
                                height: 120.h, // Disesuaikan sedikit
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.asset(
                                    'assets/images/logo.png', // Sesuaikan path ini
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              // Gear badge (Tetap di pojok kanan atas)
                              Positioned(
                                top: -14,
                                right: -14,
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white,
                                  ),
                                  child: Icon(
                                    Icons.settings,
                                    color: AppColors.darkGreen,
                                    size: 28.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                    // Slogan
                    Text(
                      AppConstants.appSlogan,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    // GO START button
                    AppButton(
                      label: 'GO START',
                      width: 220.w,
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppConstants.routeHome),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
