import 'package:flutter/services.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/greetings/data/assets_quotes_repository.dart';
import 'package:my_pills/features/greetings/domain/entities/daily_quote.dart';
import 'package:my_pills/features/greetings/domain/repositories/quotes_repository.dart';
import 'package:my_pills/features/greetings/domain/use_cases/get_today_quote.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'greetings_providers.g.dart';

@Riverpod(keepAlive: true)
QuotesRepository quotesRepository(Ref ref) =>
    AssetsQuotesRepository(rootBundle);

@riverpod
GetTodayQuote getTodayQuote(Ref ref) => GetTodayQuote(
  ref.watch(quotesRepositoryProvider),
  () => ref.read(clockProvider),
);

@riverpod
Future<DailyQuote> todayQuote(Ref ref) async {
  final result = await ref.watch(getTodayQuoteProvider).call();
  return switch (result) {
    Success(:final value) => value,
    FailureResult() => const DailyQuote(
      text: 'Cada día es una nueva oportunidad para ser mejor.',
    ),
  };
}
