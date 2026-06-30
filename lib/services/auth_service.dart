import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../models/solo_echo_account.dart';
import 'key_value_store.dart';

class AuthService {
  AuthService({
    KeyValueStore? storage,
  }) : _storage = storage ?? JsonFileKeyValueStore.defaultStore();

  static final Uri _authorizationEndpoint = Uri.parse(
    'https://accounts.google.com/o/oauth2/v2/auth',
  );
  static final Uri _tokenEndpoint = Uri.parse(
    'https://oauth2.googleapis.com/token',
  );
  static final Uri _userInfoEndpoint = Uri.parse(
    'https://openidconnect.googleapis.com/v1/userinfo',
  );

  static const _desktopCredentialsKey = 'desktop_oauth_credentials';
  static const _accountEmailKey = 'account_email';
  static const _accountNameKey = 'account_name';
  static const _accountPhotoKey = 'account_photo';

  final KeyValueStore _storage;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: AppConfig.apiScopes,
  );

  http.Client? _authorizedClient;
  SoloEchoAccount? _account;

  SoloEchoAccount? get account => _account;

  http.Client get authorizedClient {
    final client = _authorizedClient;
    if (client == null) {
      throw StateError('Google account is not signed in.');
    }
    return client;
  }

  static bool isRecoverableAuthError(Object error) {
    if (error is AuthExpiredException ||
        error is oauth2.AuthorizationException ||
        error is oauth2.ExpirationException) {
      return true;
    }

    final text = error.toString().toLowerCase();
    return text.contains('invalid_token') ||
        text.contains('access was denied') &&
            text.contains('www-authenticate') ||
        text.contains('oauth2 credentials have expired') ||
        text.contains('google api authorization is required') ||
        text.contains('401') && text.contains('unauthorized');
  }

  Future<SoloEchoAccount?> restoreSession() async {
    if (kIsWeb) {
      return null;
    }
    if (_isDesktopOAuthPlatform) {
      return _restoreDesktopSession();
    }
    if (Platform.isAndroid) {
      return _restoreAndroidSession();
    }
    return null;
  }

  Future<SoloEchoAccount> signIn() async {
    if (kIsWeb) {
      throw UnsupportedError('SoloEcho targets Android, Windows, and macOS.');
    }
    if (_isDesktopOAuthPlatform) {
      return _signInWithDesktopOAuth();
    }
    if (Platform.isAndroid) {
      return _signInWithGoogleSignIn();
    }
    throw UnsupportedError('SoloEcho targets Android, Windows, and macOS.');
  }

  Future<void> signOut() async {
    _authorizedClient?.close();
    _authorizedClient = null;
    _account = null;
    await _storage.delete(key: _desktopCredentialsKey);
    await _storage.delete(key: _accountEmailKey);
    await _storage.delete(key: _accountNameKey);
    await _storage.delete(key: _accountPhotoKey);
    if (!kIsWeb && Platform.isAndroid) {
      await _googleSignIn.signOut();
    }
  }

  Future<bool> refreshAuthorization() async {
    if (kIsWeb) {
      return false;
    }
    if (_isDesktopOAuthPlatform) {
      return _refreshDesktopAuthorization();
    }
    if (Platform.isAndroid) {
      return _refreshAndroidAuthorization();
    }
    return false;
  }

  void dispose() {
    _authorizedClient?.close();
  }

  Future<SoloEchoAccount?> _restoreAndroidSession() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) {
      _account = await _readStoredAccount();
      return null;
    }
    return _finishAndroidSignIn(account);
  }

  Future<SoloEchoAccount> _signInWithGoogleSignIn() async {
    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } on PlatformException catch (error) {
      if (_isAndroidDeveloperConfigurationError(error)) {
        throw const AppConfigurationException(
          'Android Google 로그인 설정이 맞지 않습니다. Google Cloud에서 Android OAuth client를 만들어 주세요. Package name: com.soloecho.app / SHA-1: 86:E4:02:A7:AF:49:98:7D:16:D1:3B:A5:07:EC:E9:D9:AC:19:9F:6F',
        );
      }
      rethrow;
    }
    if (account == null) {
      throw const AuthCancelledException();
    }
    return _finishAndroidSignIn(account);
  }

  Future<SoloEchoAccount> _finishAndroidSignIn(
    GoogleSignInAccount googleAccount,
  ) async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw StateError('Google API authorization is required.');
    }
    _authorizedClient = client;
    final account = SoloEchoAccount(
      email: googleAccount.email,
      displayName: googleAccount.displayName,
      photoUrl: googleAccount.photoUrl,
    );
    await _storeAccount(account);
    _account = account;
    return account;
  }

  Future<SoloEchoAccount?> _restoreDesktopSession() async {
    final json = await _storage.read(key: _desktopCredentialsKey);
    if (json == null || json.trim().isEmpty) {
      return null;
    }
    try {
      final credentials = oauth2.Credentials.fromJson(json);
      final client = oauth2.Client(
        credentials,
        identifier: AppConfig.requiredDesktopClientId,
        secret: AppConfig.desktopClientSecretOrNull,
        basicAuth: false,
        onCredentialsRefreshed: (credentials) {
          unawaited(_storeDesktopCredentials(credentials));
        },
      );
      _authorizedClient = client;
      _account = await _readStoredAccount() ?? await _fetchUserInfo(client);
      if (_account != null) {
        await _storeAccount(_account!);
      }
      return _account;
    } catch (_) {
      await _storage.delete(key: _desktopCredentialsKey);
      _authorizedClient = null;
      return null;
    }
  }

  Future<SoloEchoAccount> _signInWithDesktopOAuth() async {
    final clientId = AppConfig.requiredDesktopClientId;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = Uri.parse(
      'http://127.0.0.1:${server.port}/oauth2redirect',
    );
    final state = _randomString(32);
    final grant = oauth2.AuthorizationCodeGrant(
      clientId,
      _authorizationEndpoint,
      _tokenEndpoint,
      secret: AppConfig.desktopClientSecretOrNull,
      basicAuth: false,
      codeVerifier: _randomString(64),
      onCredentialsRefreshed: (credentials) {
        unawaited(_storeDesktopCredentials(credentials));
      },
    );
    var keepAuthorizedClient = false;

    try {
      final baseAuthorizationUri = grant.getAuthorizationUrl(
        redirectUri,
        scopes: AppConfig.desktopOAuthScopes,
        state: state,
      );
      final authorizationUri = baseAuthorizationUri.replace(
        queryParameters: <String, String>{
          ...baseAuthorizationUri.queryParameters,
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );

      final launched = await launchUrl(
        authorizationUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not open the Google sign-in page.');
      }

      final request = await server.first.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          throw TimeoutException('Google sign-in timed out.');
        },
      );
      final responseState = request.uri.queryParameters['state'];
      if (responseState != state) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('Invalid OAuth response.');
        await request.response.close();
        throw StateError('Invalid OAuth response state.');
      }

      if (request.uri.queryParameters.containsKey('error')) {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.html;
        request.response.write(
          '<!doctype html><title>SoloEcho</title>'
          '<body style="font-family:sans-serif;padding:32px">'
          'SoloEcho login was cancelled. You can close this window.'
          '</body>',
        );
        await request.response.close();
        throw const AuthCancelledException();
      }

      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<!doctype html><title>SoloEcho</title>'
        '<body style="font-family:sans-serif;padding:32px">'
        'SoloEcho login complete. You can close this window.'
        '</body>',
      );
      await request.response.close();

      final client = await grant.handleAuthorizationResponse(
        request.uri.queryParameters,
      );
      keepAuthorizedClient = true;
      _authorizedClient = client;
      await _storeDesktopCredentials(client.credentials);

      final account = await _fetchUserInfo(client);
      await _storeAccount(account);
      _account = account;
      return account;
    } finally {
      await server.close(force: true);
      if (!keepAuthorizedClient) {
        grant.close();
      }
    }
  }

  Future<SoloEchoAccount> _fetchUserInfo(http.Client client) async {
    final response = await client.get(_userInfoEndpoint);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Could not read Google profile.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SoloEchoAccount(
      email: data['email']?.toString() ?? '',
      displayName: data['name']?.toString(),
      photoUrl: data['picture']?.toString(),
    );
  }

  Future<void> _storeDesktopCredentials(oauth2.Credentials credentials) async {
    await _storage.write(
      key: _desktopCredentialsKey,
      value: credentials.toJson(),
    );
  }

  Future<bool> _refreshDesktopAuthorization() async {
    final client = _authorizedClient;
    if (client is oauth2.Client) {
      try {
        await client.refreshCredentials();
        await _storeDesktopCredentials(client.credentials);
        return true;
      } on oauth2.AuthorizationException {
        await _clearExpiredAuthorization();
        return false;
      } on oauth2.ExpirationException {
        await _clearExpiredAuthorization();
        return false;
      } on StateError {
        await _clearExpiredAuthorization();
        return false;
      }
    }

    return await _restoreDesktopSession() != null;
  }

  Future<bool> _refreshAndroidAuthorization() async {
    try {
      final account = await _googleSignIn.signInSilently(
        reAuthenticate: true,
      );
      if (account == null) {
        await _clearExpiredAuthorization();
        return false;
      }
      await _finishAndroidSignIn(account);
      return true;
    } on PlatformException catch (error) {
      if (_isAndroidDeveloperConfigurationError(error)) {
        throw const AppConfigurationException(
          'Android Google 로그인 설정이 맞지 않습니다. Google Cloud에서 Android OAuth client를 만들어 주세요. Package name: com.soloecho.app / SHA-1: 86:E4:02:A7:AF:49:98:7D:16:D1:3B:A5:07:EC:E9:D9:AC:19:9F:6F',
        );
      }
      await _clearExpiredAuthorization();
      return false;
    }
  }

  Future<void> _clearExpiredAuthorization() async {
    _authorizedClient?.close();
    _authorizedClient = null;
    _account = null;
    await _storage.delete(key: _desktopCredentialsKey);
    await _storage.delete(key: _accountEmailKey);
    await _storage.delete(key: _accountNameKey);
    await _storage.delete(key: _accountPhotoKey);
  }

  bool get _isDesktopOAuthPlatform => Platform.isWindows || Platform.isMacOS;

  bool _isAndroidDeveloperConfigurationError(PlatformException error) {
    if (error.code != GoogleSignIn.kSignInFailedError) {
      return false;
    }
    final message = error.message ?? error.toString();
    return message.contains('ApiException: 10') ||
        message.contains('Api 10') ||
        message.contains('Api10');
  }

  Future<void> _storeAccount(SoloEchoAccount account) async {
    await _storage.write(key: _accountEmailKey, value: account.email);
    if (account.displayName == null) {
      await _storage.delete(key: _accountNameKey);
    } else {
      await _storage.write(key: _accountNameKey, value: account.displayName);
    }
    if (account.photoUrl == null) {
      await _storage.delete(key: _accountPhotoKey);
    } else {
      await _storage.write(key: _accountPhotoKey, value: account.photoUrl);
    }
  }

  Future<SoloEchoAccount?> _readStoredAccount() async {
    final email = await _storage.read(key: _accountEmailKey);
    final name = await _storage.read(key: _accountNameKey);
    final photo = await _storage.read(key: _accountPhotoKey);
    return SoloEchoAccount.fromStorage(
      <String, String>{
        if (email != null) 'email': email,
        if (name != null) 'displayName': name,
        if (photo != null) 'photoUrl': photo,
      },
    );
  }

  String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'Google sign-in was cancelled.';
}

class AuthExpiredException implements Exception {
  const AuthExpiredException();

  @override
  String toString() => 'Google authorization has expired.';
}
