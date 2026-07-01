import 'package:flutter/material.dart';

import '../models/solo_echo_account.dart';
import '../models/timeline_entry.dart';
import 'app_theme.dart';
import 'profile_avatar.dart';
import 'search_highlight.dart';

class ThreadTimelineScreen extends StatelessWidget {
  const ThreadTimelineScreen({
    super.key,
    required this.account,
    required this.entries,
    required this.isLoading,
    required this.onRefresh,
    this.searchQuery,
    this.emptyMessage,
  });

  final SoloEchoAccount account;
  final List<TimelineEntry> entries;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String? searchQuery;
  final String? emptyMessage;

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
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(emptyMessage ?? '아직 기록이 없습니다')),
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
                    searchQuery: searchQuery ?? '',
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
    required this.searchQuery,
  });

  final SoloEchoAccount account;
  final TimelineEntry entry;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.threadCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.cardBorder),
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
                        color: colors.textSecondary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SearchHighlightedText(
                      text: entry.content,
                      query: searchQuery,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        height: 1.45,
                      ),
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
