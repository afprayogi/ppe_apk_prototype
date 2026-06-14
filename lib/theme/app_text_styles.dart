import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 48.sp,
        fontWeight: FontWeight.w900,
        color: AppColors.gold,
      );

  static TextStyle get headlineLarge => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelLarge => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textOnGreen,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // On-green variants
  static TextStyle get headlineOnGreen => headlineLarge.copyWith(color: AppColors.white);
  static TextStyle get titleOnGreen    => titleLarge.copyWith(color: AppColors.white);
  static TextStyle get bodyOnGreen     => bodyMedium.copyWith(color: AppColors.white);
}
