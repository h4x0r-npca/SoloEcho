import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class SoloEchoColors extends ThemeExtension<SoloEchoColors> {
  const SoloEchoColors({
    required this.background,
    required this.headerBar,
    required this.composerBackground,
    required this.bubble,
    required this.threadCard,
    required this.cardBorder,
    required this.inputFill,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.point,
    required this.pointText,
  });

  final Color background;
  final Color headerBar;
  final Color composerBackground;
  final Color bubble;
  final Color threadCard;
  final Color cardBorder;
  final Color inputFill;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color point;
  final Color pointText;

  static const dark = SoloEchoColors(
    background: Color(0xFF0F1216),
    headerBar: Color(0xFF171A20),
    composerBackground: Color(0xFF141922),
    bubble: Color(0xFF272B33),
    threadCard: Color(0xFF1B1E24),
    cardBorder: Color(0xFF2B2F38),
    inputFill: Color(0xFF1E2229),
    divider: Color(0xFF232730),
    textPrimary: Color(0xFFE9EAED),
    textSecondary: Color(0xFF767B85),
    point: Color(0xFF5A7FE0),
    pointText: Color(0xFFFFFFFF),
  );

  static const light = SoloEchoColors(
    background: Color(0xFFFFFFFF),
    headerBar: Color(0xFFF5F7F9),
    composerBackground: Color(0xFFFFFFFF),
    bubble: Color(0xFFD7E1EC),
    threadCard: Color(0xFFEEF3F8),
    cardBorder: Color(0xFFE1E8EF),
    inputFill: Color(0xFFF1F4F7),
    divider: Color(0xFFE6EBF0),
    textPrimary: Color(0xFF1A1A1D),
    textSecondary: Color(0xFF98A0A8),
    point: Color(0xFF9FBEDE),
    pointText: Color(0xFF1F2C39),
  );

  static SoloEchoColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<SoloEchoColors>() ??
        switch (theme.brightness) {
          Brightness.dark => SoloEchoColors.dark,
          Brightness.light => SoloEchoColors.light,
        };
  }

  @override
  SoloEchoColors copyWith({
    Color? background,
    Color? headerBar,
    Color? composerBackground,
    Color? bubble,
    Color? threadCard,
    Color? cardBorder,
    Color? inputFill,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? point,
    Color? pointText,
  }) {
    return SoloEchoColors(
      background: background ?? this.background,
      headerBar: headerBar ?? this.headerBar,
      composerBackground: composerBackground ?? this.composerBackground,
      bubble: bubble ?? this.bubble,
      threadCard: threadCard ?? this.threadCard,
      cardBorder: cardBorder ?? this.cardBorder,
      inputFill: inputFill ?? this.inputFill,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      point: point ?? this.point,
      pointText: pointText ?? this.pointText,
    );
  }

  @override
  SoloEchoColors lerp(ThemeExtension<SoloEchoColors>? other, double t) {
    if (other is! SoloEchoColors) {
      return this;
    }
    return SoloEchoColors(
      background: Color.lerp(background, other.background, t)!,
      headerBar: Color.lerp(headerBar, other.headerBar, t)!,
      composerBackground:
          Color.lerp(composerBackground, other.composerBackground, t)!,
      bubble: Color.lerp(bubble, other.bubble, t)!,
      threadCard: Color.lerp(threadCard, other.threadCard, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      point: Color.lerp(point, other.point, t)!,
      pointText: Color.lerp(pointText, other.pointText, t)!,
    );
  }
}

class SoloEchoTheme {
  const SoloEchoTheme._();

  static ThemeData get darkTheme => _build(
        colors: SoloEchoColors.dark,
        brightness: Brightness.dark,
      );

  static ThemeData get lightTheme => _build(
        colors: SoloEchoColors.light,
        brightness: Brightness.light,
      );

  static ThemeData _build({
    required SoloEchoColors colors,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.point,
      brightness: brightness,
    ).copyWith(
      primary: colors.point,
      onPrimary: colors.pointText,
      primaryContainer: colors.point,
      onPrimaryContainer: colors.pointText,
      secondary: colors.bubble,
      onSecondary: colors.textPrimary,
      surface: colors.background,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.bubble,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.cardBorder,
      outlineVariant: colors.divider,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Pretendard',
    );
    final textTheme = _applyTextColor(base.textTheme, colors.textPrimary);
    final overlayStyle = switch (brightness) {
      Brightness.dark => SystemUiOverlayStyle.light.copyWith(
          statusBarColor: colors.headerBar,
          systemNavigationBarColor: colors.background,
          systemNavigationBarDividerColor: colors.divider,
        ),
      Brightness.light => SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: colors.headerBar,
          systemNavigationBarColor: colors.background,
          systemNavigationBarDividerColor: colors.divider,
        ),
    };

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        colors,
      ],
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      cardColor: colors.threadCard,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colors.headerBar,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        hintStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.point, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.point,
          foregroundColor: colors.pointText,
          disabledBackgroundColor: colors.bubble,
          disabledForegroundColor: colors.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.point;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colors.pointText),
        side: BorderSide(color: colors.textSecondary, width: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.bubble,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
        ),
      ),
    );
  }

  static TextTheme _applyTextColor(TextTheme textTheme, Color color) {
    return textTheme.apply(
      bodyColor: color,
      displayColor: color,
      decorationColor: color,
    );
  }
}
