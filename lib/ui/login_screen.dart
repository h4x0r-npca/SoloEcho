import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.isBusy,
    required this.onSignIn,
    this.errorMessage,
  });

  final bool isBusy;
  final Future<void> Function() onSignIn;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      children: <Widget>[
        FilledButton.icon(
          onPressed: isBusy ? null : onSignIn,
          icon: isBusy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login),
          label: Text(isBusy ? '로그인 중' : 'Google로 계속하기'),
        ),
        if (errorMessage != null) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.children,
  });

  final List<Widget> children;
  static const _logoAsset = 'assets/images/solo_echo_logo_transparent.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _EmotionGradientBackground()),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0x660A0B0C)),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Image.asset(
                        _logoAsset,
                        width: 136,
                        height: 136,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'SoloEcho',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 32),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionGradientBackground extends StatefulWidget {
  const _EmotionGradientBackground();

  @override
  State<_EmotionGradientBackground> createState() =>
      _EmotionGradientBackgroundState();
}

class _EmotionGradientBackgroundState extends State<_EmotionGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _EmotionGradientPainter(_controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _EmotionGradientPainter extends CustomPainter {
  const _EmotionGradientPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final basePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(
          size.width * (0.06 + 0.08 * math.sin(phase)),
          size.height * (0.03 + 0.08 * math.cos(phase * 0.7)),
        ),
        Offset(
          size.width * (0.94 + 0.08 * math.cos(phase * 0.8)),
          size.height * (0.98 + 0.08 * math.sin(phase * 0.6)),
        ),
        const <Color>[
          Color(0xFFFFF3C8),
          Color(0xFFFFC7D8),
          Color(0xFFC8F3DE),
          Color(0xFFB7E3FF),
          Color(0xFFD4C1FF),
          Color(0xFF6F609D),
          Color(0xFF171623),
        ],
        const <double>[0, 0.17, 0.34, 0.5, 0.67, 0.84, 1],
      );
    canvas.drawRect(rect, basePaint);

    _drawRibbon(
      canvas,
      size,
      phase,
      0,
      const <Color>[Color(0x44FFF9DC), Color(0x22FF8FAF)],
    );
    _drawRibbon(
      canvas,
      size,
      phase,
      math.pi * 0.72,
      const <Color>[Color(0x33AEEBFF), Color(0x227D6CFF)],
    );
    _drawRibbon(
      canvas,
      size,
      phase,
      math.pi * 1.35,
      const <Color>[Color(0x334FE3B1), Color(0x22423263)],
    );
  }

  void _drawRibbon(
    Canvas canvas,
    Size size,
    double phase,
    double offset,
    List<Color> colors,
  ) {
    final width = size.width;
    final height = size.height;
    final centerY = height * (0.38 + 0.12 * math.sin(phase + offset));
    final ribbonHeight = height * 0.28;
    final wave = height * 0.18;
    final path = Path()
      ..moveTo(-width * 0.12, centerY)
      ..cubicTo(
        width * 0.18,
        centerY - wave * math.cos(phase + offset),
        width * 0.38,
        centerY + wave * math.sin(phase * 0.7 + offset),
        width * 0.66,
        centerY - wave * 0.4,
      )
      ..cubicTo(
        width * 0.86,
        centerY - wave,
        width * 1.04,
        centerY + wave * 0.7,
        width * 1.12,
        centerY + wave * 0.2,
      )
      ..lineTo(width * 1.12, centerY + ribbonHeight)
      ..cubicTo(
        width * 0.78,
        centerY + ribbonHeight + wave * 0.4,
        width * 0.4,
        centerY + ribbonHeight - wave * 0.5,
        -width * 0.12,
        centerY + ribbonHeight + wave * 0.2,
      )
      ..close();

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, centerY),
        Offset(width, centerY + ribbonHeight),
        colors,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EmotionGradientPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
