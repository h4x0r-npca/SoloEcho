import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/models/app_theme_mode.dart';
import 'package:soloecho/models/solo_echo_account.dart';
import 'package:soloecho/models/workspace_info.dart';
import 'package:soloecho/models/writing_mode.dart';
import 'package:soloecho/ui/settings_sheet.dart';

void main() {
  testWidgets('settings sheet changes writing mode', (tester) async {
    WritingMode? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SettingsSheet(
            account: const SoloEchoAccount(email: 'me@example.com'),
            workspace: const WorkspaceInfo(
              folderId: 'folder',
              spreadsheetId: 'sheet',
            ),
            writingMode: WritingMode.chat,
            themeMode: AppThemeMode.dark,
            lastSync: null,
            onWritingModeChanged: (mode) async {
              selected = mode;
            },
            onThemeModeChanged: (_) async {},
            onSignOut: () async {},
          ),
        ),
      ),
    );

    expect(find.text('글쓰기'), findsOneWidget);
    expect(find.text('채팅방식'), findsOneWidget);
    expect(find.text('스레드방식'), findsOneWidget);

    await tester.tap(find.text('스레드방식'));
    await tester.pump();

    expect(selected, WritingMode.thread);
  });

  testWidgets('settings sheet changes theme mode', (tester) async {
    AppThemeMode? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SettingsSheet(
            account: const SoloEchoAccount(email: 'me@example.com'),
            workspace: const WorkspaceInfo(
              folderId: 'folder',
              spreadsheetId: 'sheet',
            ),
            writingMode: WritingMode.chat,
            themeMode: AppThemeMode.dark,
            lastSync: null,
            onWritingModeChanged: (_) async {},
            onThemeModeChanged: (mode) async {
              selected = mode;
            },
            onSignOut: () async {},
          ),
        ),
      ),
    );

    expect(find.text('화면'), findsOneWidget);
    expect(find.text('다크'), findsOneWidget);
    expect(find.text('라이트'), findsOneWidget);

    await tester.tap(find.text('라이트'));
    await tester.pump();

    expect(selected, AppThemeMode.light);
  });

  testWidgets('settings sheet scrolls in short landscape layouts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 300));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SettingsSheet(
            account: const SoloEchoAccount(email: 'me@example.com'),
            workspace: const WorkspaceInfo(
              folderId: 'folder',
              spreadsheetId: 'sheet',
            ),
            writingMode: WritingMode.chat,
            themeMode: AppThemeMode.dark,
            lastSync: DateTime(2026, 6, 30, 18, 0),
            onWritingModeChanged: (_) async {},
            onThemeModeChanged: (_) async {},
            onSignOut: () async {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('로그아웃'), findsOneWidget);
  });
}
