class AppConfig {
  const AppConfig._();

  static const appName = 'SoloEcho';
  static const folderName = 'SoloEcho';
  static const spreadsheetName = 'SoloEcho Timeline';
  static const logSheetName = 'Log';

  static const desktopClientId = String.fromEnvironment(
    'SOLOECHO_DESKTOP_CLIENT_ID',
  );
  static const desktopClientSecret = String.fromEnvironment(
    'SOLOECHO_DESKTOP_CLIENT_SECRET',
  );

  static const authScopes = <String>[
    'openid',
    'email',
    'profile',
  ];

  static const apiScopes = <String>[
    'https://www.googleapis.com/auth/drive.file',
  ];

  static const desktopOAuthScopes = <String>[
    ...authScopes,
    ...apiScopes,
  ];

  static String get requiredDesktopClientId {
    final value = desktopClientId.trim();
    if (value.isEmpty) {
      throw const AppConfigurationException(
        'SOLOECHO_DESKTOP_CLIENT_ID is required for desktop OAuth.',
      );
    }
    return value;
  }

  static String? get desktopClientSecretOrNull {
    final value = desktopClientSecret.trim();
    return value.isEmpty ? null : value;
  }
}

class AppConfigurationException implements Exception {
  const AppConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}
