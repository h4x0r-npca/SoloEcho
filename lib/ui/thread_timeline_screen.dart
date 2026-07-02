import 'dart:async';

import 'package:flutter/material.dart';

import '../models/solo_echo_account.dart';
import '../models/timeline_entry.dart';
import 'app_theme.dart';
import 'profile_avatar.dart';
import 'search_highlight.dart';

class ThreadTimelineScreen extends StatefulWidget {
  const ThreadTimelineScreen({
    super.key,
    required this.account,
    required this.entries,
    required this.isLoading,
    required this.onRefresh,
    this.searchQuery,
    this.emptyMessage,
    this.revealingTimestamp,
  });

  final SoloEchoAccount account;
  final List<TimelineEntry> entries;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String? searchQuery;
  final String? emptyMessage;
  final DateTime? revealingTimestamp;

  @override
  State<ThreadTimelineScreen> createState() => _ThreadTimelineScreenState();
}

class _ThreadTimelineScreenState extends State<ThreadTimelineScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _firstEntryKey = GlobalKey();
  DateTime? _lastAnimatedTimestamp;

  bool get _hasSearch => widget.searchQuery?.trim().isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _scheduleNewEntryScrollIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ThreadTimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revealingTimestamp != widget.revealingTimestamp ||
        oldWidget.entries != widget.entries ||
        oldWidget.searchQuery != widget.searchQuery) {
      _scheduleNewEntryScrollIfNeeded();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          if (widget.entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(widget.emptyMessage ?? '아직 기록이 없습니다')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              sliver: SliverList.builder(
                itemCount: widget.entries.length,
                itemBuilder: (context, index) {
                  final card = _ThreadEntryCard(
                    account: widget.account,
                    entry: widget.entries[index],
                    searchQuery: widget.searchQuery ?? '',
                  );
                  if (index == 0) {
                    return KeyedSubtree(
                      key: _firstEntryKey,
                      child: card,
                    );
                  }
                  return card;
                },
              ),
            ),
        ],
      ),
    );
  }

  void _scheduleNewEntryScrollIfNeeded() {
    final timestamp = widget.revealingTimestamp;
    if (timestamp == null ||
        _hasSearch ||
        widget.entries.isEmpty ||
        widget.entries.first.timestamp != timestamp ||
        _lastAnimatedTimestamp == timestamp) {
      return;
    }
    _lastAnimatedTimestamp = timestamp;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final firstEntryRender =
          _firstEntryKey.currentContext?.findRenderObject() as RenderBox?;
      if (firstEntryRender == null || !firstEntryRender.hasSize) {
        return;
      }
      final position = _scrollController.position;
      final revealOffset = (firstEntryRender.size.height + 12)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if (revealOffset <= position.minScrollExtent) {
        return;
      }
      position.jumpTo(revealOffset);
      unawaited(
        position.animateTo(
          position.minScrollExtent,
          duration: const Duration(milliseconds: 430),
          curve: Curves.easeOutCubic,
        ),
      );
    });
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
