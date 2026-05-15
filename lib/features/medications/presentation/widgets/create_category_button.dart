import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';
import 'package:my_pills/features/medications/presentation/widgets/create_taxonomy_sheet.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class CreateCategoryButton extends StatelessWidget {
  const CreateCategoryButton({required this.type, super.key});

  final TaxonomyType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CreateTaxonomySheet(type: type),
        );
      },
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          radius: serene.radius.lg.topLeft.x,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: serene.spacing.xxl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.3),
            borderRadius: serene.radius.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(serene.spacing.md),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: theme.colorScheme.primary),
              ),
              SizedBox(height: serene.spacing.md),
              Text(
                type == TaxonomyType.category
                    ? l10n.createCategoryButton
                    : l10n.createDiseaseButton,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final dashPath = _dashPath(
      path,
      dashArray: _CircularIntervalList<double>([8, 6]),
    );
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;

  Path _dashPath(
    Path source, {
    required _CircularIntervalList<double> dashArray,
  }) {
    final dest = Path();
    for (final metric in source.computeRemainingMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = dashArray.next;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }
}

class _CircularIntervalList<T> {
  _CircularIntervalList(this._vals);
  final List<T> _vals;
  int _idx = 0;
  T get next => _vals[_idx++ % _vals.length];
}

extension on Path {
  Iterable<PathMetric> computeRemainingMetrics() => computeMetrics();
}
