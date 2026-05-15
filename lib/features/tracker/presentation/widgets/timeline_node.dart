import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

class TimelineNode extends StatelessWidget {
  const TimelineNode({
    required this.status,
    required this.isFirst,
    required this.isLast,
    required this.child,
    super.key,
  });

  final DoseStatus status;
  final bool isFirst;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: CustomPaint(
              painter: _TimelinePainter(
                status: status,
                isFirst: isFirst,
                isLast: isLast,
                lineColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.5,
                ),
                theme: theme,
              ),
            ),
          ),
          SizedBox(width: serene.spacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.status,
    required this.isFirst,
    required this.isLast,
    required this.lineColor,
    required this.theme,
  });

  final DoseStatus status;
  final bool isFirst;
  final bool isLast;
  final Color lineColor;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    // Align circle to the top with a padding matching the card's visual padding, let's say 32px from top.
    const circleCenterY = 32.0;

    // Draw top line
    if (!isFirst) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, circleCenterY - 20),
        paint,
      );
    }

    // Draw bottom line
    if (!isLast) {
      canvas.drawLine(
        Offset(centerX, circleCenterY + 20),
        Offset(centerX, size.height),
        paint,
      );
    }

    // Draw circle
    final circlePaint = Paint()..style = PaintingStyle.fill;
    switch (status) {
      case DoseStatus.taken:
        circlePaint.color = theme.colorScheme.secondaryContainer.withValues(
          alpha: 0.5,
        );
      case DoseStatus.pending:
        circlePaint.color = theme.colorScheme.primary;
      case DoseStatus.missed:
        // Using surfaceContainerHighest for scheduled/missed for now.
        circlePaint.color = theme.colorScheme.surfaceContainerHighest;
    }

    canvas.drawCircle(Offset(centerX, circleCenterY), 20, circlePaint);

    // Draw Icon inside circle
    IconData iconData;
    Color iconColor;
    switch (status) {
      case DoseStatus.taken:
        iconData = Icons.check_circle;
        iconColor = theme.colorScheme.secondary;
      case DoseStatus.pending:
        iconData = Icons.ssid_chart;
        iconColor = theme.colorScheme.onPrimary;
      case DoseStatus.missed:
        iconData = Icons.schedule;
        iconColor = theme.colorScheme.onSurfaceVariant;
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 20,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: iconColor,
        ),
      ),
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        circleCenterY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.theme != theme;
  }
}
