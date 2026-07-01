import '../models/app_theme_mode.dart';
import '../models/font_scale_step.dart';
import '../models/writing_mode.dart';
import 'key_value_store.dart';

class UserSettingsService {
  UserSettingsService({
    KeyValueStore? storage,
  }) : _storage = storage ?? JsonFileKeyValueStore.defaultStore();

  static const _writingModeKey = 'writing_mode';
  static const _themeModeKey = 'theme_mode';
  static const _fontScaleStepKey = 'font_scale_step';

  final KeyValueStore _storage;

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
}
