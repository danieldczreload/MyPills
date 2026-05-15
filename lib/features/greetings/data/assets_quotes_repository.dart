import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/greetings/domain/entities/daily_quote.dart';
import 'package:my_pills/features/greetings/domain/repositories/quotes_repository.dart';

class AssetsQuotesRepository implements QuotesRepository {
  AssetsQuotesRepository(this._bundle);

  final AssetBundle _bundle;

  List<_QuoteEntry>? _cache;

  @override
  Future<Result<DailyQuote>> getTodayQuote(DateTime now) async {
    try {
      _cache ??= await _load();
      final index = _dayOfYear(now) % _cache!.length;
      final entry = _cache![index];
      return Result.success(DailyQuote(text: entry.text, author: entry.author));
    } on Object catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  Future<List<_QuoteEntry>> _load() async {
    final raw = await _bundle.loadString('assets/quotes_es.json');
    final list = json.decode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(_QuoteEntry.fromJson).toList();
  }

  int _dayOfYear(DateTime d) => d.difference(DateTime(d.year)).inDays;
}

class _QuoteEntry {
  _QuoteEntry({required this.text, this.author});

  factory _QuoteEntry.fromJson(Map<String, dynamic> json) => _QuoteEntry(
    text: json['text'] as String,
    author: json['author'] as String?,
  );

  final String text;
  final String? author;
}
