import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/models/app_theme_mode.dart';
import 'package:soloecho/models/font_scale_step.dart';
import 'package:soloecho/models/solo_echo_account.dart';
import 'package:soloecho/models/workspace_info.dart';
import 'package:soloecho/models/writing_mode.dart';
import 'package:soloecho/ui/profile_avatar.dart';
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
            fontScaleStep: FontScaleStep.defaultValue,
            motionEffectsEnabled: true,
            lockEnabled: false,
            lastSync: null,
            onWritingModeChanged: (mode) async {
              selected = mode;
            },
            onThemeModeChanged: (_) async {},
            onFontScaleStepChanged: (_) async {},
            onMotionEffectsChanged: (_) async {},
            onEnableLock: (_) async => null,
            onDisableLock: (_) async => null,
            onChangeLockPassword: ({
              required currentPassword,
              required newPassword,
            }) async =>
                null,
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
            fontScaleStep: FontScaleStep.defaultValue,
            motionEffectsEnabled: true,
            lockEnabled: false,
            lastSync: null,
            onWritingModeChanged: (_) async {},
            onThemeModeChanged: (mode) async {
              selected = mode;
            },
            onFontScaleStepChanged: (_) async {},
            onMotionEffectsChanged: (_) async {},
            onEnableLock: (_) async => null,
            onDisableLock: (_) async => null,
            onChangeLockPassword: ({
              required currentPassword,
              required newPassword,
            }) async =>
                null,
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

  testWidgets('settings sheet uses Google profile photo when available',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: _buildSettingsSheet(
            account: const SoloEchoAccount(
              email: 'me@example.com',
              displayName: '민지',
              photoUrl: 'https://example.com/profile.png',
            ),
          ),
        ),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(
      find.descendant(
        of: find.byType(ProfileAvatar),
        matching: find.byType(CircleAvatar),
      ),
    );
    final image = avatar.foregroundImage;

    expect(image, isA<NetworkImage>());
    expect((image! as NetworkImage).url, 'https://example.com/profile.png');
  });

  testWidgets('settings sheet changes font scale with slider', (tester) async {
    FontScaleStep? selected;

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
            fontScaleStep: FontScaleStep.defaultValue,
            motionEffectsEnabled: true,
            lockEnabled: false,
            lastSync: null,
            onWritingModeChanged: (_) async {},
            onThemeModeChanged: (_) async {},
            onFontScaleStepChanged: (step) async {
              selected = step;
            },
            onMotionEffectsChanged: (_) async {},
            onEnableLock: (_) async => null,
            onDisableLock: (_) async => null,
            onChangeLockPassword: ({
              required currentPassword,
              required newPassword,
            }) async =>
                null,
            onSignOut: () async {},
          ),
        ),
      ),
    );

    expect(find.text('글씨'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('기본크기'), findsNothing);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(2);
    await tester.pump();

    expect(selected, FontScaleStep.large);
  });

  testWidgets('settings sheet resets font scale to default', (tester) async {
    FontScaleStep? selected;

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
            fontScaleStep: FontScaleStep.large,
            motionEffectsEnabled: true,
            lockEnabled: false,
            lastSync: null,
            onWritingModeChanged: (_) async {},
            onThemeModeChanged: (_) async {},
            onFontScaleStepChanged: (step) async {
              selected = step;
            },
            onMotionEffectsChanged: (_) async {},
            onEnableLock: (_) async => null,
            onDisableLock: (_) async => null,
            onChangeLockPassword: ({
              required currentPassword,
              required newPassword,
            }) async =>
                null,
            onSignOut: () async {},
          ),
        ),
      ),
    );

    expect(find.text('120%'), findsOneWidget);
    expect(find.text('기본크기'), findsOneWidget);

    await tester.tap(find.text('기본크기'));
    await tester.pump();

    expect(selected, FontScaleStep.defaultValue);
  });

  testWidgets('settings sheet changes motion effects setting', (tester) async {
    bool? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: _buildSettingsSheet(
            motionEffectsEnabled: true,
            onMotionEffectsChanged: (enabled) async {
              selected = enabled;
            },
          ),
        ),
      ),
    );

    expect(find.text('애니메이션'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(selected, isFalse);
  });

  testWidgets('settings sheet enables lock with matching passwords',
      (tester) async {
    String? password;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: _buildSettingsSheet(
            onEnableLock: (value) async {
              password = value;
              return null;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('잠금 켜기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '  secret  ');
    await tester.enterText(find.byType(TextField).at(1), '  secret  ');
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(password, '  secret  ');
  });

  testWidgets('settings sheet rejects mismatched lock passwords',
      (tester) async {
    var called = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: _buildSettingsSheet(
            onEnableLock: (_) async {
              called = true;
              return null;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('잠금 켜기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'one');
    await tester.enterText(find.byType(TextField).at(1), 'two');
    await tester.tap(find.text('완료'));
    await tester.pump();

    expect(called, isFalse);
    expect(find.text('새 비밀번호가 서로 다릅니다'), findsOneWidget);
  });

  testWidgets('settings sheet disables lock after current password',
      (tester) async {
    String? currentPassword;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: _buildSettingsSheet(
            lockEnabled: true,
            onDisableLock: (value) async {
              currentPassword = value;
              return null;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('잠금 끄기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'current');
    await tester.tap(find.text('끄기'));
    await tester.pumpAndSettle();

    expect(currentPassword, 'current');
  });

  testWidgets('settings sheet changes lock password after current password',
      (tester) async {
    String? observedCurrentPassword;
    String? observedNewPassword;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: _buildSettingsSheet(
            lockEnabled: true,
            onChangeLockPassword: ({
              required String currentPassword,
              required String newPassword,
            }) async {
              observedCurrentPassword = currentPassword;
              observedNewPassword = newPassword;
              return null;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('비밀번호 변경'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'old');
    await tester.enterText(find.byType(TextField).at(1), 'new');
    await tester.enterText(find.byType(TextField).at(2), 'new');
    await tester.tap(find.text('변경'));
    await tester.pumpAndSettle();

    expect(observedCurrentPassword, 'old');
    expect(observedNewPassword, 'new');
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
            fontScaleStep: FontScaleStep.defaultValue,
            motionEffectsEnabled: true,
            lockEnabled: false,
            lastSync: DateTime(2026, 6, 30, 18, 0),
            onWritingModeChanged: (_) async {},
            onThemeModeChanged: (_) async {},
            onFontScaleStepChanged: (_) async {},
            onMotionEffectsChanged: (_) async {},
            onEnableLock: (_) async => null,
            onDisableLock: (_) async => null,
            onChangeLockPassword: ({
              required currentPassword,
              required newPassword,
            }) async =>
                null,
            onSignOut: () async {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('로그아웃'), findsOneWidget);
  });
}

SettingsSheet _buildSettingsSheet({
  SoloEchoAccount account = const SoloEchoAccount(email: 'me@example.com'),
  bool motionEffectsEnabled = true,
  bool lockEnabled = false,
  Future<void> Function(bool enabled)? onMotionEffectsChanged,
  Future<String?> Function(String password)? onEnableLock,
  Future<String?> Function(String currentPassword)? onDisableLock,
  Future<String?> Function({
    required String currentPassword,
    required String newPassword,
  })? onChangeLockPassword,
}) {
  return SettingsSheet(
    account: account,
    workspace: const WorkspaceInfo(
      folderId: 'folder',
      spreadsheetId: 'sheet',
    ),
    writingMode: WritingMode.chat,
    themeMode: AppThemeMode.dark,
    fontScaleStep: FontScaleStep.defaultValue,
    motionEffectsEnabled: motionEffectsEnabled,
    lockEnabled: lockEnabled,
    lastSync: null,
    onWritingModeChanged: (_) async {},
    onThemeModeChanged: (_) async {},
    onFontScaleStepChanged: (_) async {},
    onMotionEffectsChanged: onMotionEffectsChanged ?? (_) async {},
    onEnableLock: onEnableLock ?? (_) async => null,
    onDisableLock: onDisableLock ?? (_) async => null,
    onChangeLockPassword: onChangeLockPassword ??
        ({
          required currentPassword,
          required newPassword,
        }) async =>
            null,
    onSignOut: () async {},
  );
}
