import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/greetings/domain/entities/daily_quote.dart';

// ignore: one_member_abstracts // intentional clean-arch interface; data layer can be swapped without touching domain
abstract interface class QuotesRepository {
  Future<Result<DailyQuote>> getTodayQuote(DateTime now);
}
