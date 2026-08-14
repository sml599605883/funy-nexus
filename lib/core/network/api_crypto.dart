import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:fund_nexus/core/network/api_exception.dart';

class ApiCrypto {
  ApiCrypto({required String key, required String iv})
    : _encrypter = key.isEmpty && iv.isEmpty
          ? null
          : Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc)),
      _iv = key.isEmpty && iv.isEmpty ? null : IV.fromUtf8(iv);

  final Encrypter? _encrypter;
  final IV? _iv;

  bool get isConfigured => _encrypter != null && _iv != null;

  String encryptText(String plainText) {
    final encrypter = _requireConfigured();
    return encrypter.encrypt(plainText, iv: _iv!).base64;
  }

  String encryptJson(Object? value) {
    return encryptText(jsonEncode(value));
  }

  String decryptText(String cipherText) {
    final encrypter = _requireConfigured();
    return encrypter.decrypt64(cipherText, iv: _iv!);
  }

  Encrypter _requireConfigured() {
    final encrypter = _encrypter;
    if (encrypter == null || _iv == null) {
      throw const ApiException(
        type: ApiFailureType.configuration,
        message: 'API encryption is not configured',
      );
    }
    return encrypter;
  }
}
