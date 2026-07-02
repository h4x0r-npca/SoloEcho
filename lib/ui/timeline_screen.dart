import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/solo_echo_account.dart';
import '../models/timeline_entry.dart';
import 'app_theme.dart';
import 'profile_avatar.dart';
import 'search_highlight.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.account,
    required this.entries,
    required this.isLoading,
    required this.onRefresh,
    this.searchQuery,
    this.currentSearchEntryIndex,
    this.revealingTimestamp,
  });

  final SoloEchoAccount account;
  final List<TimelineEntry> entries;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String? searchQuery;
  final int? currentSearchEntryIndex;
  final DateTime? revealingTimestamp;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _entryKeys = <int, GlobalKey>{};
  final Map<int, GlobalKey> _entryTextKeys = <int, GlobalKey>{};
  int _scrollRequestId = 0;

  bool get _hasCurrentSearchResult {
    final index = widget.currentSearchEntryIndex;
    return index != null &&
        index >= 0 &&
        index < widget.entries.length &&
        (widget.searchQuery?.trim().isNotEmpty ?? false);
  }

  @override
  void initState() {
    super.initState();
    _scheduleEnsureCurrentResultVisible();
  }

  @override
  void didUpdateWidget(covariant TimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextLength = widget.entries.length;
    _entryKeys.removeWhere((index, key) => index >= nextLength);
    _entryTextKeys.removeWhere((index, key) => index >= nextLength);
    if (oldWidget.currentSearchEntryIndex != widget.currentSearchEntryIndex ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.entries != widget.entries) {
      _scheduleEnsureCurrentResultVisible();
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
        reverse: widget.entries.isNotEmpty,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          if (widget.entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('아직 기록이 없습니다')),
            )
          else if (_hasCurrentSearchResult)
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  List<Widget>.generate(
                    widget.entries.length,
                    _buildEntry,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList.builder(
                itemCount: widget.entries.length,
                itemBuilder: (context, index) {
                  return _buildEntry(index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntry(int index) {
    final isCurrentSearchResult = widget.currentSearchEntryIndex == index;
    final bubble = _TimelineBubble(
      key: _keyForIndex(index),
      textKey: isCurrentSearchResult ? _textKeyForIndex(index) : null,
      account: widget.account,
      entry: widget.entries[index],
      searchQuery: widget.searchQuery ?? '',
      isCurrentSearchResult: isCurrentSearchResult,
    );
    if (widget.revealingTimestamp == widget.entries[index].timestamp) {
      return _EntryReveal(child: bubble);
    }
    return bubble;
  }

  GlobalKey _keyForIndex(int index) {
    return _entryKeys.putIfAbsent(index, GlobalKey.new);
  }

  GlobalKey _textKeyForIndex(int index) {
    return _entryTextKeys.putIfAbsent(index, GlobalKey.new);
  }

  void _scheduleEnsureCurrentResultVisible() {
    if (!_hasCurrentSearchResult) {
      return;
    }
    final requestId = ++_scrollRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestId != _scrollRequestId) {
        return;
      }
      _ensureCurrentResultVisible(requestId);
    });
  }

  void _ensureCurrentResultVisible(
    int requestId, {
    int remainingEstimatedJumps = 8,
  }) {
    final index = widget.currentSearchEntryIndex;
    if (index == null) {
      return;
    }
    if (_ensureCurrentMatchTextVisible(index)) {
      return;
    }
    final context = _entryKeys[index]?.currentContext;
    if (context == null) {
      _scrollNearCurrentSearchResult(
        index,
        requestId,
        remainingEstimatedJumps,
      );
      return;
    }
    unawaited(
      Scrollable.ensureVisible(
        context,
        alignment: 0.08,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      ).then((_) {
        if (!mounted || requestId != _scrollRequestId) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && requestId == _scrollRequestId) {
            _ensureCurrentMatchTextVisible(index);
          }
        });
      }),
    );
  }

  bool _ensureCurrentMatchTextVisible(int index) {
    final textContext = _entryTextKeys[index]?.currentContext;
    final query = widget.searchQuery?.trim() ?? '';
    if (textContext == null || query.isEmpty) {
      return false;
    }
    final content = widget.entries[index].content;
    final matchStart = content.toLowerCase().indexOf(query.toLowerCase());
    if (matchStart < 0) {
      return false;
    }

    final renderObject = textContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }
    final scrollable = Scrollable.maybeOf(textContext);
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (scrollable == null || viewport == null) {
      return false;
    }

    final colors = SoloEchoColors.of(textContext);
    final style = Theme.of(textContext).textTheme.bodyLarge?.copyWith(
              color: colors.textPrimary,
              height: 1.45,
            ) ??
        DefaultTextStyle.of(textContext).style;
    final textPainter = TextPainter(
      text: TextSpan(text: content, style: style),
      textDirection: Directionality.of(textContext),
      textScaler: MediaQuery.textScalerOf(textContext),
    )..layout(maxWidth: renderObject.size.width);
    final matchEnd = matchStart + query.length;
    final boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: matchStart, extentOffset: matchEnd),
    );
    if (boxes.isEmpty) {
      return false;
    }

    final firstBox = boxes.first;
    final matchRect = Rect.fromLTRB(
      firstBox.left,
      firstBox.top,
      firstBox.right,
      firstBox.bottom,
    ).inflate(24);
    final visibleRect = matchRect.intersect(Offset.zero & renderObject.size);
    final revealedOffset = viewport.getOffsetToReveal(
      renderObject,
      0.36,
      rect: visibleRect.isEmpty ? matchRect : visibleRect,
    );
    final position = scrollable.position;
    final targetOffset = revealedOffset.offset
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    unawaited(
      position.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
    return true;
  }

  bool _scrollNearCurrentSearchResult(
    int index,
    int requestId,
    int remainingEstimatedJumps,
  ) {
    if (!_scrollController.hasClients || remainingEstimatedJumps <= 0) {
      return false;
    }
    final position = _scrollController.position;
    final targetOffset = _estimatedScrollOffsetForEntry(index)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    position.jumpTo(targetOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && requestId == _scrollRequestId) {
        _ensureCurrentResultVisible(
          requestId,
          remainingEstimatedJumps: remainingEstimatedJumps - 1,
        );
      }
    });
    return true;
  }

  double _estimatedScrollOffsetForEntry(int index) {
    final viewportWidth =
        context.size?.width ?? MediaQuery.of(context).size.width;
    final textWidth = math.max(32.0, viewportWidth - 116);
    var offset = 8.0;
    for (var entryIndex = 0; entryIndex < index; entryIndex += 1) {
      offset += _estimatedEntryExtent(widget.entries[entryIndex], textWidth);
    }
    return offset;
  }

  double _estimatedEntryExtent(TimelineEntry entry, double textWidth) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
          color: colors.textPrimary,
          height: 1.45,
        ) ??
        DefaultTextStyle.of(context).style;
    final timestampStyle = theme.textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ) ??
        DefaultTextStyle.of(context).style;
    final textScaler = MediaQuery.textScalerOf(context);
    final textHeight = _measureTextHeight(
      text: entry.content,
      style: bodyStyle,
      maxWidth: textWidth,
      textScaler: textScaler,
    );
    final timestampHeight = _measureTextHeight(
      text: entry.formattedTimestamp,
      style: timestampStyle,
      maxWidth: textWidth,
      textScaler: textScaler,
    );
    final bubbleHeight = textHeight + 22;
    final columnHeight = bubbleHeight + 6 + timestampHeight;
    return math.max(44, columnHeight) + 14;
  }

  double _measureTextHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextScaler textScaler,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);
    return textPainter.height;
  }
}

class _EntryReveal extends StatelessWidget {
  const _EntryReveal({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: (0.55 + value * 0.45).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _TimelineBubble extends StatelessWidget {
  const _TimelineBubble({
    super.key,
    required this.textKey,
    required this.account,
    required this.entry,
    required this.searchQuery,
    required this.isCurrentSearchResult,
  });

  final Key? textKey;
  final SoloEchoAccount account;
  final TimelineEntry entry;
  final String searchQuery;
  final bool isCurrentSearchResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProfileAvatar(account: account),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.bubble,
                    border: isCurrentSearchResult
                        ? Border.all(color: colors.point, width: 2)
                        : null,
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
                    child: SearchHighlightedText(
                      key: textKey,
                      text: entry.content,
                      query: searchQuery,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.formattedTimestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
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
