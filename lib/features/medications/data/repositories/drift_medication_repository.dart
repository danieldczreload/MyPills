import 'dart:async';

import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/data/db/medications_dao.dart';
import 'package:my_pills/features/medications/data/mappers/medication_mapper.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';

class DriftMedicationRepository implements MedicationRepository {
  DriftMedicationRepository(AppDatabase db) : _dao = db.medicationDao;

  final MedicationDao _dao;

  @override
  Future<Result<List<Medication>>> getAll() async {
    try {
      final rows = await _dao.getAllMedications();
      return Result.success(
        rows.map(toMedicationEntity).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Stream<Result<List<Medication>>> watchAll() {
    return Stream<Result<List<Medication>>>.multi((controller) {
      final subscription = _dao.watchAllMedications().listen(
        (rows) {
          try {
            controller.add(
              Result.success(
                rows.map(toMedicationEntity).toList(growable: false),
              ),
            );
          } on Object catch (error, stackTrace) {
            controller.add(
              Result.failure(
                Failure.unexpected(error: error, stackTrace: stackTrace),
              ),
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          controller.add(
            Result.failure(
              Failure.unexpected(error: error, stackTrace: stackTrace),
            ),
          );
        },
        onDone: controller.close,
      );

      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<Result<Medication>> getById(int id) async {
    try {
      final row = await _dao.getMedicationById(id);
      if (row == null) {
        return const Result.failure(Failure.notFound());
      }
      return Result.success(toMedicationEntity(row));
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<Medication>> add(Medication medication) async {
    try {
      final id = await _dao.insertMedication(
        toMedicationInsertCompanion(medication),
      );
      final row = await _dao.getMedicationById(id);
      if (row == null) {
        return Result.failure(
          Failure.unexpected(
            error: StateError('Inserted medication not found'),
          ),
        );
      }
      return Result.success(toMedicationEntity(row));
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<Medication>> update(Medication medication) async {
    try {
      final changed = await _dao.updateMedication(toMedicationRow(medication));
      if (!changed) {
        return const Result.failure(Failure.notFound());
      }
      final row = await _dao.getMedicationById(medication.id);
      if (row == null) {
        return const Result.failure(Failure.notFound());
      }
      return Result.success(toMedicationEntity(row));
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      final deleted = await _dao.deleteMedicationById(id);
      if (deleted == 0) {
        return const Result.failure(Failure.notFound());
      }
      return const Result<void>.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }
}
