import 'package:flutter/material.dart';

class TollSignalSplash extends StatefulWidget {
  final String title;
  final String tagline;
  final Future<void> Function() onReady; // called immediately on build
  final bool useBrandYellowBackground; // true: native-like yellow; false: dark gradient

  const TollSignalSplash({
    super.key,
    required this.onReady,
    this.title = 'TollSignal',
    this.tagline = "Know what's ahead.",
    this.useBrandYellowBackground = false,
  });

  @override
  State<TollSignalSplash> createState() => _TollSignalSplashState();
}

class _TollSignalSplashState extends State<TollSignalSplash>
    with TickerProviderStateMixin {
  late final AnimationController _pulse1;
  late final AnimationController _pulse2;

  @override
  void initState() {
    super.initState();
    _pulse1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulse2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )
      ..forward(from: 0.25)
      ..repeat();

    // Kick off initialization work immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady());
  }

  @override
  void dispose() {
    _pulse1.dispose();
    _pulse2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFFC400);
    const asphalt = Color(0xFF0B1117);
    const night = Color(0xFF06090D);
    const teal = Color(0xFF2FD3FF);
    const amber = Color(0xFFFFC043);

    final bool dark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final BoxDecoration background =
        widget.useBrandYellowBackground && !dark
            ? const BoxDecoration(color: brandYellow)
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [night, asphalt],
                ),
              );

    return Scaffold(
      body: Container(
        decoration: background,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated radar-like pulses + your icon in the center
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulse1, _pulse2]),
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size.square(220),
                        painter: _PulsePainter(
                          p1: _pulse1.value,
                          p2: _pulse2.value,
                          pulseColor: teal.withOpacity(0.35),
                          ringColor: amber.withOpacity(0.55),
                        ),
                      );
                    },
                  ),
                  // Your provided app icon. Ship the PNG with your app at the path
                  // below; if it's missing locally (e.g. binary omitted from source
                  // control) we fall back to a neutral glyph so the splash still
                  // renders gracefully.
                  Image.asset(
                    'assets/branding/tollsignal_icon.png',
                    width: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (context, _, __) => const Icon(
                      Icons.navigation,
                      size: 96,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            Opacity(
              opacity: 0.7,
              child: Text(
                'Preparing verified toll segments…',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double p1; // 0..1
  final double p2; // 0..1
  final Color pulseColor;
  final Color ringColor;

  _PulsePainter({
    required this.p1,
    required this.p2,
    required this.pulseColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide * 0.36;

    void drawPulse(double t) {
      final radius = base * (1 + t * 0.9);
      final alpha = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = pulseColor.withOpacity(0.45 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = base * 0.06 * (1 - t);
      canvas.drawCircle(center, radius, paint);
    }

    drawPulse(p1);
    drawPulse(p2);

    final ringPaint1 = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = base * 0.028;
    final ringPaint2 = Paint()
      ..color = ringColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = base * 0.022;

    canvas.drawCircle(center, base * 1.15, ringPaint1);
    canvas.drawCircle(center, base * 1.45, ringPaint2);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.p1 != p1 || oldDelegate.p2 != p2;
  }
}
