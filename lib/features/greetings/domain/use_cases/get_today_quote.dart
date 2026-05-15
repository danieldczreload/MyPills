import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/utils/clock.dart';
import 'package:my_pills/features/greetings/domain/entities/daily_quote.dart';
import 'package:my_pills/features/greetings/domain/repositories/quotes_repository.dart';

class GetTodayQuote {
  GetTodayQuote(this._repository, this._clock);

  final QuotesRepository _repository;
  final Clock _clock;

  Future<Result<DailyQuote>> call() => _repository.getTodayQuote(_clock());
}
