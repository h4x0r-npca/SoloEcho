import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/ui/app_theme.dart';

void main() {
  test('dark theme colors match the design guide', () {
    final colors = SoloEchoTheme.darkTheme.extension<SoloEchoColors>()!;

    expect(colors.background, const Color(0xFF0F1216));
    expect(colors.headerBar, const Color(0xFF171A20));
    expect(colors.composerBackground, const Color(0xFF141922));
    expect(colors.bubble, const Color(0xFF272B33));
    expect(colors.threadCard, const Color(0xFF1B1E24));
    expect(colors.cardBorder, const Color(0xFF2B2F38));
    expect(colors.inputFill, const Color(0xFF1E2229));
    expect(colors.divider, const Color(0xFF232730));
    expect(colors.textPrimary, const Color(0xFFE9EAED));
    expect(colors.textSecondary, const Color(0xFF767B85));
    expect(colors.point, const Color(0xFF5A7FE0));
  });

  test('light theme colors match the design guide', () {
    final colors = SoloEchoTheme.lightTheme.extension<SoloEchoColors>()!;

    expect(colors.background, const Color(0xFFFFFFFF));
    expect(colors.headerBar, const Color(0xFFF5F7F9));
    expect(colors.bubble, const Color(0xFFD7E1EC));
    expect(colors.threadCard, const Color(0xFFEEF3F8));
    expect(colors.cardBorder, const Color(0xFFE1E8EF));
    expect(colors.inputFill, const Color(0xFFF1F4F7));
    expect(colors.divider, const Color(0xFFE6EBF0));
    expect(colors.textPrimary, const Color(0xFF1A1A1D));
    expect(colors.textSecondary, const Color(0xFF98A0A8));
    expect(colors.point, const Color(0xFF9FBEDE));
    expect(colors.pointText, const Color(0xFF1F2C39));
  });
}
