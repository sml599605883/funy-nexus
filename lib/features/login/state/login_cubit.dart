import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/session/session_store.dart';

typedef LoginMessagePresenter = Future<void> Function(String message);
typedef LoginSuccessCallback = Future<void> Function();

class LoginState {
  const LoginState({
    this.agreementAccepted = true,
    this.requestingCode = false,
    this.loggingIn = false,
    this.countdownSeconds = 0,
  });

  final bool agreementAccepted;
  final bool requestingCode;
  final bool loggingIn;
  final int countdownSeconds;

  LoginState copyWith({
    bool? agreementAccepted,
    bool? requestingCode,
    bool? loggingIn,
    int? countdownSeconds,
  }) {
    return LoginState(
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
      requestingCode: requestingCode ?? this.requestingCode,
      loggingIn: loggingIn ?? this.loggingIn,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required this.apiClient,
    required this.sessionStore,
    required this.showMessage,
    required this.onLoginSuccess,
    this.countdownInterval = const Duration(seconds: 1),
  }) : super(const LoginState());

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final LoginMessagePresenter showMessage;
  final LoginSuccessCallback onLoginSuccess;
  final Duration countdownInterval;

  Timer? _countdownTimer;

  void toggleAgreement() {
    emit(state.copyWith(agreementAccepted: !state.agreementAccepted));
  }

  Future<bool> requestSmsCode(String phone) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty ||
        state.requestingCode ||
        state.countdownSeconds > 0) {
      return false;
    }
    emit(state.copyWith(requestingCode: true));
    try {
      final response = await apiClient.sendLoginSmsCode(phone: normalizedPhone);
      await showMessage(response.message);
      _startCountdown();
      return true;
    } catch (error) {
      await showMessage(_messageFor(error));
      return false;
    } finally {
      emit(state.copyWith(requestingCode: false));
    }
  }

  Future<bool> submitSmsCode({
    required String phone,
    required String code,
  }) async {
    if (state.loggingIn) {
      return false;
    }
    if (!state.agreementAccepted) {
      await showMessage(
        'Please agree to the Privacy Policy and Terms of Service',
      );
      return false;
    }
    final normalizedPhone = phone.trim();
    final normalizedCode = code.trim();
    if (normalizedPhone.isEmpty || normalizedCode.length != 6) {
      return false;
    }

    emit(state.copyWith(loggingIn: true));
    try {
      final response = await apiClient.loginWithSmsCode(
        phone: normalizedPhone,
        code: normalizedCode,
      );
      final sessionId = response.data.coccolith.trim();
      if (sessionId.isEmpty) {
        throw const ApiException(
          type: ApiFailureType.invalidResponse,
          message: 'Invalid login response',
        );
      }
      await sessionStore.save(phone: normalizedPhone, sessionId: sessionId);
      await onLoginSuccess();
      return true;
    } catch (error) {
      await showMessage(_messageFor(error));
      return false;
    } finally {
      emit(state.copyWith(loggingIn: false));
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    emit(state.copyWith(countdownSeconds: 60));
    _countdownTimer = Timer.periodic(countdownInterval, (timer) {
      if (state.countdownSeconds <= 1) {
        timer.cancel();
        emit(state.copyWith(countdownSeconds: 0));
      } else {
        emit(state.copyWith(countdownSeconds: state.countdownSeconds - 1));
      }
    });
  }

  static String _messageFor(Object error) {
    return error is ApiException ? error.message : 'Unexpected request error';
  }

  @override
  Future<void> close() async {
    _countdownTimer?.cancel();
    await super.close();
  }
}
