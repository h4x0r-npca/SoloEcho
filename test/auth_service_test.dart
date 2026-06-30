import 'package:flutter_test/flutter_test.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:soloecho/services/auth_service.dart';

void main() {
  test('recognizes Google invalid token access denial', () {
    expect(
      AuthService.isRecoverableAuthError(
        Exception(
          'Access was denied (www-authenticate header was: Bearer '
          'realm="https://accounts.google.com/", error="invalid_token").',
        ),
      ),
      isTrue,
    );
  });

  test('recognizes OAuth authorization failures as recoverable auth errors',
      () {
    expect(
      AuthService.isRecoverableAuthError(
        oauth2.AuthorizationException('invalid_token', null, null),
      ),
      isTrue,
    );
  });

  test('does not treat sign-in cancellation as token expiry', () {
    expect(
      AuthService.isRecoverableAuthError(const AuthCancelledException()),
      isFalse,
    );
  });
}
