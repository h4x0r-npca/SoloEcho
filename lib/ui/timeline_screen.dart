import 'package:flutter/material.dart';

import '../models/solo_echo_account.dart';
import '../models/timeline_entry.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({
    super.key,
    required this.account,
    required this.entries,
    required this.isLoading,
    required this.onRefresh,
  });

  final SoloEchoAccount account;
  final List<TimelineEntry> entries;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        reverse: entries.isNotEmpty,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          if (entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('아직 기록이 없습니다')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _TimelineBubble(
                    account: account,
                    entry: entries[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineBubble extends StatelessWidget {
  const _TimelineBubble({
    required this.account,
    required this.entry,
  });

  final SoloEchoAccount account;
  final TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ProfileAvatar(account: account),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: SelectableText(
                      entry.content,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.formattedTimestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.account});

  final SoloEchoAccount account;

  @override
  Widget build(BuildContext context) {
    final photoUrl = account.photoUrl;
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundImage: NetworkImage(photoUrl),
        onForegroundImageError: (_, __) {},
        child: Text(account.initials),
      );
    }
    return CircleAvatar(
      radius: 22,
      child: Text(account.initials),
    );
  }
}
