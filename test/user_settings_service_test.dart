import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/models/app_theme_mode.dart';
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
