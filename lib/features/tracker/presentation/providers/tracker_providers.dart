import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

final StreamProvider<Result<List<DoseEvent>>> todayDosesProvider =
    StreamProvider.autoDispose<Result<List<DoseEvent>>>((ref) {
      final watchToday = ref.watch(watchTodayDosesUseCaseProvider);
      return watchToday();
    });

final FutureProvider<int> streakProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(doseEventRepositoryProvider);
  final result = await repository.calculateStreak();
  return switch (result) {
    Success(:final value) => value,
    FailureResult() => 0,
  };
});

final FutureProvider<double> adherenceProvider = FutureProvider<double>((
  ref,
) async {
  final repository = ref.watch(doseEventRepositoryProvider);
  final result = await repository.calculateAdherence();
  return switch (result) {
    Success(:final value) => value,
    FailureResult() => 100.0,
  };
});
