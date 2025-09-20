import 'package:flutter/material.dart';

/// Text widget that animates numeric changes smoothly without the flicker of
/// swapping entire Text widgets via [AnimatedSwitcher].
class SmoothNumberText extends StatefulWidget {
  const SmoothNumberText({
    super.key,
    required this.value,
    required this.decimals,
    this.placeholder = '—',
    this.style,
    this.duration = const Duration(milliseconds: 240),
    this.curve = Curves.easeOutCubic,
  });

  /// Numeric value to display. If `null`, [placeholder] is shown instead.
  final double? value;

  /// Number of fractional digits to show when formatting the value.
  final int decimals;

  /// Text to render when [value] is `null`.
  final String placeholder;

  /// Text style for the rendered value/placeholder.
  final TextStyle? style;

  /// Duration for value change animations.
  final Duration duration;

  /// Animation curve applied while transitioning between values.
  final Curve curve;

  @override
  State<SmoothNumberText> createState() => _SmoothNumberTextState();
}

class _SmoothNumberTextState extends State<SmoothNumberText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Tween<double> _tween;
  double? _latestTarget;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    final initialValue = widget.value ?? 0;
    _tween = Tween<double>(begin: initialValue, end: initialValue);
    if (widget.value != null) {
      _latestTarget = widget.value;
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant SmoothNumberText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.curve != oldWidget.curve) {
      final currentValue = _latestTarget == null
          ? (widget.value ?? 0)
          : _tween.evaluate(_animation);
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
      _tween = Tween<double>(begin: currentValue, end: _latestTarget ?? currentValue);
      if (_latestTarget != null) {
        _controller.value = 1;
      }
    }

    final newValue = widget.value;
    if (newValue == null) {
      _latestTarget = null;
      _controller.stop();
      return;
    }

    if (_latestTarget != null && (newValue - _latestTarget!).abs() < 1e-6) {
      return;
    }

    final currentDisplayed = _latestTarget == null
        ? newValue
        : _tween.evaluate(_animation);
    _tween = Tween<double>(begin: currentDisplayed, end: newValue);
    _latestTarget = newValue;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value == null) {
      return Text(widget.placeholder, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _tween.evaluate(_animation);
        return Text(
          value.toStringAsFixed(widget.decimals),
          style: widget.style,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}