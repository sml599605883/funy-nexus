import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:fund_nexus/core/json/json.dart';

class FaceLivenessResult {
  const FaceLivenessResult({
    required this.success,
    required this.code,
    required this.message,
    required this.image,
    required this.livenessId,
  });

  final bool success;
  final int code;
  final String message;
  final String image;
  final String livenessId;
}

class FaceLivenessBridge {
  FaceLivenessBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'fund_nexus/face_liveness';
  static final instance = FaceLivenessBridge();

  final MethodChannel _channel;

  Future<FaceLivenessResult> start(String license) async {
    if (!Platform.isIOS) {
      return const FaceLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is only available on iOS.',
        image: '',
        livenessId: '',
      );
    }
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'start',
        license,
      );
      if (result == null) {
        return const FaceLivenessResult(
          success: false,
          code: -1,
          message: 'Liveness returned no result.',
          image: '',
          livenessId: '',
        );
      }
      final json = Json(result);
      return FaceLivenessResult(
        success: json['success'].stringValue.trim().toLowerCase() == 'true',
        code: json['code'].numValue.toInt(),
        message: json['message'].stringValue.trim(),
        image: json['image'].stringValue.trim(),
        livenessId: json['liveness_id'].stringValue.trim(),
      );
    } on PlatformException catch (error) {
      return FaceLivenessResult(
        success: false,
        code: -1,
        message: error.message ?? 'Unable to start liveness verification.',
        image: '',
        livenessId: '',
      );
    } on MissingPluginException {
      return const FaceLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is unavailable.',
        image: '',
        livenessId: '',
      );
    }
  }
}
