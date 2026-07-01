import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/utils/friendly_error.dart';

void main() {
  test('explains macOS app verification TLS failures in Korean', () {
    expect(
      friendlyErrorMessage(
        Exception(
          'HandshakeException: Handshake error in client '
          '(OS Error: CERTIFICATE_VERIFY_FAILED: application '
          'verification failure(handshake.cc:298))',
        ),
      ),
      '앱 네트워크 인증 확인에 실패했습니다. macOS 테스트 앱이라면 최신 zip을 다시 압축 해제한 뒤 실행해 주세요.',
    );
  });

  test('keeps existing network guidance', () {
    expect(
      friendlyErrorMessage(
          Exception('SocketException: Network is unreachable')),
      '네트워크 연결을 확인해 주세요',
    );
  });
}
