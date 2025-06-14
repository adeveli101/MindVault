import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateLimiter {
  final SharedPreferences _prefs;
  static const String _attemptsKey = 'pin_attempts';
  static const String _lastAttemptTimeKey = 'last_attempt_time';
  static const String _lockoutEndTimeKey = 'lockout_end_time';
  
  // Sabitler
  static const int maxAttempts = 5; // Maksimum deneme sayısı
  static const int lockoutDurationMinutes = 15; // Kilitleme süresi (dakika)
  static const int attemptWindowMinutes = 5; // Deneme penceresi (dakika)

  RateLimiter(this._prefs);

  /// PIN denemesi yapıldığında çağrılır
  Future<bool> recordAttempt() async {
    final now = DateTime.now();
    final lastAttemptTime = _getLastAttemptTime();
    final attempts = _getAttempts();

    // Kilitleme süresi kontrolü
    if (_isLocked()) {
      if (kDebugMode) {
        print('RateLimiter: Account is locked. Try again later.');
      }
      return false;
    }

    // Deneme penceresi kontrolü
    if (lastAttemptTime != null) {
      final timeSinceLastAttempt = now.difference(lastAttemptTime);
      if (timeSinceLastAttempt.inMinutes > attemptWindowMinutes) {
        // Deneme penceresi geçmişse sayacı sıfırla
        await _resetAttempts();
      }
    }

    // Deneme sayısını artır
    final newAttempts = attempts + 1;
    await _prefs.setInt(_attemptsKey, newAttempts);
    await _prefs.setString(_lastAttemptTimeKey, now.toIso8601String());

    // Maksimum deneme sayısına ulaşıldıysa kilitle
    if (newAttempts >= maxAttempts) {
      await _lockAccount();
      if (kDebugMode) {
        print('RateLimiter: Maximum attempts reached. Account locked.');
      }
      return false;
    }

    return true;
  }

  /// Kalan deneme hakkını kontrol eder
  Future<bool> canAttempt() async {
    if (_isLocked()) {
      return false;
    }

    final attempts = _getAttempts();
    return attempts < maxAttempts;
  }

  /// Kalan deneme hakkını döndürür
  int getRemainingAttempts() {
    return maxAttempts - _getAttempts();
  }

  /// Hesabın kilitli olup olmadığını kontrol eder
  bool _isLocked() {
    final lockoutEndTime = _prefs.getString(_lockoutEndTimeKey);
    if (lockoutEndTime == null) return false;

    final endTime = DateTime.parse(lockoutEndTime);
    return DateTime.now().isBefore(endTime);
  }

  /// Kalan kilitleme süresini döndürür (dakika)
  int getRemainingLockoutTime() {
    if (!_isLocked()) return 0;

    final lockoutEndTime = _prefs.getString(_lockoutEndTimeKey);
    if (lockoutEndTime == null) return 0;

    final endTime = DateTime.parse(lockoutEndTime);
    final remaining = endTime.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Hesabı kilitler
  Future<void> _lockAccount() async {
    final lockoutEndTime = DateTime.now().add(Duration(minutes: lockoutDurationMinutes));
    await _prefs.setString(_lockoutEndTimeKey, lockoutEndTime.toIso8601String());
  }

  /// Deneme sayısını sıfırlar
  Future<void> _resetAttempts() async {
    await _prefs.setInt(_attemptsKey, 0);
    await _prefs.remove(_lockoutEndTimeKey);
  }

  /// Son deneme zamanını alır
  DateTime? _getLastAttemptTime() {
    final timeStr = _prefs.getString(_lastAttemptTimeKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  /// Deneme sayısını alır
  int _getAttempts() {
    return _prefs.getInt(_attemptsKey) ?? 0;
  }

  /// Başarılı giriş sonrası deneme sayısını sıfırlar
  Future<void> resetOnSuccess() async {
    await _resetAttempts();
  }
} 