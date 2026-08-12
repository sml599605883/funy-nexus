import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/state/async_state.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/home/widgets/home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, AsyncState<HomeData>>(
      listener: (context, state) {
        if (state case AsyncFailure<HomeData>(
          :final previousData,
        ) when previousData != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Unable to refresh home data')),
            );
        }
      },
      builder: (context, state) {
        final previousData = switch (state) {
          AsyncLoading<HomeData>(:final previousData) => previousData,
          AsyncFailure<HomeData>(:final previousData) => previousData,
          _ => null,
        };
        if (state case AsyncData<HomeData>(:final data)) {
          return HomeContent(
            data: data,
            onRefresh: context.read<HomeCubit>().load,
          );
        }
        if (previousData != null) {
          if (state is AsyncLoading<HomeData>) {
            return Stack(
              children: [
                HomeContent(
                  data: previousData,
                  onRefresh: context.read<HomeCubit>().load,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: context.r(88),
                  child: const LinearProgressIndicator(),
                ),
              ],
            );
          }
          return HomeContent(
            data: previousData,
            onRefresh: context.read<HomeCubit>().load,
          );
        }
        if (state is AsyncFailure<HomeData>) {
          return _HomeStatusView(
            message: 'Unable to load home data',
            onRetry: context.read<HomeCubit>().load,
          );
        }
        if (state is AsyncEmpty<HomeData>) {
          return _HomeStatusView(
            message: 'No loan offers are available',
            onRetry: context.read<HomeCubit>().load,
          );
        }
        return const _HomeStatusView();
      },
    );
  }
}

class _HomeStatusView extends StatelessWidget {
  const _HomeStatusView({this.message, this.onRetry});

  final String? message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: Center(
        child: message == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.homeCaption),
                  ),
                  SizedBox(height: context.r(16)),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
