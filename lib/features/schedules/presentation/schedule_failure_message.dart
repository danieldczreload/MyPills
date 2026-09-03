import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/l10n/app_localizations.dart';

String scheduleFailureMessage(AppLocalizations l10n, Failure failure) {
  if (failure is Validation) {
    return switch (failure.code) {
      ValidationCode.doseRequired => l10n.errorDoseRequired,
      ValidationCode.invalidDoseAmount => l10n.errorInvalidDoseAmount,
      ValidationCode.invalidDoseUnit => l10n.errorInvalidDoseUnit,
      _ => l10n.errorUnexpected,
    };
  }
  return l10n.errorUnexpected;
}
