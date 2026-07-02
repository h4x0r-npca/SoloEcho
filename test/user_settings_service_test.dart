import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/models/app_theme_mode.dart';
import 'package:soloecho/models/font_scale_step.dart';
import 'package:soloecho/models/writing_mode.dart';
import 'package:soloecho/services/key_value_store.dart';
import 'package:soloecho/services/user_settings_service.dart';

void main() {
  test('reads chat mode by default', () async {
    final service = UserSettingsService(storage: _FakeKeyValueStore());

    expect(await service.readWritingMode(), WritingMode.chat);
  });

  test('stores and reads writing mode', () async {
    final storage = _FakeKeyValueStore();
    final service = UserSettingsService(storage: storage);

    await service.writeWritingMode(WritingMode.thread);

    expect(await service.readWritingMode(), WritingMode.thread);
    expect(storage.values['writing_mode'], 'thread');
  });

  test('falls back to chat mode for unknown storage values', () async {
    final storage = _FakeKeyValueStore()
      ..values['writing_mode'] = 'unknown-value';
    final service = UserSettingsService(storage: storage);

    expect(await service.readWritingMode(), WritingMode.chat);
  });

  test('reads dark theme by default', () async {
    final service = UserSettingsService(storage: _FakeKeyValueStore());

    expect(await service.readThemeMode(), AppThemeMode.dark);
  });

  test('stores and reads theme mode', () async {
    final storage = _FakeKeyValueStore();
    final service = UserSettingsService(storage: storage);

    await service.writeThemeMode(AppThemeMode.light);

    expect(await service.readThemeMode(), AppThemeMode.light);
    expect(storage.values['theme_mode'], 'light');
  });

  test('falls back to dark theme for unknown storage values', () async {
    final storage = _FakeKeyValueStore()..values['theme_mode'] = 'system';
    final service = UserSettingsService(storage: storage);

    expect(await service.readThemeMode(), AppThemeMode.dark);
  });

  test('reads default font scale by default', () async {
    final service = UserSettingsService(storage: _FakeKeyValueStore());

    expect(await service.readFontScaleStep(), FontScaleStep.defaultValue);
  });

  test('stores and reads font scale step', () async {
    final storage = _FakeKeyValueStore();
    final service = UserSettingsService(storage: storage);

    await service.writeFontScaleStep(FontScaleStep.large);

    expect(await service.readFontScaleStep(), FontScaleStep.large);
    expect(storage.values['font_scale_step'], '2');
  });

  test('falls back to default font scale for invalid storage values', () async {
    final storage = _FakeKeyValueStore()..values['font_scale_step'] = 'huge';
    final service = UserSettingsService(storage: storage);

    expect(await service.readFontScaleStep(), FontScaleStep.defaultValue);

    storage.values['font_scale_step'] = '99';
    expect(await service.readFontScaleStep(), FontScaleStep.defaultValue);
  });

  test('reads motion effects enabled by default', () async {
    final service = UserSettingsService(storage: _FakeKeyValueStore());

    expect(await service.readMotionEffectsEnabled(), isTrue);
  });

  test('stores and reads motion effects setting', () async {
    final storage = _FakeKeyValueStore();
    final service = UserSettingsService(storage: storage);

    await service.writeMotionEffectsEnabled(false);

    expect(await service.readMotionEffectsEnabled(), isFalse);
    expect(storage.values['motion_effects_enabled'], 'false');
  });

  test('reads disabled lock by default', () async {
    final service = UserSettingsService(storage: _FakeKeyValueStore());

    expect((await service.readLockSettings()).isEnabled, isFalse);
  });

  test('stores and verifies lock password without plaintext storage', () async {
    final storage = _FakeKeyValueStore();
    final service = UserSettingsService(storage: storage);

    await service.writeLockPassword('  pass  ');

    expect((await service.readLockSettings()).isEnabled, isTrue);
    expect(await service.verifyLockPassword('  pass  '), isTrue);
    expect(await service.verifyLockPassword('pass'), isFalse);
    expect(storage.values.containsValue('  pass  '), isFalse);
    expect(storage.values['lock_salt'], isNotEmpty);
    expect(storage.values['lock_hash'], isNotEmpty);
    expect(storage.values['lock_iterations'], isNotEmpty);
    expect(storage.values['lock_version'], 'pbkdf2-sha256-v1');
  });

  test('rejects empty lock password', () async {
    final service = UserSettingsService(storage: _FakeKeyValueStore());

    expect(
      () => service.writeLockPassword(''),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('clears lock settings', () async {
    final storage = _FakeKeyValueStore();
    final service = UserSettingsService(storage: storage);

    await service.writeLockPassword('pass');
    await service.clearLock();

    expect(await service.verifyLockPassword('pass'), isFalse);
    expect((await service.readLockSettings()).isEnabled, isFalse);
    expect(storage.values.containsKey('lock_salt'), isFalse);
    expect(storage.values.containsKey('lock_hash'), isFalse);
  });

  test('falls back to disabled lock for invalid storage values', () async {
    final storage = _FakeKeyValueStore()
      ..values['lock_salt'] = 'salt'
      ..values['lock_hash'] = 'hash'
      ..values['lock_iterations'] = '0'
      ..values['lock_version'] = 'unknown';
    final service = UserSettingsService(storage: storage);

    expect((await service.readLockSettings()).isEnabled, isFalse);
    expect(await service.verifyLockPassword('pass'), isFalse);
  });
}

class _FakeKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read({required String key}) async {
    return values[key];
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      values.remove(key);
      return;
    }
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}
