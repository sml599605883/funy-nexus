import 'package:flutter/material.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

abstract final class AppTheme {
  static final light = ThemeData(
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.textPrimary),
    ),
  );
}
