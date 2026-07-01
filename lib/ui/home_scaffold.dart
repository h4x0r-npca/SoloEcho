import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_theme_mode.dart';
import '../models/font_scale_step.dart';
import '../models/solo_echo_account.dart';
import '../models/timeline_entry.dart';
import '../models/workspace_info.dart';
import '../models/writing_mode.dart';
import '../utils/timestamp_formatter.dart';
import 'app_theme.dart';
import 'profile_avatar.dart';
import 'settings_sheet.dart';
import 'thread_timeline_screen.dart';
import 'timeline_screen.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({
    super.key,
    required this.account,
    required this.workspace,
    required this.entries,
    required this.writingMode,
    required this.themeMode,
    required this.fontScaleStep,
    required this.isLoadingTimeline,
    required this.isSaving,
    required this.lastSync,
    required this.onRefresh,
    required this.onSave,
    required this.onWritingModeChanged,
    required this.onThemeModeChanged,
    required this.onFontScaleStepChanged,
    required this.onSignOut,
  });

  final SoloEchoAccount account;
  final WorkspaceInfo workspace;
  final List<TimelineEntry> entries;
  final WritingMode writingMode;
  final AppThemeMode themeMode;
  final FontScaleStep fontScaleStep;
  final bool isLoadingTimeline;
  final bool isSaving;
  final DateTime? lastSync;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String content, DateTime timestamp) onSave;
  final Future<void> Function(WritingMode mode) onWritingModeChanged;
  final Future<void> Function(AppThemeMode mode) onThemeModeChanged;
  final Future<void> Function(FontScaleStep step) onFontScaleStepChanged;
  final Future<void> Function() onSignOut;

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _inputFocusNode = FocusNode(
    onKeyEvent: _handleInputKeyEvent,
  );

  Timer? _clockTimer;
  bool _isLongMode = false;
  bool _isSending = false;
  bool _isApplyingShiftNewLine = false;
  String _lastInputText = '';
  String _searchQuery = '';
  int _currentSearchOrdinal = 0;
  DateTime _clockTimestamp = DateTime.now();
  late String _clockText = TimestampFormatter.format(_clockTimestamp);

  bool get _canSend =>
      _controller.text.trim().isNotEmpty && !widget.isSaving && !_isSending;
  bool get _hasSearch => _searchQuery.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
    _clockTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) {
        return;
      }
      final now = DateTime.now();
      setState(() {
        _clockTimestamp = now;
        _clockText = TimestampFormatter.format(now);
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _inputFocusNode.dispose();
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(widget.fontScaleStep.scale),
      ),
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              const _OpenSearchIntent(),
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
              const _OpenSearchIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
              onInvoke: (intent) {
                unawaited(_openSearchDialog());
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                title: const _SoloEchoTitle(),
                actions: <Widget>[
                  IconButton(
                    tooltip: '검색',
                    icon: const Icon(Icons.search),
                    onPressed: () => unawaited(_openSearchDialog()),
                  ),
                  IconButton(
                    tooltip: '설정',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _openSettings(context),
                  ),
                ],
              ),
              body: widget.writingMode == WritingMode.thread
                  ? _buildThreadBody()
                  : _buildChatBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    final matchIndices = _searchMatchIndices;
    final matchCount = matchIndices.length;
    final currentOrdinal = _clampedSearchOrdinal(matchCount);
    final currentEntryIndex =
        matchCount == 0 ? null : matchIndices[currentOrdinal];

    return Column(
      children: <Widget>[
        if (_hasSearch)
          _SearchStatusBar(
            query: _searchQuery,
            summary: matchCount == 0
                ? '0 / 0'
                : '${currentOrdinal + 1} / $matchCount',
            showNavigation: true,
            canNavigate: matchCount > 0,
            onPrevious: () => _moveSearchResult(-1),
            onNext: () => _moveSearchResult(1),
            onClear: _clearSearch,
          ),
        Expanded(
          child: TimelineScreen(
            account: widget.account,
            entries: widget.entries,
            isLoading: widget.isLoadingTimeline,
            onRefresh: widget.onRefresh,
            searchQuery: _searchQuery,
            currentSearchEntryIndex: currentEntryIndex,
          ),
        ),
        SafeArea(
          top: false,
          child: _ChatComposer(
            controller: _controller,
            focusNode: _inputFocusNode,
            clockText: _clockText,
            isLongMode: _isLongMode,
            isSaving: widget.isSaving || _isSending,
            canSend: _canSend,
            onLongModeChanged: (value) {
              setState(() {
                _isLongMode = value;
              });
            },
            onSend: _sendCurrentText,
          ),
        ),
      ],
    );
  }

  Widget _buildThreadBody() {
    final threadEntries = _threadEntriesForSearch;

    return Column(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: _ThreadComposer(
            account: widget.account,
            controller: _controller,
            focusNode: _inputFocusNode,
            clockText: _clockText,
            isSaving: widget.isSaving || _isSending,
            canSend: _canSend,
            onSend: _sendCurrentText,
          ),
        ),
        if (_hasSearch)
          _SearchStatusBar(
            query: _searchQuery,
            summary: '${threadEntries.length}개 결과',
            showNavigation: false,
            canNavigate: false,
            onPrevious: null,
            onNext: null,
            onClear: _clearSearch,
          ),
        Expanded(
          child: ThreadTimelineScreen(
            account: widget.account,
            entries: threadEntries,
            isLoading: widget.isLoadingTimeline,
            onRefresh: widget.onRefresh,
            searchQuery: _searchQuery,
            emptyMessage: _hasSearch ? '검색 결과가 없습니다' : null,
          ),
        ),
      ],
    );
  }

  List<int> get _searchMatchIndices {
    if (!_hasSearch) {
      return const <int>[];
    }
    final query = _searchQuery.toLowerCase();
    final indices = <int>[];
    for (var index = 0; index < widget.entries.length; index += 1) {
      if (widget.entries[index].content.toLowerCase().contains(query)) {
        indices.add(index);
      }
    }
    return indices;
  }

  List<TimelineEntry> get _threadEntriesForSearch {
    if (!_hasSearch) {
      return widget.entries;
    }
    final query = _searchQuery.toLowerCase();
    return widget.entries
        .where((entry) => entry.content.toLowerCase().contains(query))
        .toList(growable: false);
  }

  int _clampedSearchOrdinal(int matchCount) {
    if (matchCount == 0) {
      return 0;
    }
    if (_currentSearchOrdinal < 0) {
      return 0;
    }
    if (_currentSearchOrdinal >= matchCount) {
      return matchCount - 1;
    }
    return _currentSearchOrdinal;
  }

  Future<void> _openSearchDialog() async {
    final result = await showDialog<_SearchDialogResult>(
      context: context,
      builder: (dialogContext) {
        return _SearchDialog(
          initialQuery: _searchQuery,
          hasActiveSearch: _hasSearch,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    switch (result.action) {
      case _SearchDialogAction.search:
        _applySearch(result.query);
      case _SearchDialogAction.clear:
        _clearSearch();
    }
  }

  void _applySearch(String value) {
    final query = value.trim();
    setState(() {
      _searchQuery = query;
      _currentSearchOrdinal = 0;
    });
  }

  void _clearSearch() {
    if (!_hasSearch) {
      return;
    }
    setState(() {
      _searchQuery = '';
      _currentSearchOrdinal = 0;
    });
  }

  void _moveSearchResult(int delta) {
    final matchCount = _searchMatchIndices.length;
    if (matchCount == 0) {
      return;
    }
    final current = _clampedSearchOrdinal(matchCount);
    setState(() {
      _currentSearchOrdinal = (current + delta) % matchCount;
      if (_currentSearchOrdinal < 0) {
        _currentSearchOrdinal += matchCount;
      }
    });
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SettingsSheet(
          account: widget.account,
          workspace: widget.workspace,
          writingMode: widget.writingMode,
          themeMode: widget.themeMode,
          fontScaleStep: widget.fontScaleStep,
          lastSync: widget.lastSync,
          onWritingModeChanged: widget.onWritingModeChanged,
          onThemeModeChanged: widget.onThemeModeChanged,
          onFontScaleStepChanged: widget.onFontScaleStepChanged,
          onSignOut: () async {
            Navigator.of(context).pop();
            await widget.onSignOut();
          },
        );
      },
    );
  }

  Future<void> _sendCurrentText() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSending || widget.isSaving) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    var didSave = false;
    try {
      await widget.onSave(content, _clockTimestamp);
      didSave = true;
    } catch (_) {
      // The parent shows the error; keep the draft in place.
    } finally {
      if (mounted) {
        if (didSave) {
          _controller.clear();
          _lastInputText = '';
        }
      }
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  KeyEventResult _handleInputKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) {
      return KeyEventResult.ignored;
    }

    if (widget.writingMode == WritingMode.thread) {
      if (HardwareKeyboard.instance.isControlPressed) {
        unawaited(_sendCurrentText());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_isLongMode) {
      return KeyEventResult.ignored;
    }

    if (HardwareKeyboard.instance.isShiftPressed) {
      _insertNewLine();
    } else {
      unawaited(_sendCurrentText());
    }
    return KeyEventResult.handled;
  }

  void _insertNewLine() {
    final value = _controller.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final newText = text.replaceRange(start, end, '\n');
    final offset = start + 1;

    _isApplyingShiftNewLine = true;
    _controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
    _isApplyingShiftNewLine = false;
    _lastInputText = newText;
  }

  void _handleTextChanged() {
    final currentText = _controller.text;
    final didAddNewLine =
        _countNewLines(currentText) > _countNewLines(_lastInputText);

    if (_isApplyingShiftNewLine || _isSending) {
      _lastInputText = currentText;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (widget.writingMode == WritingMode.chat &&
        !_isLongMode &&
        didAddNewLine &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _lastInputText = currentText;
      unawaited(_sendCurrentText());
      return;
    }

    _lastInputText = currentText;
    if (mounted) {
      setState(() {});
    }
  }

  static int _countNewLines(String value) {
    return '\n'.allMatches(value).length;
  }
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

enum _SearchDialogAction {
  search,
  clear,
}

class _SearchDialogResult {
  const _SearchDialogResult.search(this.query)
      : action = _SearchDialogAction.search;

  const _SearchDialogResult.clear()
      : action = _SearchDialogAction.clear,
        query = '';

  final _SearchDialogAction action;
  final String query;
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({
    required this.initialQuery,
    required this.hasActiveSearch,
  });

  final String initialQuery;
  final bool hasActiveSearch;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('검색'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: '검색어 입력',
        ),
        onSubmitted: _submit,
      ),
      actions: <Widget>[
        if (widget.hasActiveSearch)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                const _SearchDialogResult.clear(),
              );
            },
            child: const Text('검색 해제'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => _submit(_controller.text),
          child: const Text('검색'),
        ),
      ],
    );
  }

  void _submit(String value) {
    Navigator.of(context).pop(
      _SearchDialogResult.search(value),
    );
  }
}

