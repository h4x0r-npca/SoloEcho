import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/models/app_theme_mode.dart';
import 'package:soloecho/models/font_scale_step.dart';
import 'package:soloecho/models/solo_echo_account.dart';
import 'package:soloecho/models/timeline_entry.dart';
import 'package:soloecho/models/workspace_info.dart';
import 'package:soloecho/models/writing_mode.dart';
import 'package:soloecho/ui/home_scaffold.dart';
import 'package:soloecho/utils/timestamp_formatter.dart';

void main() {
  testWidgets('home screen has chat input without view/write tabs',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(),
      ),
    );

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('보기'), findsNothing);
    expect(find.text('쓰기'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('긴글모드'), findsOneWidget);
    expect(_liveClockFinder(), findsOneWidget);

    await _disposeHome(tester);
  });

  testWidgets('home applies configured font scale after login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(fontScaleStep: FontScaleStep.extraLarge),
      ),
    );

    final titleElement = tester.element(find.text('SoloEcho'));
    expect(
      MediaQuery.textScalerOf(titleElement).scale(100),
      closeTo(130, 0.001),
    );

    await _disposeHome(tester);
  });

  testWidgets('send button is disabled for empty input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(),
      ),
    );

    final sendButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send),
    );
    expect(sendButton.onPressed, isNull);

    await _disposeHome(tester);
  });

  testWidgets('search icon appears before settings and opens dialog',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(),
      ),
    );

    expect(find.byTooltip('검색'), findsOneWidget);
    expect(find.byTooltip('설정'), findsOneWidget);
    expect(
      tester.getCenter(find.byTooltip('검색')).dx,
      lessThan(tester.getCenter(find.byTooltip('설정')).dx),
    );

    await _openSearchDialog(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(_dialogTextFieldFinder(), findsOneWidget);

    await _disposeHome(tester);
  });

  testWidgets('ctrl f opens search dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(AlertDialog), findsOneWidget);

    await _disposeHome(tester);
  });

  testWidgets('meta f opens search dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(AlertDialog), findsOneWidget);

    await _disposeHome(tester);
  });

  testWidgets('chat search keeps all entries and cycles through matches',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          entries: <TimelineEntry>[
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 12),
              content: '첫 번째 야옹',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 11),
              content: '멍멍',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 10),
              content: '두 번째 야옹',
            ),
          ],
        ),
      ),
    );

    await _searchFor(tester, '야옹');

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNWidgets(3));

    await tester.tap(find.byTooltip('다음 검색 결과'));
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byTooltip('다음 검색 결과'));
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    await _disposeHome(tester);
  });

  testWidgets('chat search scrolls past tall entries to the current match',
      (tester) async {
    final longEntry = List<String>.filled(24, '길게 이어지는 문장').join('\n');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          entries: <TimelineEntry>[
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 12),
              content: '첫 번째 야옹',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 11),
              content: longEntry,
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 10),
              content: '위에 숨어있던 야옹',
            ),
          ],
        ),
      ),
    );

    await _searchFor(tester, '야옹');
    await tester.tap(find.byTooltip('다음 검색 결과'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final target = find.textContaining('위에 숨어있던 야옹');
    expect(target, findsOneWidget);
    final targetTop = tester.getTopLeft(target).dy;
    final composerTop = tester.getTopLeft(find.text('메시지 입력')).dy;

    expect(targetTop, greaterThan(120));
    expect(targetTop, lessThan(composerTop));

    await _disposeHome(tester);
  });

  testWidgets('chat search reveals matches near the bottom of tall entries',
      (tester) async {
    final longEntry = '${List<String>.filled(24, '위쪽에 있는 긴 문장').join('\n')}\n'
        '마지막 줄의 야옹';

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          entries: <TimelineEntry>[
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 12),
              content: '첫 번째 야옹',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 11),
              content: longEntry,
            ),
          ],
        ),
      ),
    );

    await _searchFor(tester, '야옹');
    await tester.tap(find.byTooltip('다음 검색 결과'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final target = find.textContaining('마지막 줄의 야옹');
    expect(target, findsOneWidget);
    final targetBottom = tester.getBottomLeft(target).dy;
    final statusBottom = tester.getBottomLeft(find.text('2 / 2')).dy;
    final composerTop = tester.getTopLeft(find.text('메시지 입력')).dy;

    expect(targetBottom, greaterThan(statusBottom));
    expect(targetBottom, lessThan(composerTop));

    await _disposeHome(tester);
  });

  testWidgets('thread search filters to matching entries', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          writingMode: WritingMode.thread,
          entries: <TimelineEntry>[
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 12),
              content: '첫 번째 야옹',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 11),
              content: '멍멍',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 10),
              content: '두 번째 야옹',
            ),
          ],
        ),
      ),
    );

    await _searchFor(tester, '야옹');

    expect(find.text('2개 결과'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNWidgets(3));
    expect(find.textContaining('멍멍'), findsNothing);

    await _disposeHome(tester);
  });

  testWidgets('thread search shows empty result and clear restores list',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          writingMode: WritingMode.thread,
          entries: <TimelineEntry>[
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 12),
              content: '야옹',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 11),
              content: '멍멍',
            ),
          ],
        ),
      ),
    );

    await _searchFor(tester, '없음');

    expect(find.text('0개 결과'), findsOneWidget);
    expect(find.text('검색 결과가 없습니다'), findsOneWidget);

    await tester.tap(find.byTooltip('검색 해제'));
    await tester.pump();

    expect(find.text('0개 결과'), findsNothing);
    expect(find.byType(CircleAvatar), findsNWidgets(3));

    await _disposeHome(tester);
  });

  testWidgets('button clears only after save completes', (tester) async {
    final saveCompleter = Completer<void>();
    String? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          onSave: (content, timestamp) async {
            saved = content;
            await saveCompleter.future;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  hello  ');
    await tester.pump();
    await tester.tap(find.byTooltip('저장'));
    await tester.pump();

    TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(saved, 'hello');
    expect(field.controller?.text, '  hello  ');

    saveCompleter.complete();
    await tester.pump();

    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);

    await _disposeHome(tester);
  });

  testWidgets('failed save keeps the draft and does not leak framework errors',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          onSave: (content, timestamp) async {
            throw StateError('save failed');
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  keep me  ');
    await tester.pump();
    await tester.tap(find.byTooltip('저장'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '  keep me  ');
    expect(tester.takeException(), isNull);

    await _disposeHome(tester);
  });

  testWidgets('enter sends short input and clears after save succeeds',
      (tester) async {
    String? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          onSave: (content, timestamp) async {
            saved = content;
          },
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '  hello  ');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(saved, 'hello');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);

    await _disposeHome(tester);
  });

  testWidgets('newline inserted by enter also sends and clears after success',
      (tester) async {
    String? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          onSave: (content, timestamp) async {
            saved = content;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hello\n');
    await tester.pump();

    expect(saved, 'hello');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);

    await _disposeHome(tester);
  });

  testWidgets('short mode grows upward and shift enter inserts a newline',
      (tester) async {
    String? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          onSave: (content, timestamp) async {
            saved = content;
          },
        ),
      ),
    );

    TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 1);
    expect(field.maxLines, 4);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.send);

    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(saved, isNull);
    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'hello\n');

    await tester.enterText(find.byType(TextField), 'hello\nworld');
    await tester.pump();
    expect(saved, isNull);

    await _disposeHome(tester);
  });

  testWidgets('long mode expands input and clears after save succeeds',
      (tester) async {
    String? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          onSave: (content, timestamp) async {
            saved = content;
          },
        ),
      ),
    );

    TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, 4);
    expect(field.textInputAction, TextInputAction.send);

    await tester.tap(find.text('긴글모드'));
    await tester.pump(const Duration(milliseconds: 220));

    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 5);
    expect(field.maxLines, 10);
    expect(field.textInputAction, TextInputAction.newline);

    await tester.enterText(find.byType(TextField), '  long\nmessage  ');
    await tester.pump();
    await tester.tap(find.byTooltip('저장'));
    await tester.pump();

    expect(saved, 'long\nmessage');
    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);

    await tester.tap(find.text('긴글모드'));
    await tester.pump(const Duration(milliseconds: 220));

    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, 4);
    expect(field.textInputAction, TextInputAction.send);

    await _disposeHome(tester);
  });

  testWidgets('saving uses the timestamp shown in the composer',
      (tester) async {
    DateTime? savedAt;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          onSave: (content, timestamp) async {
            savedAt = timestamp;
          },
        ),
      ),
    );

    final visibleClock = tester.widget<Text>(_liveClockFinder()).data;
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byTooltip('저장'));
    await tester.pump();

    expect(savedAt, isNotNull);
    expect(TimestampFormatter.format(savedAt!), visibleClock);

    await _disposeHome(tester);
  });

  testWidgets('timeline scroll is reversed so newest entries appear at bottom',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          entries: <TimelineEntry>[
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 12),
              content: 'newest',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 11),
              content: 'older',
            ),
          ],
        ),
      ),
    );

    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(scrollView.reverse, isTrue);
    expect(find.byType(Divider), findsNothing);

    await _disposeHome(tester);
  });

  testWidgets('thread mode shows top composer with live timestamp',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(writingMode: WritingMode.thread),
      ),
    );

    expect(find.text('오늘은 어떤 하루였나요?'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('긴글모드'), findsNothing);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(_liveClockFinder(), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 3);
    expect(field.maxLines, 8);
    expect(field.textInputAction, TextInputAction.newline);

    await _disposeHome(tester);
  });

  testWidgets('thread mode shows newest entries at the top', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          writingMode: WritingMode.thread,
          entries: <TimelineEntry>[
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 12),
              content: 'newest',
            ),
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 11),
              content: 'older',
            ),
          ],
        ),
      ),
    );

    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(scrollView.reverse, isFalse);
    expect(find.byType(CircleAvatar), findsNWidgets(3));
    expect(
      tester.getTopLeft(find.text('newest')).dy,
      lessThan(tester.getTopLeft(find.text('older')).dy),
    );

    await _disposeHome(tester);
  });

  testWidgets('thread mode uses Google profile image avatars', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          account: const SoloEchoAccount(
            email: 'me@example.com',
            photoUrl: 'https://example.com/me.png',
          ),
          writingMode: WritingMode.thread,
          entries: <TimelineEntry>[
            TimelineEntry(
              timestamp: DateTime(2026, 6, 26, 12),
              content: 'newest',
            ),
          ],
        ),
      ),
    );

    final avatars = tester.widgetList<CircleAvatar>(
      find.byType(CircleAvatar),
    );
    expect(avatars, hasLength(2));
    for (final avatar in avatars) {
      expect(avatar.foregroundImage, isA<NetworkImage>());
    }

    await _disposeHome(tester);
  });

  testWidgets('thread mode newline input does not save', (tester) async {
    String? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          writingMode: WritingMode.thread,
          onSave: (content, timestamp) async {
            saved = content;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello\n');
    await tester.pump();

    expect(saved, isNull);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'hello\n');

    await _disposeHome(tester);
  });

  testWidgets('thread mode control enter saves shown timestamp',
      (tester) async {
    String? saved;
    DateTime? savedAt;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          writingMode: WritingMode.thread,
          onSave: (content, timestamp) async {
            saved = content;
            savedAt = timestamp;
          },
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextField));
    final visibleClock = tester.widget<Text>(_liveClockFinder()).data;
    await tester.enterText(find.byType(TextField), '  shortcut entry  ');
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(saved, 'shortcut entry');
    expect(savedAt, isNotNull);
    expect(TimestampFormatter.format(savedAt!), visibleClock);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);

    await _disposeHome(tester);
  });

  testWidgets('thread mode record button saves shown timestamp',
      (tester) async {
    String? saved;
    DateTime? savedAt;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _buildHome(
          writingMode: WritingMode.thread,
          onSave: (content, timestamp) async {
            saved = content;
            savedAt = timestamp;
          },
        ),
      ),
    );

    final visibleClock = tester.widget<Text>(_liveClockFinder()).data;
    await tester.enterText(find.byType(TextField), '  thread entry  ');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '기록'));
    await tester.pump();

    expect(saved, 'thread entry');
    expect(savedAt, isNotNull);
    expect(TimestampFormatter.format(savedAt!), visibleClock);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);

    await _disposeHome(tester);
  });
}

