import 'package:flutter/material.dart';

/// Shared layout metrics for the 375 logical-pixel design grid.
class AppResponsive extends InheritedWidget {
  const AppResponsive({
    required this.scale,
    required this.heightScale,
    required super.child,
    super.key,
  });

  static const designWidth = 375.0;
  static const designHeight = 812.0;
  final double scale;
  final double heightScale;

  static AppResponsive of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppResponsive>() ??
        const AppResponsive(scale: 1, heightScale: 1, child: SizedBox.shrink());
  }

  double w(num value) => value * scale;
  double h(num value) => value * heightScale;
  double sp(num value) => value * scale;
  double r(num value) => value * scale;
  double size(double value) => w(value);
  double get width => designWidth * scale;

  @override
  bool updateShouldNotify(AppResponsive oldWidget) =>
      scale != oldWidget.scale || heightScale != oldWidget.heightScale;
}

class ResponsiveScope extends StatelessWidget {
  const ResponsiveScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.size.width / AppResponsive.designWidth;
    final heightScale = media.size.height / AppResponsive.designHeight;
    return AppResponsive(scale: scale, heightScale: heightScale, child: child);
  }
}

extension ResponsiveContext on BuildContext {
  AppResponsive get responsive => AppResponsive.of(this);
  double r(double value) => responsive.r(value);
}
