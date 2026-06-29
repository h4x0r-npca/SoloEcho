import 'package:flutter/material.dart';

import '../models/solo_echo_account.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.account,
    this.radius = 22,
  });

  final SoloEchoAccount account;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoUrl = account.photoUrl;
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundImage: NetworkImage(photoUrl),
        onForegroundImageError: (_, __) {},
        child: Text(account.initials),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Text(account.initials),
    );
  }
}
