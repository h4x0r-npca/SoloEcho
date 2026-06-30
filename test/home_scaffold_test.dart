import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<void> Function(String content, DateTime timestamp)? onSave,
  Future<void> Function(WritingMode mode)? onWritingModeChanged,
}) {
  return HomeScaffold(
    account: account,
    workspace: const WorkspaceInfo(
      folderId: 'folder',
      spreadsheetId: 'sheet',
    ),
    entries: entries,
    writingMode: writingMode,
    isLoadingTimeline: false,
    isSaving: false,
    lastSync: null,
    onRefresh: () async {},
    onSave: onSave ?? (content, timestamp) async {},
    onWritingModeChanged: onWritingModeChanged ?? (mode) async {},
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

Future<void> _disposeHome(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
