import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

class CertificationProgress extends StatelessWidget {
  const CertificationProgress({
    this.currentStep = 1,
    this.labels = const ['25%', '50%', '75%', '100%'],
    super.key,
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final activeStep = currentStep.clamp(0, labels.length);
    final width = MediaQuery.sizeOf(context).width - context.r(32);
    return SizedBox(
      width: width,
      height: context.r(67),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(12)),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              AppColors.certificationProgressBackgroundStart,
              AppColors.surface,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.r(12),
            context.r(12),
            context.r(12),
            context.r(31),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  labels.length,
                  (index) => Container(
                    key: Key('certificationProgressSegment-$index'),
                    width: context.r(50),
                    height: context.r(6),
                    color: index < activeStep
                        ? AppColors.certificationProgressActive
                        : AppColors.certificationProgressInactive,
                  ),
                ),
              ),
              SizedBox(height: context.r(4)),
              SizedBox(
                height: context.r(14),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: context.r(14),
                    right: context.r(11),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var index = 0; index < labels.length; index++)
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: index < activeStep
                                ? AppColors.certificationProgressActive
                                : AppColors.certificationProgressInactive,
                            fontSize: context.r(10),
                            fontWeight: FontWeight.w600,
                            height: 14 / 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
