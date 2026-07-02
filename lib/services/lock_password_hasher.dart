import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class LockPasswordHasher {
  const LockPasswordHasher({
    this.saltLength = 16,
    this.hashLength = 32,
  });

  final int saltLength;
  final int hashLength;

  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(saltLength, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String hashPassword({
    required String password,
    required String salt,
    required int iterations,
  }) {
    final saltBytes = base64Decode(salt);
    final passwordBytes = utf8.encode(password);
    final derived = _pbkdf2(
      passwordBytes: passwordBytes,
      saltBytes: saltBytes,
      iterations: iterations,
      length: hashLength,
    );
    return base64Encode(derived);
  }

  bool verifyPassword({
    required String password,
    required String salt,
    required String expectedHash,
    required int iterations,
  }) {
    final actualHash = hashPassword(
      password: password,
      salt: salt,
      iterations: iterations,
    );
    return _constantTimeEquals(
      base64Decode(actualHash),
      base64Decode(expectedHash),
    );
  }

  Uint8List _pbkdf2({
    required List<int> passwordBytes,
    required List<int> saltBytes,
    required int iterations,
    required int length,
  }) {
    if (iterations <= 0 || length <= 0) {
      throw ArgumentError('PBKDF2 iterations and length must be positive.');
    }

    final hmac = Hmac(sha256, passwordBytes);
    const digestLength = 32;
    final blockCount = (length / digestLength).ceil();
    final output = BytesBuilder(copy: false);

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex += 1) {
      final block = BytesBuilder(copy: false)
        ..add(saltBytes)
        ..add(_int32BigEndian(blockIndex));
      var u = hmac.convert(block.takeBytes()).bytes;
      final t = Uint8List.fromList(u);

      for (var round = 1; round < iterations; round += 1) {
        u = hmac.convert(u).bytes;
        for (var byteIndex = 0; byteIndex < t.length; byteIndex += 1) {
          t[byteIndex] ^= u[byteIndex];
        }
      }
      output.add(t);
    }

    return Uint8List.fromList(output.takeBytes().take(length).toList());
  }

  List<int> _int32BigEndian(int value) {
    return <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var index = 0; index < a.length; index += 1) {
      diff |= a[index] ^ b[index];
    }
    return diff == 0;
  }
}
