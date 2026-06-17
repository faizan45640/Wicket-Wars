import 'package:encrypt/encrypt.dart';

/// AES-256 encryption helpers for passwords before they are handed to Firebase Auth.
///
/// **Course requirement:** demonstrate symmetric encrypt + decrypt in the app.
///
/// 
final class PasswordCrypto {
  PasswordCrypto._();

  /// 32-byte secret for AES-256 (lab / demo only — rotate via secure config in production).
  static final Key _key = Key.fromUtf8('wicket_wars_aes256_key_32chars!!');

  /// Encrypt [plainPassword]; returns `ivBase64:cipherBase64` (IV unique per call).
  static String encryptPassword(String plainPassword) {
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key));
    final encrypted = encrypter.encrypt(plainPassword, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Inverse of [encryptPassword].
  static String decryptPassword(String packed) {
    final idx = packed.indexOf(':');
    if (idx <= 0 || idx >= packed.length - 1) {
      throw const FormatException('Invalid encrypted password payload');
    }
    final iv = IV.fromBase64(packed.substring(0, idx));
    final cipher = Encrypted.fromBase64(packed.substring(idx + 1));
    final encrypter = Encrypter(AES(_key));
    return encrypter.decrypt(cipher, iv: iv);
  }
}
