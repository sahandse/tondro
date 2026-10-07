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
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _TondroRibbonPainter(),
      ),
    );
  }
}

class _TondroRibbonPainter extends CustomPainter {
  const _TondroRibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const cyan = Color(0xFF56E9FF);
    const blue = Color(0xFF1785FF);
    const royal = Color(0xFF1746E8);
    const deep = Color(0xFF092CA5);

    final top = Path()
      ..moveTo(size.width * .50, size.height * .08)
      ..cubicTo(
        size.width * .28,
        size.height * .20,
        size.width * .26,
        size.height * .35,
        size.width * .44,
        size.height * .45,
      )
      ..cubicTo(
        size.width * .61,
        size.height * .55,
        size.width * .73,
        size.height * .51,
        size.width * .76,
        size.height * .41,
      )
      ..cubicTo(
        size.width * .79,
        size.height * .31,
        size.width * .70,
        size.height * .25,
        size.width * .50,
        size.height * .08,
      )
      ..close();

    final middle = Path()
      ..moveTo(size.width * .34, size.height * .36)
      ..cubicTo(
        size.width * .41,
        size.height * .48,
        size.width * .66,
        size.height * .50,
        size.width * .70,
        size.height * .62,
      )
      ..cubicTo(
        size.width * .73,
        size.height * .71,
        size.width * .64,
        size.height * .77,
        size.width * .52,
        size.height * .79,
      )
      ..cubicTo(
        size.width * .64,
        size.height * .68,
        size.width * .55,
        size.height * .61,
        size.width * .39,
        size.height * .55,
      )
      ..cubicTo(
        size.width * .25,
        size.height * .50,
        size.width * .24,
        size.height * .43,
        size.width * .34,
        size.height * .36,
      )
      ..close();

    final arrow = Path()
      ..moveTo(size.width * .22, size.height * .64)
      ..lineTo(size.width * .45, size.height * .68)
      ..lineTo(size.width * .45, size.height * .57)
      ..lineTo(size.width * .52, size.height * .79)
      ..lineTo(size.width * .84, size.height * .65)
      ..lineTo(size.width * .72, size.height * .88)
      ..quadraticBezierTo(
        size.width * .52,
        size.height * 1.02,
        size.width * .31,
        size.height * .86,
      )
      ..close();

    canvas.drawPath(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cyan, blue, royal],
        ).createShader(rect),
    );

    canvas.drawPath(
      middle,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [cyan, royal, deep],
        ).createShader(rect),
    );

    canvas.drawPath(
      arrow,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [cyan, blue, royal],
        ).createShader(rect),
    );

    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: .48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .018
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(top, edgePaint)
      ..drawPath(middle, edgePaint)
      ..drawPath(arrow, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _TondroRibbonPainter oldDelegate) => false;
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
