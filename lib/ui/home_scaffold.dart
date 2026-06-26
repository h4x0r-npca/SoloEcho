import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/solo_echo_account.dart';
import '../models/timeline_entry.dart';
import '../models/workspace_info.dart';
import 'settings_sheet.dart';
import 'timeline_screen.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({
    super.key,
    required this.account,
    required this.workspace,
    required this.entries,
    required this.isLoadingTimeline,
    required this.isSaving,
    required this.lastSync,
    required this.onRefresh,
    required this.onSave,
    required this.onSignOut,
  });

  final SoloEchoAccount account;
  final WorkspaceInfo workspace;
  final List<TimelineEntry> entries;
  final bool isLoadingTimeline;
  final bool isSaving;
  final DateTime? lastSync;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String content) onSave;
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
  String _clockText = _formatLiveClock(DateTime.now());

  bool get _canSend =>
      _controller.text.trim().isNotEmpty && !widget.isSaving && !_isSending;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
    _clockTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _clockText = _formatLiveClock(DateTime.now());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoloEcho'),
        actions: <Widget>[
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: TimelineScreen(
              account: widget.account,
              entries: widget.entries,
              isLoading: widget.isLoadingTimeline,
              onRefresh: widget.onRefresh,
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
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SettingsSheet(
          account: widget.account,
          workspace: widget.workspace,
          lastSync: widget.lastSync,
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

    try {
      await widget.onSave(content);
      if (mounted) {
        _controller.clear();
        _lastInputText = '';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  KeyEventResult _handleInputKeyEvent(FocusNode node, KeyEvent event) {
    if (_isLongMode || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) {
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

    if (!_isLongMode &&
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

  static String _formatLiveClock(DateTime value) {
    final local = value.toLocal();
    final date = '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
    final fractional = '${local.millisecond.toString().padLeft(3, '0')}'
        '${local.microsecond.toString().padLeft(3, '0')}';
    return '$date $time.$fractional';
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
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
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                decoration: InputDecoration(
                  hintText: isLongMode ? '긴 글을 적어주세요' : '메시지 입력',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
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
                      color: theme.colorScheme.onSurfaceVariant,
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
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: '저장',
                  onPressed: canSend ? onSend : null,
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
