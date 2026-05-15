import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_quote.freezed.dart';

@freezed
abstract class DailyQuote with _$DailyQuote {
  const factory DailyQuote({
    required String text,
    String? author,
  }) = _DailyQuote;
}
