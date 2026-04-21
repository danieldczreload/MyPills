// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MyPills';

  @override
  String get navToday => 'Hoy';

  @override
  String get navMedications => 'Medicamentos';

  @override
  String get navTimeline => 'Historial';

  @override
  String get homeGreetingMorning => 'Buenos días';

  @override
  String get homeGreetingAfternoon => 'Buenas tardes';

  @override
  String get homeGreetingEvening => 'Buenas noches';

  @override
  String get todayDosesTitle => 'Dosis de hoy';

  @override
  String get doseStatusTaken => 'Tomado';

  @override
  String get doseStatusPending => 'Pendiente';

  @override
  String get doseStatusMissed => 'Omitido';

  @override
  String get markTakenButton => 'Marcar como tomado';

  @override
  String get medicationsTitle => 'Mis medicamentos';

  @override
  String get addMedicationButton => 'Agregar medicamento';

  @override
  String get schedulerDailyTitle => 'Horario diario';

  @override
  String get schedulerSpecificDaysTitle => 'Días específicos';

  @override
  String get timelineTitle => 'Historial';

  @override
  String get errorUnexpected => 'Ocurrió un error inesperado';

  @override
  String get errorNotFound => 'No se encontró el recurso solicitado';

  @override
  String doseCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosis',
      one: '1 dosis',
      zero: 'Sin dosis',
    );
    return '$_temp0';
  }
}
