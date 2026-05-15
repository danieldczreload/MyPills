import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:my_pills/core/errors/failure.dart';

part 'result.freezed.dart';

/// Functional result type: either a [Success] value or a [Failure].
///
/// .NET analogue: `Result<T>` or `Either<Error, T>` — forces callers to
/// handle the error path at compile time via pattern matching.
///
/// ```dart
/// final result = await useCase.call();
/// switch (result) {
///   case Success(:final value): /* use value */;
///   case FailureResult(:final failure): /* handle error */;
/// }
/// ```
@freezed
sealed class Result<T> with _$Result<T> {
  const Result._();

  /// Operation completed successfully with [value].
  const factory Result.success(T value) = Success<T>;

  /// Operation failed with [failure].
  const factory Result.failure(Failure failure) = FailureResult<T>;

  /// Returns the success value or `null`.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    FailureResult() => null,
  };

  /// Returns `true` if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this is a [FailureResult].
  bool get isFailure => this is FailureResult<T>;
}
