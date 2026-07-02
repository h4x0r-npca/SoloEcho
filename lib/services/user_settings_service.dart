import 'dart:convert';

import '../models/app_theme_mode.dart';
import '../models/font_scale_step.dart';
import '../models/lock_settings.dart';
import '../models/writing_mode.dart';
import 'key_value_store.dart';
import 'lock_password_hasher.dart';

class UserSettingsService {
  UserSettingsService({
    KeyValueStore? storage,
    LockPasswordHasher? lockPasswordHasher,
  })  : _storage = storage ?? JsonFileKeyValueStore.defaultStore(),
        _lockPasswordHasher = lockPasswordHasher ?? const LockPasswordHasher();

  static const _writingModeKey = 'writing_mode';
  static const _themeModeKey = 'theme_mode';
  static const _fontScaleStepKey = 'font_scale_step';
  static const _motionEffectsEnabledKey = 'motion_effects_enabled';
  static const _lockSaltKey = 'lock_salt';
  static const _lockHashKey = 'lock_hash';
  static const _lockIterationsKey = 'lock_iterations';
  static const _lockVersionKey = 'lock_version';
  static const _lockVersion = 'pbkdf2-sha256-v1';
  static const _lockIterations = 120000;

  final KeyValueStore _storage;
  final LockPasswordHasher _lockPasswordHasher;

  Future<WritingMode> readWritingMode() async {
    final value = await _storage.read(key: _writingModeKey);
    return WritingMode.fromStorage(value);
  }

  Future<void> writeWritingMode(WritingMode mode) async {
    await _storage.write(key: _writingModeKey, value: mode.storageValue);
  }

  Future<AppThemeMode> readThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return AppThemeMode.fromStorage(value);
  }

  Future<void> writeThemeMode(AppThemeMode mode) async {
    await _storage.write(key: _themeModeKey, value: mode.storageValue);
  }

  Future<FontScaleStep> readFontScaleStep() async {
    final value = await _storage.read(key: _fontScaleStepKey);
    return FontScaleStep.fromStorage(value);
  }

  Future<void> writeFontScaleStep(FontScaleStep step) async {
    await _storage.write(key: _fontScaleStepKey, value: step.storageValue);
  }

  Future<bool> readMotionEffectsEnabled() async {
    final value = await _storage.read(key: _motionEffectsEnabledKey);
    return switch (value) {
      'false' => false,
      'true' => true,
      _ => true,
    };
  }

  Future<void> writeMotionEffectsEnabled(bool enabled) async {
    await _storage.write(
      key: _motionEffectsEnabledKey,
      value: enabled.toString(),
    );
  }

  Future<LockSettings> readLockSettings() async {
    final salt = await _storage.read(key: _lockSaltKey);
    final hash = await _storage.read(key: _lockHashKey);
    final iterationsText = await _storage.read(key: _lockIterationsKey);
    final version = await _storage.read(key: _lockVersionKey);
    final iterations = int.tryParse(iterationsText ?? '');

    if (salt == null ||
        salt.isEmpty ||
        hash == null ||
        hash.isEmpty ||
        iterations == null ||
        iterations <= 0 ||
        version != _lockVersion) {
      return const LockSettings.disabled();
    }
    try {
      base64Decode(salt);
      base64Decode(hash);
    } on FormatException {
      return const LockSettings.disabled();
    }

    return LockSettings.enabled(
      salt: salt,
      hash: hash,
      iterations: iterations,
      version: version!,
    );
  }

  Future<void> writeLockPassword(String password) async {
    if (password.isEmpty) {
      throw ArgumentError.value(password, 'password', 'Password is empty.');
    }

    final salt = _lockPasswordHasher.generateSalt();
    final hash = _lockPasswordHasher.hashPassword(
      password: password,
      salt: salt,
      iterations: _lockIterations,
    );

    await _storage.write(key: _lockSaltKey, value: salt);
    await _storage.write(key: _lockHashKey, value: hash);
    await _storage.write(
      key: _lockIterationsKey,
      value: _lockIterations.toString(),
    );
    await _storage.write(key: _lockVersionKey, value: _lockVersion);
  }

  Future<bool> verifyLockPassword(String password) async {
    final settings = await readLockSettings();
    if (!settings.isEnabled) {
      return false;
    }
    try {
      return _lockPasswordHasher.verifyPassword(
        password: password,
        salt: settings.salt,
        expectedHash: settings.hash,
        iterations: settings.iterations,
      );
    } on FormatException {
      return false;
    } on ArgumentError {
      return false;
    }
  }

  Future<void> clearLock() async {
    await _storage.delete(key: _lockSaltKey);
    await _storage.delete(key: _lockHashKey);
    await _storage.delete(key: _lockIterationsKey);
    await _storage.delete(key: _lockVersionKey);
  }
}
