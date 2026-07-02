import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/ui/lock_screen.dart';

void main() {
  testWidgets('lock screen rejects empty password locally', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LockScreen(
          onUnlock: (_) async => null,
          onUnlockComplete: () {},
          onResetLock: () async {},
        ),
      ),
    );

    await tester.tap(find.text('잠금 해제'));
    await tester.pump();

    expect(find.text('비밀번호를 입력해 주세요'), findsOneWidget);
  });

  testWidgets('lock screen shows unlock error from callback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LockScreen(
          onUnlock: (_) async => '비밀번호가 맞지 않습니다',
          onUnlockComplete: () {},
          onResetLock: () async {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.tap(find.text('잠금 해제'));
    await tester.pump();

    expect(find.text('비밀번호가 맞지 않습니다'), findsOneWidget);
  });

  testWidgets('lock screen completes unlock without local fade animation',
      (tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LockScreen(
          onUnlock: (_) async => null,
          onUnlockComplete: () {
            completed = true;
          },
          onResetLock: () async {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('잠금 해제'));
    await tester.pump();

    expect(completed, isTrue);
    expect(find.byKey(const ValueKey<String>('lock-screen-unlock-fade')),
        findsNothing);
  });

  testWidgets('lock screen reset asks confirmation', (tester) async {
    var reset = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LockScreen(
          onUnlock: (_) async => null,
          onUnlockComplete: () {},
          onResetLock: () async {
            reset = true;
          },
        ),
      ),
    );

    await tester.tap(find.text('비밀번호 재설정'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('재설정'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(reset, isTrue);
  });
}