class _SearchStatusBar extends StatelessWidget {
  const _SearchStatusBar({
    required this.query,
    required this.summary,
    required this.showNavigation,
    required this.canNavigate,
    required this.onPrevious,
    required this.onNext,
    required this.onClear,
  });

  final String query;
  final String summary;
  final bool showNavigation;
  final bool canNavigate;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.headerBar,
        border: Border(
          bottom: BorderSide(color: colors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.search,
              size: 18,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
            if (showNavigation) ...<Widget>[
              const SizedBox(width: 4),
              IconButton(
                tooltip: '이전 검색 결과',
                visualDensity: VisualDensity.compact,
                onPressed: canNavigate ? onPrevious : null,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: '다음 검색 결과',
                visualDensity: VisualDensity.compact,
                onPressed: canNavigate ? onNext : null,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
            IconButton(
              tooltip: '검색 해제',
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoloEchoTitle extends StatelessWidget {
  const _SoloEchoTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'assets/images/solo_echo_logo_transparent.png',
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 8),
        const Text('SoloEcho'),
      ],
    );
  }
}

class _ThreadComposer extends StatelessWidget {
  const _ThreadComposer({
    required this.account,
    required this.controller,
    required this.focusNode,
    required this.clockText,
    required this.isSaving,
    required this.canSend,
    required this.onSend,
  });

  final SoloEchoAccount account;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String clockText;
  final bool isSaving;
  final bool canSend;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.composerBackground,
        border: Border(
          bottom: BorderSide(color: colors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProfileAvatar(account: account),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 3,
                    maxLines: 8,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: '오늘은 어떤 하루였나요?',
                      filled: true,
                      fillColor: colors.inputFill,
                      hintStyle: TextStyle(color: colors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          clockText,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: canSend ? onSend : null,
                        icon: isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.edit_note_outlined),
                        label: const Text('기록'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.clockText,
    required this.isLongMode,
    required this.isSaving,
    required this.canSend,
    required this.onLongModeChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String clockText;
  final bool isLongMode;
  final bool isSaving;
  final bool canSend;
  final ValueChanged<bool> onLongModeChanged;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.composerBackground,
        border: Border(
          top: BorderSide(color: colors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.bottomCenter,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: isLongMode ? 5 : 1,
                maxLines: isLongMode ? 10 : 4,
                textInputAction:
                    isLongMode ? TextInputAction.newline : TextInputAction.send,
                keyboardType: TextInputType.multiline,
                onSubmitted: isLongMode ? null : (_) => onSend(),
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: isLongMode ? '긴 글을 적어주세요' : '메시지 입력',
                  filled: true,
                  fillColor: colors.inputFill,
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    clockText,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Checkbox(
                  value: isLongMode,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) => onLongModeChanged(value ?? false),
                ),
                GestureDetector(
                  onTap: () => onLongModeChanged(!isLongMode),
                  child: Text(
                    '긴글모드',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: '저장',
                  onPressed: canSend ? onSend : null,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.point,
                    foregroundColor: colors.pointText,
                    disabledBackgroundColor: colors.bubble,
                    disabledForegroundColor: colors.textSecondary,
                  ),
                  icon: isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
