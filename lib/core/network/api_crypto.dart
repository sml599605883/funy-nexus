import 'dart:convert';

import 'package:encrypt/encrypt.dart';

class ApiCrypto {
  ApiCrypto({required String key, required String iv})
    : _encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc)),
      _iv = IV.fromUtf8(iv);

  final Encrypter _encrypter;
  final IV _iv;

  String encryptText(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  String encryptJson(Object? value) {
    return encryptText(jsonEncode(value));
  }

  String decryptText(String cipherText) {
    return _encrypter.decrypt64(cipherText, iv: _iv);
  }
}
