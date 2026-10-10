import 'package:flutter/material.dart';

class DownloadFlowIndicator extends StatefulWidget {
  const DownloadFlowIndicator({
    super.key,
    required this.progress,
    required this.active,
  });

  final double? progress;
  final bool active;

  @override
  State<DownloadFlowIndicator> createState() => _DownloadFlowIndicatorState();
}

class _DownloadFlowIndicatorState extends State<DownloadFlowIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant DownloadFlowIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _DownloadFlowPainter(
            progress: widget.progress,
            phase: _controller.value,
            active: widget.active,
            trackColor: theme.colorScheme.surfaceContainerHighest,
            startColor: theme.colorScheme.primary,
            endColor: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

class _DownloadFlowPainter extends CustomPainter {
  const _DownloadFlowPainter({
    required this.progress,
    required this.phase,
    required this.active,
    required this.trackColor,
    required this.startColor,
    required this.endColor,
  });

  final double? progress;
  final double phase;
  final bool active;
  final Color trackColor;
  final Color startColor;
  final Color endColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    canvas.drawRRect(track, Paint()..color = trackColor);

    final value = progress;
    if (value == null) {
      final width = size.width * .34;
      final x = (size.width + width) * phase - width;
      final rect = Rect.fromLTWH(x, 0, width, size.height);
      canvas.save();
      canvas.clipRRect(track);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [startColor, endColor],
          ).createShader(rect),
      );
      canvas.restore();
      return;
    }

    final clamped = value.clamp(0.0, 1.0);
    if (clamped <= 0) return;

    final filledWidth = size.width * clamped;
    final filledRect = Rect.fromLTWH(0, 0, filledWidth, size.height);
    final filled = RRect.fromRectAndRadius(
      filledRect,
      Radius.circular(radius),
    );

    canvas.drawRRect(
      filled,
      Paint()
        ..shader = LinearGradient(
          colors: [startColor, endColor],
        ).createShader(filledRect),
    );

    if (!active || filledWidth < 26) return;

    canvas.save();
    canvas.clipRRect(filled);
    final particlePaint = Paint()..color = Colors.white.withValues(alpha: .78);

    for (var index = 0; index < 3; index++) {
      final localPhase = (phase + index / 3) % 1;
      final x = localPhase * filledWidth;
      final y = size.height / 2;
      final particleRadius = 1.4 + (index * .35);
      canvas.drawCircle(
        Offset(x, y),
        particleRadius,
        particlePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DownloadFlowPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        phase != oldDelegate.phase ||
        active != oldDelegate.active ||
        trackColor != oldDelegate.trackColor ||
        startColor != oldDelegate.startColor ||
        endColor != oldDelegate.endColor;
  }
}
