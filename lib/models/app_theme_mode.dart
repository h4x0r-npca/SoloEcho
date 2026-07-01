enum AppThemeMode {
  dark,
  light;

  String get label {
    return switch (this) {
      AppThemeMode.dark => '다크',
      AppThemeMode.light => '라이트',
    };
  }

  String get storageValue {
    return switch (this) {
      AppThemeMode.dark => 'dark',
      AppThemeMode.light => 'light',
    };
  }

  static AppThemeMode fromStorage(String? value) {
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.dark,
    };
  }
}
