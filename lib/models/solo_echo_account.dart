class SoloEchoAccount {
  const SoloEchoAccount({
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String email;
  final String? displayName;
  final String? photoUrl;

  String get initials {
    final name = (displayName == null || displayName!.trim().isEmpty)
        ? email
        : displayName!.trim();
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Map<String, String> toStorage() {
    return <String, String>{
      'email': email,
      if (displayName != null) 'displayName': displayName!,
      if (photoUrl != null) 'photoUrl': photoUrl!,
    };
  }

  static SoloEchoAccount? fromStorage(Map<String, String> values) {
    final email = values['email'];
    if (email == null || email.trim().isEmpty) {
      return null;
    }
    return SoloEchoAccount(
      email: email,
      displayName: values['displayName'],
      photoUrl: values['photoUrl'],
    );
  }
}
