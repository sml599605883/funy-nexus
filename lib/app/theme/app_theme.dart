import 'package:flutter/cupertino.dart';
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
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: _NoSwipeCupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: _NoSwipeCupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

class _NoSwipeCupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoSwipeCupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration =>
      CupertinoRouteTransitionMixin.kTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: false,
        child: child,
      );
    }
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    );
  }
}