HomeScaffold _buildHome({
  SoloEchoAccount account = const SoloEchoAccount(email: 'me@example.com'),
  List<TimelineEntry> entries = const <TimelineEntry>[],
  WritingMode writingMode = WritingMode.chat,
  AppThemeMode themeMode = AppThemeMode.dark,
  FontScaleStep fontScaleStep = FontScaleStep.defaultValue,
  Future<void> Function(String content, DateTime timestamp)? onSave,
  Future<void> Function(WritingMode mode)? onWritingModeChanged,
  Future<void> Function(AppThemeMode mode)? onThemeModeChanged,
  Future<void> Function(FontScaleStep step)? onFontScaleStepChanged,
}) {
  return HomeScaffold(
    account: account,
    workspace: const WorkspaceInfo(
      folderId: 'folder',
      spreadsheetId: 'sheet',
    ),
    entries: entries,
    writingMode: writingMode,
    themeMode: themeMode,
    fontScaleStep: fontScaleStep,
    isLoadingTimeline: false,
    isSaving: false,
    lastSync: null,
    onRefresh: () async {},
    onSave: onSave ?? (content, timestamp) async {},
    onWritingModeChanged: onWritingModeChanged ?? (mode) async {},
    onThemeModeChanged: onThemeModeChanged ?? (mode) async {},
    onFontScaleStepChanged: onFontScaleStepChanged ?? (step) async {},
    onSignOut: () async {},
  );
}

Finder _liveClockFinder() {
  final pattern = RegExp(
    r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{6}$',
  );
  return find.byWidgetPredicate(
    (widget) => widget is Text && pattern.hasMatch(widget.data ?? ''),
  );
}

Finder _dialogTextFieldFinder() {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );
}

Future<void> _openSearchDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('검색'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _searchFor(WidgetTester tester, String query) async {
  await _openSearchDialog(tester);
  await tester.enterText(_dialogTextFieldFinder(), query);
  await tester.pump();
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, '검색'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _disposeHome(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
