import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';

final StreamProvider<Result<List<Medication>>> medicationsStreamProvider =
    StreamProvider.autoDispose<Result<List<Medication>>>((ref) {
      final watchMedications = ref.watch(watchMedicationsUseCaseProvider);
      return watchMedications();
    });
