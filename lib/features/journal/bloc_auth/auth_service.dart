// lib/features/journal/services/auth_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // PlatformException için
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:mindvault/features/journal/bloc_auth/rate_limiter.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final RateLimiter _rateLimiter;

  // Secure Storage için anahtarlar
  static const _pinHashKey = 'mindvault_pin_hash_v1';
  static const _pinSaltKey = 'mindvault_pin_salt_v1';
  static const _biometricsEnabledKey = 'mindvault_biometrics_enabled_v1';

  AuthService({required RateLimiter rateLimiter}) : _rateLimiter = rateLimiter;

  // --- PIN/Şifre Yönetimi ---

  String _generateSalt([int length = 16]) {
    final random = Random.secure();
    // Güvenli rastgele byte listesi oluştur
    final saltBytes = List<int>.generate(length, (_) => random.nextInt(256));
    // Base64 string olarak kodla (saklamak ve okumak için uygun)
    return base64Encode(saltBytes);
  }

  String _hashPin(String pin, String salt) {
    // PIN ve tuzu birleştir (UTF-8 olarak kodla)
    final keyBytes = utf8.encode(pin + salt);
    // SHA-256 hash'ini hesapla
    final digest = sha256.convert(keyBytes);
    // Hash'lenmiş byte'ları Base64 string olarak kodla
    return base64Encode(digest.bytes);
  }

  Future<void> setPin(String pin) async {
    try {
      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);
      // Tuzu ve hash'i güvenli depolamaya yaz
      await _secureStorage.write(key: _pinSaltKey, value: salt);
      await _secureStorage.write(key: _pinHashKey, value: hash);
      if (kDebugMode) {
        print("AuthService: PIN set successfully.");
      } // Debug
    } catch (e) {
      if (kDebugMode) {
        print("Error setting PIN: $e");
      }
      throw Exception("PIN ayarlanamadı."); // Hata fırlat
    }
  }

  Future<bool> verifyPin(String enteredPin) async {
    try {
      // Rate limiting kontrolü
      if (!await _rateLimiter.canAttempt()) {
        final remainingTime = _rateLimiter.getRemainingLockoutTime();
        throw Exception('Çok fazla başarısız deneme. Lütfen $remainingTime dakika sonra tekrar deneyin.');
      }

      final salt = await _secureStorage.read(key: _pinSaltKey);
      final storedHash = await _secureStorage.read(key: _pinHashKey);

      if (salt == null || storedHash == null) {
        if (kDebugMode) {
          print("AuthService: PIN not set.");
        }
        return false;
      }

      final enteredHash = _hashPin(enteredPin, salt);
      final bool match = enteredHash == storedHash;

      if (match) {
        // Başarılı girişte deneme sayısını sıfırla
        await _rateLimiter.resetOnSuccess();
      } else {
        // Başarısız denemeyi kaydet
        await _rateLimiter.recordAttempt();
      }

      if (kDebugMode) {
        print("AuthService: PIN verification result: $match");
      }
      return match;
    } catch (e) {
      if (kDebugMode) {
        print("Error verifying PIN: $e");
      }
      rethrow; // Hatayı yukarı fırlat
    }
  }

  Future<bool> isPinSet() async {
    try {
      final hash = await _secureStorage.read(key: _pinHashKey);
      final isSet = hash != null;
      if (kDebugMode) {
        print("AuthService: Is PIN set? $isSet");
      } // Debug
      return isSet;
    } catch (e) {
      if (kDebugMode) {
        print("Error checking if PIN is set: $e");
      }
      return false;
    }
  }

  Future<void> removePin() async {
    try {
      await _secureStorage.delete(key: _pinHashKey);
      await _secureStorage.delete(key: _pinSaltKey);
      // PIN kaldırılınca biyometriği de devre dışı bırak
      await setBiometricsEnabled(false);
      if (kDebugMode) {
        print("AuthService: PIN removed.");
      } // Debug
    } catch (e) {
      if (kDebugMode) {
        print("Error removing PIN: $e");
      }
      throw Exception("PIN kaldırılamadı.");
    }
  }

  // --- Biyometrik Yönetimi ---

  Future<bool> canCheckBiometrics() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      if (kDebugMode) {
        print("AuthService: Can check biometrics? $canCheck");
      } // Debug
      return canCheck;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Error checking biometrics availability (PlatformException): ${e.code} - ${e.message}");
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print("Error checking biometrics availability: $e");
      }
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> available = await _localAuth.getAvailableBiometrics();
      if (kDebugMode) {
        print("AuthService: Available biometrics: $available");
      } // Debug
      return available;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Error getting available biometrics (PlatformException): ${e.code} - ${e.message}");
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print("Error getting available biometrics: $e");
      }
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics(String localizedReason) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Sistem UI'ı açık kalsın
          biometricOnly: true, // Sadece biyometrik, cihaz şifresi değil
        ),
      );
      if (kDebugMode) {
        print("AuthService: Biometric authentication result: $didAuthenticate");
      } // Debug
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Error during biometric authentication (PlatformException): ${e.code} - ${e.message}");
      }
      // Kullanıcı iptal ettiyse veya kilit ekranı yoksa gibi bilinen hataları ayıklayabilirsin
      // if (e.code == auth_error.notAvailable || e.code == auth_error.notEnrolled || e.code == auth_error.lockedOut) { ... }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print("Error during biometric authentication: $e");
      }
      return false;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    // Önce PIN ayarlı mı diye KESİN kontrol et
    if (enabled && !(await isPinSet())) {
      if (kDebugMode) {
        print("AuthService: Cannot enable biometrics without a PIN set.");
      }
      // Hata fırlatmak yerine sessizce başarısız olabilir veya uyarı verebilirsin.
      // Şimdilik sadece kaydetme işlemini atlıyoruz.
      return;
    }
    try {
      await _secureStorage.write(key: _biometricsEnabledKey, value: enabled.toString());
      if (kDebugMode) {
        print("AuthService: Biometrics enabled set to $enabled.");
      } // Debug
    } catch (e) {
      if (kDebugMode) {
        print("Error setting biometrics enabled flag: $e");
      }
      throw Exception("Biyometrik ayarı kaydedilemedi.");
    }
  }

  Future<bool> isBiometricsEnabled() async {
    // PIN ayarlı değilse otomatik olarak false
    if (!(await isPinSet())) {
      if (kDebugMode) {
        print("AuthService: Biometrics check - PIN not set, returning false.");
      } // Debug
      return false;
    }
    try {
      final enabled = await _secureStorage.read(key: _biometricsEnabledKey);
      if (kDebugMode) {
        print("AuthService: Biometrics enabled flag read as: $enabled");
      } // Debug
      return enabled == 'true';
    } catch (e) {
      if (kDebugMode) {
        print("Error reading biometrics enabled flag: $e");
      }
      return false;
    }
  }
}