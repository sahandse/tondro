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
      child: const CustomPaint(
        painter: _TondroRibbonPainter(),
      ),
    );
  }
}

class _TondroRibbonPainter extends CustomPainter {
  const _TondroRibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const cyan = Color(0xFF54E6FF);
    const blue = Color(0xFF1785FF);
    const royal = Color(0xFF2356F6);

    final stem = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .43,
        size.height * .14,
        size.width * .14,
        size.height * .43,
      ),
      Radius.circular(size.width * .07),
    );

    canvas.drawRRect(
      stem,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cyan, blue],
        ).createShader(rect),
    );

    final arrow = Path()
      ..moveTo(size.width * .22, size.height * .49)
      ..quadraticBezierTo(
        size.width * .20,
        size.height * .46,
        size.width * .25,
        size.height * .46,
      )
      ..lineTo(size.width * .43, size.height * .46)
      ..lineTo(size.width * .43, size.height * .56)
      ..lineTo(size.width * .50, size.height * .63)
      ..lineTo(size.width * .57, size.height * .56)
      ..lineTo(size.width * .57, size.height * .46)
      ..lineTo(size.width * .75, size.height * .46)
      ..quadraticBezierTo(
        size.width * .80,
        size.height * .46,
        size.width * .78,
        size.height * .49,
      )
      ..lineTo(size.width * .54, size.height * .76)
      ..quadraticBezierTo(
        size.width * .50,
        size.height * .81,
        size.width * .46,
        size.height * .76,
      )
      ..close();

    canvas.drawPath(
      arrow,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cyan, blue, royal],
        ).createShader(rect),
    );

    final trayPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [blue, royal],
      ).createShader(rect)
      ..strokeWidth = size.width * .105
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * .31, size.height * .87),
      Offset(size.width * .69, size.height * .87),
      trayPaint,
    );
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
