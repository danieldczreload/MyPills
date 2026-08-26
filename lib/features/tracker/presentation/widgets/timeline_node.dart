import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

class TimelineNode extends StatelessWidget {
  const TimelineNode({
    required this.status,
    required this.isFirst,
    required this.isLast,
    required this.child,
    this.medicationIcon,
    this.medicationColor,
    super.key,
  });

  final DoseStatus status;
  final bool isFirst;
  final bool isLast;
  final IconData? medicationIcon;
  final Color? medicationColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final effectiveColor = medicationColor ?? theme.colorScheme.primary;
    final effectiveIcon = medicationIcon ?? Icons.medication_rounded;

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
                medicationIcon: effectiveIcon,
                medicationColor: effectiveColor,
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
    required this.medicationIcon,
    required this.medicationColor,
    required this.theme,
  });

  final DoseStatus status;
  final bool isFirst;
  final bool isLast;
  final Color lineColor;
  final IconData medicationIcon;
  final Color medicationColor;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;

    final centerX = size.width / 2;
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

    // Draw circle background & border
    final circlePaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Color iconColor;
    switch (status) {
      case DoseStatus.taken:
        circlePaint.color = theme.colorScheme.secondaryContainer.withValues(
          alpha: 0.35,
        );
        borderPaint.color = theme.colorScheme.secondary;
        iconColor = theme.colorScheme.secondary;
      case DoseStatus.pending:
        circlePaint.color = medicationColor.withValues(alpha: 0.15);
        borderPaint.color = medicationColor;
        iconColor = medicationColor;
      case DoseStatus.missed:
        circlePaint.color = theme.colorScheme.errorContainer.withValues(
          alpha: 0.25,
        );
        borderPaint.color = theme.colorScheme.error;
        iconColor = theme.colorScheme.error;
    }

    canvas.drawCircle(Offset(centerX, circleCenterY), 20, circlePaint);
    canvas.drawCircle(Offset(centerX, circleCenterY), 20, borderPaint);

    // Draw medication form icon inside circle
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(medicationIcon.codePoint),
        style: TextStyle(
          fontSize: 20,
          fontFamily: medicationIcon.fontFamily,
          package: medicationIcon.fontPackage,
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

    // If taken, draw a small check badge at the bottom-right of the circle
    if (status == DoseStatus.taken) {
      final badgeCenter = Offset(centerX + 13, circleCenterY + 13);
      final badgeBgPaint = Paint()
        ..color = theme.colorScheme.secondary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(badgeCenter, 7, badgeBgPaint);

      final checkPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(Icons.check.codePoint),
          style: TextStyle(
            fontSize: 10,
            fontFamily: Icons.check.fontFamily,
            package: Icons.check.fontPackage,
            color: theme.colorScheme.onSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      )..layout();

      checkPainter.paint(
        canvas,
        Offset(
          badgeCenter.dx - checkPainter.width / 2,
          badgeCenter.dy - checkPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.medicationIcon != medicationIcon ||
        oldDelegate.medicationColor != medicationColor ||
        oldDelegate.theme != theme;
  }
}
