import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/core/state/async_state.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';

typedef HomeLoader = Future<HomeData> Function();
typedef HomeLoadingAction = Future<void> Function();

class HomeCubit extends Cubit<AsyncState<HomeData>> {
  HomeCubit({
    required HomeLoader loadHome,
    HomeLoadingAction? showLoading,
    HomeLoadingAction? dismissLoading,
  }) : _loadHome = loadHome,
       _showLoading = showLoading ?? _noOp,
       _dismissLoading = dismissLoading ?? _noOp,
       super(const AsyncInitial());

  final HomeLoader _loadHome;
  final HomeLoadingAction _showLoading;
  final HomeLoadingAction _dismissLoading;
  int _requestId = 0;

  Future<void> load() async {
    if (isClosed) return;
    final requestId = ++_requestId;
    unawaited(_showLoading());
    final previousData = switch (state) {
      AsyncData<HomeData>(:final data) => data,
      AsyncLoading<HomeData>(:final previousData) => previousData,
      AsyncFailure<HomeData>(:final previousData) => previousData,
      _ => null,
    };
    emit(AsyncLoading(previousData: previousData));
    try {
      final data = await _loadHome();
      if (isClosed || requestId != _requestId) return;
      emit(data.isEmpty ? const AsyncEmpty() : AsyncData(data));
    } catch (error, stackTrace) {
      if (isClosed || requestId != _requestId) return;
      emit(
        AsyncFailure(
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
    } finally {
      if (!isClosed && requestId == _requestId) {
        await _dismissLoading();
      }
    }
  }

  static Future<void> _noOp() async {}
}
