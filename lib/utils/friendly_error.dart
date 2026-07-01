import '../services/auth_service.dart';

String friendlyErrorMessage(Object error) {
  if (error is AuthCancelledException) {
    return '로그인이 취소되었습니다';
  }
  if (error is AuthExpiredException ||
      AuthService.isRecoverableAuthError(error)) {
    return '세션이 만료되었습니다. 다시 로그인해 주세요';
  }

  final text = error.toString();
  final lowerText = text.toLowerCase();
  if (text.contains('Google sign-in was cancelled')) {
    return '로그인이 취소되었습니다';
  }
  if (text.contains('Google API authorization is required')) {
    return 'Google Drive 접근 권한이 필요합니다. 다시 로그인해 주세요';
  }
  if (lowerText.contains('certificate_verify_failed') ||
      (lowerText.contains('handshake') &&
          lowerText.contains('application verification failure'))) {
    return '앱 네트워크 인증 확인에 실패했습니다. macOS 테스트 앱이라면 최신 zip을 다시 압축 해제한 뒤 실행해 주세요.';
  }
  if (text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('Network is unreachable')) {
    return '네트워크 연결을 확인해 주세요';
  }
  if (text.contains('timed out')) {
    return '로그인 시간이 초과되었습니다';
  }
  return text
      .replaceFirst('Exception: ', '')
      .replaceFirst('Bad state: ', '')
      .replaceFirst('StateError: ', '');
}
