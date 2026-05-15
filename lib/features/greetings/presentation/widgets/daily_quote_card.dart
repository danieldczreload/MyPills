import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/greetings/domain/entities/daily_quote.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({required this.quote, super.key});

  final DailyQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: serene.radius.lg,
      ),
      child: Padding(
        padding: EdgeInsets.all(serene.spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.welcomeQuoteOfTheDayLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.70),
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: serene.spacing.sm),
            Text(
              '“${quote.text}”',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            if (quote.author != null) ...[
              SizedBox(height: serene.spacing.sm),
              Text(
                '— ${quote.author}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
