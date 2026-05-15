import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Application title shown in the app bar.
  ///
  /// In es, this message translates to:
  /// **'MyPills'**
  String get appTitle;

  /// Bottom nav label — Today/Tracker tab.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get navToday;

  /// Bottom nav label — Medications tab.
  ///
  /// In es, this message translates to:
  /// **'Medicamentos'**
  String get navMedications;

  /// Bottom nav label — Categories tab.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get navCategories;

  /// Morning greeting on the Home/Tracker screen.
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get homeGreetingMorning;

  /// Afternoon greeting on the Home/Tracker screen.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get homeGreetingAfternoon;

  /// Evening greeting on the Home/Tracker screen.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get homeGreetingEvening;

  /// Section header on the tracker screen.
  ///
  /// In es, this message translates to:
  /// **'Dosis de hoy'**
  String get todayDosesTitle;

  /// Chip label — dose has been taken.
  ///
  /// In es, this message translates to:
  /// **'Tomado'**
  String get doseStatusTaken;

  /// Chip label — dose is pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get doseStatusPending;

  /// Chip label — dose was missed (use amber, never red).
  ///
  /// In es, this message translates to:
  /// **'Omitido'**
  String get doseStatusMissed;

  /// Primary CTA to mark a dose as taken.
  ///
  /// In es, this message translates to:
  /// **'Marcar como tomado'**
  String get markTakenButton;

  /// Screen title for the medication catalog.
  ///
  /// In es, this message translates to:
  /// **'Mis medicamentos'**
  String get medicationsTitle;

  /// FAB / button label to add a new medication.
  ///
  /// In es, this message translates to:
  /// **'Agregar medicamento'**
  String get addMedicationButton;

  /// Screen title for the daily scheduler.
  ///
  /// In es, this message translates to:
  /// **'Horario diario'**
  String get schedulerDailyTitle;

  /// Screen title for the specific-days scheduler.
  ///
  /// In es, this message translates to:
  /// **'Días específicos'**
  String get schedulerSpecificDaysTitle;

  /// Screen title for the timeline.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get timelineTitle;

  /// Generic unexpected-error message.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado'**
  String get errorUnexpected;

  /// Not-found error message.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el recurso solicitado'**
  String get errorNotFound;

  /// Pluralised dose counter.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin dosis} =1{1 dosis} other{{count} dosis}}'**
  String doseCount(int count);

  /// Header subtitle showing pending dose count on tracker.
  ///
  /// In es, this message translates to:
  /// **'Tienes {count} tomas pendientes para hoy. Sigue así.'**
  String todayPendingDosesMessage(int count);

  /// Empty state message on today tracker.
  ///
  /// In es, this message translates to:
  /// **'No hay dosis programadas para hoy'**
  String get emptyTodayDoses;

  /// Empty state message for medication catalog.
  ///
  /// In es, this message translates to:
  /// **'Aún no has agregado medicamentos'**
  String get emptyMedications;

  /// Fallback label when medication name cannot be resolved.
  ///
  /// In es, this message translates to:
  /// **'Medicamento'**
  String get unknownMedication;

  /// Secondary action to mark a dose as missed.
  ///
  /// In es, this message translates to:
  /// **'Marcar como omitido'**
  String get markMissedButton;

  /// Generic save action.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get saveButton;

  /// Generic cancel action.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelButton;

  /// Input label for medication name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nameLabel;

  /// Input label for medication category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get categoryLabel;

  /// Input label for optional notes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notesLabel;

  /// Input label for medication physical form.
  ///
  /// In es, this message translates to:
  /// **'Forma'**
  String get medicationFormLabel;

  /// Input label for schedule start date.
  ///
  /// In es, this message translates to:
  /// **'Fecha de inicio'**
  String get startDateLabel;

  /// Input label for schedule end date.
  ///
  /// In es, this message translates to:
  /// **'Fecha de fin'**
  String get endDateLabel;

  /// Generic time label.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get timeLabel;

  /// Button to add another time-of-day in scheduler.
  ///
  /// In es, this message translates to:
  /// **'Agregar hora'**
  String get addTimeButton;

  /// Primary action to create a schedule.
  ///
  /// In es, this message translates to:
  /// **'Crear horario'**
  String get createScheduleButton;

  /// Input label for medication picker in schedulers.
  ///
  /// In es, this message translates to:
  /// **'Medicamento'**
  String get selectMedicationLabel;

  /// Message shown when trying to schedule without medications.
  ///
  /// In es, this message translates to:
  /// **'Agrega un medicamento antes de crear un horario'**
  String get noMedicationsForSchedule;

  /// Timeline range title for default window.
  ///
  /// In es, this message translates to:
  /// **'Últimos 7 días'**
  String get timelineWindowTitle;

  /// Medication form label for pill.
  ///
  /// In es, this message translates to:
  /// **'Tableta'**
  String get medicationFormPill;

  /// Medication form label for capsule.
  ///
  /// In es, this message translates to:
  /// **'Cápsula'**
  String get medicationFormCapsule;

  /// Medication form label for liquid.
  ///
  /// In es, this message translates to:
  /// **'Líquido'**
  String get medicationFormLiquid;

  /// Medication form label for injection.
  ///
  /// In es, this message translates to:
  /// **'Inyección'**
  String get medicationFormInjection;

  /// Medication form label for drops.
  ///
  /// In es, this message translates to:
  /// **'Gotas'**
  String get medicationFormDrops;

  /// Medication form label for inhaler.
  ///
  /// In es, this message translates to:
  /// **'Inhalador'**
  String get medicationFormInhaler;

  /// Medication form label for patch.
  ///
  /// In es, this message translates to:
  /// **'Parche'**
  String get medicationFormPatch;

  /// Medication form label for other.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get medicationFormOther;

  /// Short label for Monday.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get dayMon;

  /// Short label for Tuesday.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get dayTue;

  /// Short label for Wednesday.
  ///
  /// In es, this message translates to:
  /// **'X'**
  String get dayWed;

  /// Short label for Thursday.
  ///
  /// In es, this message translates to:
  /// **'J'**
  String get dayThu;

  /// Short label for Friday.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get dayFri;

  /// Short label for Saturday.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get daySat;

  /// Short label for Sunday.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get daySun;

  /// Input label for medication color token.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get colorTokenLabel;

  /// Color token option: primary.
  ///
  /// In es, this message translates to:
  /// **'Principal'**
  String get colorTokenPrimary;

  /// Color token option: secondary.
  ///
  /// In es, this message translates to:
  /// **'Secundario'**
  String get colorTokenSecondary;

  /// Color token option: tertiary.
  ///
  /// In es, this message translates to:
  /// **'Terciario'**
  String get colorTokenTertiary;

  /// No description provided for @brandSanctuary.
  ///
  /// In es, this message translates to:
  /// **'Sanctuary'**
  String get brandSanctuary;

  /// No description provided for @schedulerHeading.
  ///
  /// In es, this message translates to:
  /// **'Programa tu medicación'**
  String get schedulerHeading;

  /// No description provided for @schedulerSubheading.
  ///
  /// In es, this message translates to:
  /// **'La precisión es clave para tu recuperación. Define cómo y cuándo tomar tu dosis.'**
  String get schedulerSubheading;

  /// No description provided for @recurrenceTitle.
  ///
  /// In es, this message translates to:
  /// **'Recurrencia'**
  String get recurrenceTitle;

  /// No description provided for @recurrenceDaily.
  ///
  /// In es, this message translates to:
  /// **'Diaria'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceDailyDesc.
  ///
  /// In es, this message translates to:
  /// **'Cada día, ritmo regular'**
  String get recurrenceDailyDesc;

  /// No description provided for @recurrenceSpecificDays.
  ///
  /// In es, this message translates to:
  /// **'Días específicos'**
  String get recurrenceSpecificDays;

  /// No description provided for @recurrenceSpecificDaysDesc.
  ///
  /// In es, this message translates to:
  /// **'Selecciona días de la semana'**
  String get recurrenceSpecificDaysDesc;

  /// No description provided for @durationTitle.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get durationTitle;

  /// No description provided for @durationContinuous.
  ///
  /// In es, this message translates to:
  /// **'Continuo'**
  String get durationContinuous;

  /// No description provided for @durationContinuousDesc.
  ///
  /// In es, this message translates to:
  /// **'Tratamiento continuo sin fecha de fin.'**
  String get durationContinuousDesc;

  /// No description provided for @durationSpecificEnd.
  ///
  /// In es, this message translates to:
  /// **'Fecha de fin específica'**
  String get durationSpecificEnd;

  /// No description provided for @durationSpecificEndDesc.
  ///
  /// In es, this message translates to:
  /// **'Establece una fecha fija para detener la medicación.'**
  String get durationSpecificEndDesc;

  /// No description provided for @schedulerStepLabel.
  ///
  /// In es, this message translates to:
  /// **'Paso 2 de 3'**
  String get schedulerStepLabel;

  /// No description provided for @frequencyModeTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo de frecuencia'**
  String get frequencyModeTitle;

  /// No description provided for @frequencyModeSetTimes.
  ///
  /// In es, this message translates to:
  /// **'Establecer horas'**
  String get frequencyModeSetTimes;

  /// No description provided for @frequencyModeInterval.
  ///
  /// In es, this message translates to:
  /// **'Intervalo'**
  String get frequencyModeInterval;

  /// No description provided for @doseLabel.
  ///
  /// In es, this message translates to:
  /// **'Dosis {number}'**
  String doseLabel(int number);

  /// No description provided for @confirmScheduleButton.
  ///
  /// In es, this message translates to:
  /// **'Confirmar horario'**
  String get confirmScheduleButton;

  /// No description provided for @trackerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tienes {count} dosis restantes para hoy. Sigue así.'**
  String trackerSubtitle(int count);

  /// No description provided for @trackerUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get trackerUpcoming;

  /// No description provided for @trackerScheduled.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get trackerScheduled;

  /// No description provided for @trackerMissedAlert.
  ///
  /// In es, this message translates to:
  /// **'VENCIDA'**
  String get trackerMissedAlert;

  /// No description provided for @trackerLogAsTaken.
  ///
  /// In es, this message translates to:
  /// **'Registrar como tomado'**
  String get trackerLogAsTaken;

  /// No description provided for @trackerStreak.
  ///
  /// In es, this message translates to:
  /// **'RACHA'**
  String get trackerStreak;

  /// No description provided for @trackerAdherence.
  ///
  /// In es, this message translates to:
  /// **'ADHERENCIA'**
  String get trackerAdherence;

  /// No description provided for @trackerDays.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get trackerDays;

  /// No description provided for @trackerWeekly.
  ///
  /// In es, this message translates to:
  /// **'semanal'**
  String get trackerWeekly;

  /// No description provided for @trackerStreakTooltip.
  ///
  /// In es, this message translates to:
  /// **'Días consecutivos en los que has tomado todas tus dosis'**
  String get trackerStreakTooltip;

  /// No description provided for @trackerAdherenceTooltip.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje de dosis tomadas en los últimos 7 días'**
  String get trackerAdherenceTooltip;

  /// No description provided for @taxonomyTitle.
  ///
  /// In es, this message translates to:
  /// **'Taxonomía de Medicamentos'**
  String get taxonomyTitle;

  /// No description provided for @taxonomySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Organiza y filtra tu régimen de salud por condición médica o categoría funcional.'**
  String get taxonomySubtitle;

  /// No description provided for @searchGroupsPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar grupos...'**
  String get searchGroupsPlaceholder;

  /// No description provided for @segmentCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get segmentCategories;

  /// No description provided for @segmentDiseases.
  ///
  /// In es, this message translates to:
  /// **'Enfermedades'**
  String get segmentDiseases;

  /// No description provided for @createCategoryButton.
  ///
  /// In es, this message translates to:
  /// **'Crear Categoría'**
  String get createCategoryButton;

  /// No description provided for @itemsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @descriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get descriptionLabel;

  /// No description provided for @createDiseaseButton.
  ///
  /// In es, this message translates to:
  /// **'Crear Enfermedad'**
  String get createDiseaseButton;

  /// Step indicator on the add-medication wizard screen.
  ///
  /// In es, this message translates to:
  /// **'Paso 1 de 3'**
  String get addMedicationStepLabel;

  /// Main heading on the add-medication wizard screen.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu medicamento'**
  String get addMedicationHeading;

  /// Subheading on the add-medication wizard screen.
  ///
  /// In es, this message translates to:
  /// **'Completa los datos del medicamento antes de definir su horario.'**
  String get addMedicationSubheading;

  /// Inline button to create a new taxonomy category from the medication form.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get newCategoryButton;

  /// Button that advances to the next wizard step.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get nextButton;

  /// CTA button on the daily greeting screen.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get welcomeContinueButton;

  /// Label above the daily motivational quote card.
  ///
  /// In es, this message translates to:
  /// **'FRASE DEL DÍA'**
  String get welcomeQuoteOfTheDayLabel;

  /// Subtitle on the medication list screen.
  ///
  /// In es, this message translates to:
  /// **'Administra tu régimen de medicamentos'**
  String get medicationListSubtitle;

  /// Main heading on the edit-medication screen.
  ///
  /// In es, this message translates to:
  /// **'Editar medicamento'**
  String get editMedicationHeading;

  /// Subheading on the edit-medication screen.
  ///
  /// In es, this message translates to:
  /// **'Actualiza los datos de tu medicamento.'**
  String get editMedicationSubheading;

  /// Step indicator label on the edit-medication screen.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get editMedicationStepLabel;

  /// Title of the delete-medication confirmation dialog.
  ///
  /// In es, this message translates to:
  /// **'Eliminar medicamento'**
  String get deleteMedicationTitle;

  /// Body text of the delete-medication confirmation dialog.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de eliminar {name}? Se eliminarán también sus horarios y dosis programadas.'**
  String deleteMedicationConfirmation(String name);

  /// Destructive action label for delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteButton;

  /// Snackbar message after a medication is deleted.
  ///
  /// In es, this message translates to:
  /// **'Medicamento eliminado'**
  String get medicationDeletedMessage;

  /// Placeholder text for the medication search field.
  ///
  /// In es, this message translates to:
  /// **'Buscar medicamentos...'**
  String get searchMedicationsPlaceholder;

  /// No description provided for @onboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a MyPills'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos un poco sobre ti para personalizar tu experiencia'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingBirthDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get onboardingBirthDateLabel;

  /// No description provided for @onboardingGenderLabel.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get onboardingGenderLabel;

  /// No description provided for @onboardingGenderMale.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get onboardingGenderMale;

  /// No description provided for @onboardingGenderFemale.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get onboardingGenderFemale;

  /// No description provided for @onboardingGenderOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get onboardingGenderOther;

  /// No description provided for @onboardingPhotoPrompt.
  ///
  /// In es, this message translates to:
  /// **'Toca para agregar tu foto'**
  String get onboardingPhotoPrompt;

  /// No description provided for @onboardingPhotoCamera.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get onboardingPhotoCamera;

  /// No description provided for @onboardingPhotoGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get onboardingPhotoGallery;

  /// No description provided for @onboardingStartButton.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onboardingStartButton;

  /// No description provided for @editProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfileTitle;

  /// No description provided for @editProfileSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get editProfileSaveButton;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get editProfileChangePhoto;

  /// Button to skip optional wizard step and go to next screen.
  ///
  /// In es, this message translates to:
  /// **'Saltar por ahora'**
  String get skipForNowButton;

  /// Validation error when medication name is empty.
  ///
  /// In es, this message translates to:
  /// **'El nombre es requerido'**
  String get errorNameRequired;

  /// Validation error when no category is selected.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoría primero'**
  String get errorCategoryRequired;

  /// Section title listing active schedules for a medication.
  ///
  /// In es, this message translates to:
  /// **'Horarios activos'**
  String get activeSchedulesTitle;

  /// Empty state when a medication has no schedules.
  ///
  /// In es, this message translates to:
  /// **'Sin horarios configurados'**
  String get noSchedulesYet;

  /// Title of the delete-schedule confirmation dialog.
  ///
  /// In es, this message translates to:
  /// **'Eliminar horario'**
  String get deleteScheduleTitle;

  /// Body text of the delete-schedule confirmation dialog.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este horario? Las dosis futuras se cancelarán.'**
  String get deleteScheduleConfirmation;

  /// Snackbar message after a schedule is deleted.
  ///
  /// In es, this message translates to:
  /// **'Horario eliminado'**
  String get scheduleDeletedMessage;

  /// Button to add a new schedule for a medication.
  ///
  /// In es, this message translates to:
  /// **'Agregar horario'**
  String get addScheduleButton;

  /// Hint shown above past-day content; scroll up to reveal more.
  ///
  /// In es, this message translates to:
  /// **'↑ Días anteriores'**
  String get trackerScrollPastHint;

  /// Hint shown below future-day content; scroll down to reveal more.
  ///
  /// In es, this message translates to:
  /// **'↓ Días próximos'**
  String get trackerScrollFutureHint;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @settingsProfileSection.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get settingsProfileSection;

  /// No description provided for @settingsInAppRemindersSection.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios en la app'**
  String get settingsInAppRemindersSection;

  /// No description provided for @settingsInAppRemindersToggle.
  ///
  /// In es, this message translates to:
  /// **'Banners de recordatorio'**
  String get settingsInAppRemindersToggle;

  /// No description provided for @settingsInAppRemindersDesc.
  ///
  /// In es, this message translates to:
  /// **'Mostrar un aviso en pantalla cuando sea hora de tu dosis y la app esté abierta.'**
  String get settingsInAppRemindersDesc;

  /// No description provided for @settingsPushNotificationsSection.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones Push'**
  String get settingsPushNotificationsSection;

  /// No description provided for @settingsPushNotificationsToggle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones del sistema'**
  String get settingsPushNotificationsToggle;

  /// No description provided for @settingsPushNotificationsDesc.
  ///
  /// In es, this message translates to:
  /// **'Recibir alertas incluso cuando la app esté cerrada.'**
  String get settingsPushNotificationsDesc;

  /// No description provided for @settingsAnticipationLabel.
  ///
  /// In es, this message translates to:
  /// **'Avisar con anticipación'**
  String get settingsAnticipationLabel;

  /// No description provided for @settingsAnticipationExact.
  ///
  /// In es, this message translates to:
  /// **'Hora exacta'**
  String get settingsAnticipationExact;

  /// No description provided for @settingsAnticipationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min antes'**
  String settingsAnticipationMinutes(int minutes);

  /// No description provided for @settingsPermissionButton.
  ///
  /// In es, this message translates to:
  /// **'Otorgar permiso'**
  String get settingsPermissionButton;

  /// No description provided for @settingsCalendarSection.
  ///
  /// In es, this message translates to:
  /// **'Calendario del dispositivo'**
  String get settingsCalendarSection;

  /// No description provided for @settingsCalendarToggle.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar calendario'**
  String get settingsCalendarToggle;

  /// No description provided for @settingsCalendarDesc.
  ///
  /// In es, this message translates to:
  /// **'Agrega automáticamente tus dosis al calendario de tu teléfono (Google/Outlook).'**
  String get settingsCalendarDesc;

  /// No description provided for @settingsComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get settingsComingSoon;

  /// No description provided for @settingsCalendarSelectTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar calendario destino'**
  String get settingsCalendarSelectTitle;

  /// No description provided for @settingsCalendarPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Permiso denegado. Habilita el acceso al calendario en los ajustes del sistema.'**
  String get settingsCalendarPermissionDenied;

  /// No description provided for @notificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Hora de tu medicación'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In es, this message translates to:
  /// **'Es hora de tomar {medicationName}'**
  String notificationBody(String medicationName);

  /// No description provided for @inAppReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get inAppReminderTitle;

  /// No description provided for @inAppReminderDismiss.
  ///
  /// In es, this message translates to:
  /// **'Desliza para ocultar'**
  String get inAppReminderDismiss;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
