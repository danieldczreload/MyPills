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
  String get navCategories => 'Categorías';

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

  @override
  String todayPendingDosesMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Tienes $countString tomas pendientes para hoy. Sigue así.';
  }

  @override
  String get emptyTodayDoses => 'No hay dosis programadas para hoy';

  @override
  String get emptyMedications => 'Aún no has agregado medicamentos';

  @override
  String get unknownMedication => 'Medicamento';

  @override
  String get markMissedButton => 'Marcar como omitido';

  @override
  String get saveButton => 'Guardar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get notesLabel => 'Notas';

  @override
  String get medicationFormLabel => 'Forma';

  @override
  String get startDateLabel => 'Fecha de inicio';

  @override
  String get endDateLabel => 'Fecha de fin';

  @override
  String get timeLabel => 'Hora';

  @override
  String get addTimeButton => 'Agregar hora';

  @override
  String get createScheduleButton => 'Crear horario';

  @override
  String get selectMedicationLabel => 'Medicamento';

  @override
  String get noMedicationsForSchedule =>
      'Agrega un medicamento antes de crear un horario';

  @override
  String get timelineWindowTitle => 'Últimos 7 días';

  @override
  String get medicationFormPill => 'Tableta';

  @override
  String get medicationFormCapsule => 'Cápsula';

  @override
  String get medicationFormLiquid => 'Líquido';

  @override
  String get medicationFormInjection => 'Inyección';

  @override
  String get medicationFormDrops => 'Gotas';

  @override
  String get medicationFormInhaler => 'Inhalador';

  @override
  String get medicationFormPatch => 'Parche';

  @override
  String get medicationFormOther => 'Otro';

  @override
  String get dayMon => 'L';

  @override
  String get dayTue => 'M';

  @override
  String get dayWed => 'X';

  @override
  String get dayThu => 'J';

  @override
  String get dayFri => 'V';

  @override
  String get daySat => 'S';

  @override
  String get daySun => 'D';

  @override
  String get colorTokenLabel => 'Color';

  @override
  String get colorTokenPrimary => 'Principal';

  @override
  String get colorTokenSecondary => 'Secundario';

  @override
  String get colorTokenTertiary => 'Terciario';

  @override
  String get brandSanctuary => 'Sanctuary';

  @override
  String get schedulerHeading => 'Programa tu medicación';

  @override
  String get schedulerSubheading =>
      'La precisión es clave para tu recuperación. Define cómo y cuándo tomar tu dosis.';

  @override
  String get recurrenceTitle => 'Recurrencia';

  @override
  String get recurrenceDaily => 'Diaria';

  @override
  String get recurrenceDailyDesc => 'Cada día, ritmo regular';

  @override
  String get recurrenceSpecificDays => 'Días específicos';

  @override
  String get recurrenceSpecificDaysDesc => 'Selecciona días de la semana';

  @override
  String get durationTitle => 'Duración';

  @override
  String get durationContinuous => 'Continuo';

  @override
  String get durationContinuousDesc => 'Tratamiento continuo sin fecha de fin.';

  @override
  String get durationSpecificEnd => 'Fecha de fin específica';

  @override
  String get durationSpecificEndDesc =>
      'Establece una fecha fija para detener la medicación.';

  @override
  String get schedulerStepLabel => 'Paso 2 de 3';

  @override
  String get frequencyModeTitle => 'Modo de frecuencia';

  @override
  String get frequencyModeSetTimes => 'Establecer horas';

  @override
  String get frequencyModeInterval => 'Intervalo';

  @override
  String doseLabel(int number) {
    return 'Dosis $number';
  }

  @override
  String get confirmScheduleButton => 'Confirmar horario';

  @override
  String trackerSubtitle(int count) {
    return 'Tienes $count dosis restantes para hoy. Sigue así.';
  }

  @override
  String get trackerUpcoming => 'Próximo';

  @override
  String get trackerScheduled => 'Programado';

  @override
  String get trackerMissedAlert => 'VENCIDA';

  @override
  String get trackerLogAsTaken => 'Registrar como tomado';

  @override
  String get trackerStreak => 'RACHA';

  @override
  String get trackerAdherence => 'ADHERENCIA';

  @override
  String get trackerDays => 'días';

  @override
  String get trackerWeekly => 'semanal';

  @override
  String get trackerStreakTooltip =>
      'Días consecutivos en los que has tomado todas tus dosis';

  @override
  String get trackerAdherenceTooltip =>
      'Porcentaje de dosis tomadas en los últimos 7 días';

  @override
  String get taxonomyTitle => 'Taxonomía de Medicamentos';

  @override
  String get taxonomySubtitle =>
      'Organiza y filtra tu régimen de salud por condición médica o categoría funcional.';

  @override
  String get searchGroupsPlaceholder => 'Buscar grupos...';

  @override
  String get segmentCategories => 'Categorías';

  @override
  String get segmentDiseases => 'Enfermedades';

  @override
  String get createCategoryButton => 'Crear Categoría';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get createDiseaseButton => 'Crear Enfermedad';

  @override
  String get addMedicationStepLabel => 'Paso 1 de 3';

  @override
  String get addMedicationHeading => 'Agrega tu medicamento';

  @override
  String get addMedicationSubheading =>
      'Completa los datos del medicamento antes de definir su horario.';

  @override
  String get newCategoryButton => 'Nueva categoría';

  @override
  String get nextButton => 'Siguiente';

  @override
  String get welcomeContinueButton => 'Continuar';

  @override
  String get welcomeQuoteOfTheDayLabel => 'FRASE DEL DÍA';

  @override
  String get medicationListSubtitle => 'Administra tu régimen de medicamentos';

  @override
  String get editMedicationHeading => 'Editar medicamento';

  @override
  String get editMedicationSubheading =>
      'Actualiza los datos de tu medicamento.';

  @override
  String get editMedicationStepLabel => 'Editar';

  @override
  String get deleteMedicationTitle => 'Eliminar medicamento';

  @override
  String deleteMedicationConfirmation(String name) {
    return '¿Estás seguro de eliminar $name? Se eliminarán también sus horarios y dosis programadas.';
  }

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get medicationDeletedMessage => 'Medicamento eliminado';

  @override
  String get searchMedicationsPlaceholder => 'Buscar medicamentos...';

  @override
  String get onboardingTitle => 'Bienvenido a MyPills';

  @override
  String get onboardingSubtitle =>
      'Cuéntanos un poco sobre ti para personalizar tu experiencia';

  @override
  String get onboardingNameLabel => 'Tu nombre';

  @override
  String get onboardingBirthDateLabel => 'Fecha de nacimiento';

  @override
  String get onboardingGenderLabel => 'Género';

  @override
  String get onboardingGenderMale => 'Masculino';

  @override
  String get onboardingGenderFemale => 'Femenino';

  @override
  String get onboardingGenderOther => 'Otro';

  @override
  String get onboardingPhotoPrompt => 'Toca para agregar tu foto';

  @override
  String get onboardingPhotoCamera => 'Tomar foto';

  @override
  String get onboardingPhotoGallery => 'Elegir de la galería';

  @override
  String get onboardingStartButton => 'Comenzar';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get editProfileSaveButton => 'Guardar cambios';

  @override
  String get editProfileChangePhoto => 'Cambiar foto';

  @override
  String get skipForNowButton => 'Saltar por ahora';

  @override
  String get errorNameRequired => 'El nombre es requerido';

  @override
  String get errorCategoryRequired => 'Selecciona una categoría primero';

  @override
  String get activeSchedulesTitle => 'Horarios activos';

  @override
  String get noSchedulesYet => 'Sin horarios configurados';

  @override
  String get deleteScheduleTitle => 'Eliminar horario';

  @override
  String get deleteScheduleConfirmation =>
      '¿Eliminar este horario? Las dosis futuras se cancelarán.';

  @override
  String get scheduleDeletedMessage => 'Horario eliminado';

  @override
  String get addScheduleButton => 'Agregar horario';

  @override
  String get trackerScrollPastHint => '↑ Días anteriores';

  @override
  String get trackerScrollFutureHint => '↓ Días próximos';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsProfileSection => 'Perfil';

  @override
  String get settingsInAppRemindersSection => 'Recordatorios en la app';

  @override
  String get settingsInAppRemindersToggle => 'Banners de recordatorio';

  @override
  String get settingsInAppRemindersDesc =>
      'Mostrar un aviso en pantalla cuando sea hora de tu dosis y la app esté abierta.';

  @override
  String get settingsPushNotificationsSection => 'Notificaciones Push';

  @override
  String get settingsPushNotificationsToggle => 'Notificaciones del sistema';

  @override
  String get settingsPushNotificationsDesc =>
      'Recibir alertas incluso cuando la app esté cerrada.';

  @override
  String get settingsAnticipationLabel => 'Avisar con anticipación';

  @override
  String get settingsAnticipationExact => 'Hora exacta';

  @override
  String settingsAnticipationMinutes(int minutes) {
    return '$minutes min antes';
  }

  @override
  String get settingsPermissionButton => 'Otorgar permiso';

  @override
  String get settingsCalendarSection => 'Calendario del dispositivo';

  @override
  String get settingsCalendarToggle => 'Sincronizar calendario';

  @override
  String get settingsCalendarDesc =>
      'Agrega automáticamente tus dosis al calendario de tu teléfono (Google/Outlook).';

  @override
  String get settingsComingSoon => 'Próximamente';

  @override
  String get settingsCalendarSelectTitle => 'Seleccionar calendario destino';

  @override
  String get settingsCalendarPermissionDenied =>
      'Permiso denegado. Habilita el acceso al calendario en los ajustes del sistema.';

  @override
  String get notificationTitle => 'Hora de tu medicación';

  @override
  String notificationBody(String medicationName) {
    return 'Es hora de tomar $medicationName';
  }

  @override
  String get inAppReminderTitle => 'Recordatorio';

  @override
  String get inAppReminderDismiss => 'Desliza para ocultar';

  @override
  String get loginTitle => 'Bienvenido a MyPills';

  @override
  String get loginSubtitle =>
      'Sincroniza y respalda tus tratamientos médicos de forma segura en la nube.';

  @override
  String get loginContinueGoogle => 'Continuar con Google';

  @override
  String get loginContinueMicrosoft => 'Continuar con Microsoft';

  @override
  String get loginContinueGuest => 'Continuar en modo local (sin cuenta)';

  @override
  String get loginSyncingAccount => 'Sincronizando tu cuenta...';

  @override
  String loginErrorGoogle(String error) {
    return 'Error al iniciar sesión con Google: $error';
  }

  @override
  String loginErrorMicrosoft(String error) {
    return 'Error al iniciar sesión con Microsoft: $error';
  }

  @override
  String get settingsCloudSyncSection => 'Sincronización en la Nube';

  @override
  String get settingsCloudSyncLocalMode => 'Modo local (Sin cuenta)';

  @override
  String get settingsCloudSyncLocalModeDesc =>
      'Inicia sesión para sincronizar tus medicamentos.';

  @override
  String get settingsCloudSyncConnectButton => 'Conectar';

  @override
  String get settingsCloudSyncSyncButton => 'Sincronizar';

  @override
  String get settingsCloudSyncLogoutButton => 'Cerrar sesión';

  @override
  String get settingsCloudSyncSuccess => 'Sincronización completada';

  @override
  String get settingsCloudSyncLoggedOut => 'Sesión cerrada';

  @override
  String get greetingGenericWelcome =>
      'Bienvenido a tu espacio de salud. Mantén el control de tus medicamentos y dosis diarias.';

  @override
  String get cancelAlertTitle => 'Cancelar recordatorio';

  @override
  String cancelAlertSubtitle(String medication) {
    return '¿Qué deseas cancelar para $medication?';
  }

  @override
  String get cancelSingleAlertOption => 'Solo esta toma de hoy';

  @override
  String get cancelSingleAlertOptionDesc =>
      'Cancela la alerta y evento de calendario de esta dosis.';

  @override
  String get cancelRecurringAlertsOption => 'Todas las alertas de este horario';

  @override
  String get cancelRecurringAlertsOptionDesc =>
      'Cancela todas las alertas futuras y eventos en calendarios sincronizados.';

  @override
  String get singleAlertCancelledMessage => 'Alerta de hoy cancelada';

  @override
  String get recurringAlertsCancelledMessage =>
      'Alertas recurrentes canceladas';

  @override
  String get cancelRecurringTitle => 'Cancelar alertas recurrentes';

  @override
  String get cancelRecurringConfirmation =>
      '¿Deseas cancelar todas las alertas programadas y eventos en calendarios para este horario?';

  @override
  String get cancelRecurringButton => 'Cancelar alertas';

  @override
  String get profileSelectorHeading => 'Perfil';

  @override
  String get profileSelectorSubheading =>
      'Selecciona a qué perfil corresponde este recordatorio.';

  @override
  String profileBadgeLabel(String profileName) {
    return 'Para $profileName';
  }

  @override
  String inAppReminderTitleWithProfile(String profileName) {
    return 'Recordatorio para $profileName';
  }

  @override
  String notificationBodyWithProfile(String medication, String profileName) {
    return 'Es hora de tomar $medication ($profileName)';
  }
}
