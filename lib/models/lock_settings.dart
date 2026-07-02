class LockSettings {
  const LockSettings._({
    required this.isEnabled,
    required this.salt,
    required this.hash,
    required this.iterations,
    required this.version,
  });

  const LockSettings.disabled()
      : this._(
          isEnabled: false,
          salt: '',
          hash: '',
          iterations: 0,
          version: '',
        );

  const LockSettings.enabled({
    required String salt,
    required String hash,
    required int iterations,
    required String version,
  }) : this._(
          isEnabled: true,
          salt: salt,
          hash: hash,
          iterations: iterations,
          version: version,
        );

  final bool isEnabled;
  final String salt;
  final String hash;
  final int iterations;
  final String version;
}
