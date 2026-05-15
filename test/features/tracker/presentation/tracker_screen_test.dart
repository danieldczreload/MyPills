import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/app_theme.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/timeline/presentation/providers/timeline_providers.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/domain/use_cases/mark_dose_missed.dart';
import 'package:my_pills/features/tracker/domain/use_cases/mark_dose_taken.dart';
import 'package:my_pills/features/tracker/presentation/providers/tracker_providers.dart';
import 'package:my_pills/features/tracker/presentation/tracker_screen.dart';
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockDoseEventRepository mockDoseEventRepository;
  late SharedPreferences testPrefs;

  setUpAll(registerFallbackValues);

  setUp(() async {
    mockDoseEventRepository = MockDoseEventRepository();
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
  });

  Widget buildTestableTracker({
    required List<DoseEvent> doses,
    required List<Medication> medications,
    DateTime? fixedClock,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(testPrefs),
        timelineEventsProvider.overrideWith(
          (ref, range) => Stream.value(Result.success(doses)),
        ),
        medicationsStreamProvider.overrideWith(
          (ref) => Stream.value(Result.success(medications)),
        ),
        clockProvider.overrideWith(
          (ref) => fixedClock ?? DateTime(2024, 6, 15),
        ),
        streakProvider.overrideWith((ref) async => 14),
        adherenceProvider.overrideWith((ref) async => 98.0),
        markDoseTakenUseCaseProvider.overrideWith(
          (ref) => MarkDoseTaken(
            mockDoseEventRepository,
            clock: () => DateTime(2024, 6, 15, 10),
          ),
        ),
        markDoseMissedUseCaseProvider.overrideWith(
          (ref) => MarkDoseMissed(mockDoseEventRepository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const Scaffold(body: TrackerScreen()),
      ),
    );
  }

  group('TrackerScreen', () {
    testWidgets('shows empty state when no doses', (tester) async {
      await tester.pumpWidget(
        buildTestableTracker(doses: [], medications: []),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay dosis programadas para hoy'), findsOneWidget);
    });

    testWidgets('renders pending doses with action buttons', (tester) async {
      final doses = [
        DoseEvent(
          id: 1,
          medicationId: 10,
          scheduleId: 100,
          scheduledAt: DateTime(2024, 6, 15, 8),
          status: DoseStatus.pending,
        ),
      ];
      final medications = [
        const Medication(
          id: 10,
          name: 'Paracetamol',
          form: MedicationForm.pill,
          category: 'Pain',
          colorToken: 'sky',
        ),
      ];

      await tester.pumpWidget(
        buildTestableTracker(doses: doses, medications: medications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paracetamol'), findsOneWidget);
      expect(find.text('Próximo • 8:00 AM'), findsOneWidget);
      expect(find.text('Registrar como tomado'), findsOneWidget);
    });

    testWidgets('renders taken dose without action buttons', (tester) async {
      final doses = [
        DoseEvent(
          id: 2,
          medicationId: 20,
          scheduleId: 200,
          scheduledAt: DateTime(2024, 6, 15, 14),
          status: DoseStatus.taken,
          takenAt: DateTime(2024, 6, 15, 14, 5),
        ),
      ];
      final medications = [
        const Medication(
          id: 20,
          name: 'Vitamina C',
          form: MedicationForm.capsule,
          category: 'Supplements',
          colorToken: 'amber',
        ),
      ];

      await tester.pumpWidget(
        buildTestableTracker(doses: doses, medications: medications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vitamina C'), findsOneWidget);
      expect(find.text('Tomado • 2:00 PM'), findsOneWidget);
      expect(find.text('Registrar como tomado'), findsNothing);
    });

    testWidgets('renders missed dose WITH action buttons', (tester) async {
      final doses = [
        DoseEvent(
          id: 3,
          medicationId: 30,
          scheduleId: 300,
          scheduledAt: DateTime(2024, 6, 15, 20),
          status: DoseStatus.missed,
        ),
      ];
      final medications = [
        const Medication(
          id: 30,
          name: 'Aspirina',
          form: MedicationForm.pill,
          category: 'General',
          colorToken: 'sage',
        ),
      ];

      await tester.pumpWidget(
        buildTestableTracker(doses: doses, medications: medications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aspirina'), findsOneWidget);
      expect(find.text('Registrar como tomado'), findsOneWidget);
    });

    testWidgets('tapping mark taken on missed dose calls use case', (
      tester,
    ) async {
      final doses = [
        DoseEvent(
          id: 3,
          medicationId: 30,
          scheduleId: 300,
          scheduledAt: DateTime(2024, 6, 15, 20),
          status: DoseStatus.missed,
        ),
      ];
      final medications = [
        const Medication(
          id: 30,
          name: 'Aspirina',
          form: MedicationForm.pill,
          category: 'General',
          colorToken: 'sage',
        ),
      ];

      when(() => mockDoseEventRepository.markTaken(3, any())).thenAnswer(
        (_) async => const Result.success(null),
      );

      await tester.pumpWidget(
        buildTestableTracker(doses: doses, medications: medications),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar como tomado'));
      await tester.pump();

      verify(() => mockDoseEventRepository.markTaken(3, any())).called(1);
    });

    testWidgets('tapping mark taken calls use case', (tester) async {
      final doses = [
        DoseEvent(
          id: 1,
          medicationId: 10,
          scheduleId: 100,
          scheduledAt: DateTime(2024, 6, 15, 8),
          status: DoseStatus.pending,
        ),
      ];
      final medications = [
        const Medication(
          id: 10,
          name: 'Paracetamol',
          form: MedicationForm.pill,
          category: 'Pain',
          colorToken: 'sky',
        ),
      ];

      when(() => mockDoseEventRepository.markTaken(1, any())).thenAnswer(
        (_) async => const Result.success(null),
      );

      await tester.pumpWidget(
        buildTestableTracker(doses: doses, medications: medications),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar como tomado'));
      await tester.pump();

      verify(() => mockDoseEventRepository.markTaken(1, any())).called(1);
    });
  });
}
