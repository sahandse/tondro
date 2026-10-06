import 'package:flutter/material.dart';

class TondroLogo extends StatelessWidget {
  const TondroLogo({
    super.key,
    this.size = 44,
    this.inverted = false,
  });

  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = inverted ? !dark : dark;
    final background = base ? Colors.white : Colors.black;
    final foreground = base ? Colors.black : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .18),
        border: Border.all(
          color: foreground.withValues(alpha: .28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .45 : .16),
            offset: const Offset(2, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TondroLogoPainter(foreground),
      ),
    );
  }
}

class _TondroLogoPainter extends CustomPainter {
  const _TondroLogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * .09
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final center = size.width / 2;
    canvas.drawLine(
      Offset(center, size.height * .18),
      Offset(center, size.height * .66),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .31, size.height * .48),
      Offset(center, size.height * .68),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .69, size.height * .48),
      Offset(center, size.height * .68),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .26, size.height * .78),
      Offset(size.width * .74, size.height * .78),
      paint,
    );

    final bolt = Path()
      ..moveTo(size.width * .62, size.height * .16)
      ..lineTo(size.width * .48, size.height * .42)
      ..lineTo(size.width * .60, size.height * .42)
      ..lineTo(size.width * .48, size.height * .59);
    canvas.drawPath(
      bolt,
      Paint()
        ..color = color
        ..strokeWidth = size.width * .055
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TondroLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

class XpWindowFrame extends StatelessWidget {
  const XpWindowFrame({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(14),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final border = theme.colorScheme.outline;
    final surface = theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .45 : .14),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.surface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
                const SizedBox(width: 5),
                _WindowDot(color: theme.colorScheme.surface),
                const SizedBox(width: 4),
                _WindowDot(color: theme.colorScheme.surface),
                const SizedBox(width: 4),
                _WindowDot(color: theme.colorScheme.surface),
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _WindowDot extends StatelessWidget {
  const _WindowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
