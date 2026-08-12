import 'package:flutter/material.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

class LoginTopBar extends StatelessWidget {
  const LoginTopBar({super.key});

  @override
  Widget build(BuildContext context) => const Positioned(
    top: 54,
    left: 0,
    right: 0,
    child: Center(
      child: Text(
        'Fund Nexus',
        style: TextStyle(
          color: AppColors.surface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 24 / 17,
        ),
      ),
    ),
  );
}

class LoginBanner extends StatelessWidget {
  const LoginBanner({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 343 / 126,
        child: Image.asset(AppAssets.loginBanner, fit: BoxFit.cover),
      ),
    ),
  );
}

class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) => const Positioned(
    top: 112,
    left: 152,
    width: 72,
    height: 72,
    child: Image(image: AssetImage(AppAssets.loginLogo), fit: BoxFit.cover),
  );
}
