import 'package:flutter/material.dart';

import '../models/solo_echo_account.dart';
import '../models/timeline_entry.dart';
import 'profile_avatar.dart';

class ThreadTimelineScreen extends StatelessWidget {
  const ThreadTimelineScreen({
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
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          if (entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('아직 기록이 없습니다')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _ThreadEntryCard(
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

class _ThreadEntryCard extends StatelessWidget {
  const _ThreadEntryCard({
    required this.account,
    required this.entry,
  });

  final SoloEchoAccount account;
  final TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ProfileAvatar(account: account),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.formattedTimestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      entry.content,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
