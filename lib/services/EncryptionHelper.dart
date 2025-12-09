import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class EncryptionHelper {
  //! secret key that is used to encrypt the passwords
  static final _key = Key.fromUtf8('my32lengthsupersecretnooneknows1');

//! function that encrypts the password and store the encrypted password with the iv key separated by :
  static String encrypt(String plaintext) {
    final encrypter = Encrypter(AES(_key));
    final iv = IV.fromLength(16);

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    String ivBase64 = base64.encode(iv.bytes);
    String encryptedBase64 = encrypted.base64;
    return '$ivBase64:$encryptedBase64';
  }
//!//! function that decrypts the password by getting the iv key and decrypting it using the _key 
  static String decrypt(String combinedEncryptedData) {
    final encrypter = Encrypter(AES(_key));
    List<String> parts = combinedEncryptedData.split(':');
    if (parts.length != 2) {
      throw Exception("Invalid encrypted data format.");
    }
    final iv = IV.fromBase64(parts[0]);
    final encryptedText = parts[1];
    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
    return decrypted;
  }
}
