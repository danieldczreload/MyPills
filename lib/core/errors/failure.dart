import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Machine-readable codes for input-validation failures.
///
/// The presentation layer switches on this enum to produce a localized string
/// via `AppLocalizations` — the domain layer must never embed translated text.
enum ValidationCode {
  /// Medication name was blank.
  emptyMedicationName,

  /// Medication category was blank.
  emptyCategory,

  /// A schedule requires at least one time-of-day entry.
  noTimesOfDay,

  /// A time-of-day value is outside a valid 24-hour clock range.
  invalidTime,

  /// A DailyInterval schedule must have everyHours > 0.
  invalidHoursInterval,

  /// A SpecificDays schedule must select at least one day of the week.
  noDaysOfWeek,

  /// endDate is set but falls before startDate.
  endDateBeforeStartDate,

  /// A daysOfWeek entry is outside the ISO 8601 range 1 (Monday) – 7 (Sunday).
  invalidDayOfWeek,

  /// The supplied id is not a valid persisted identifier.
  invalidId,

  /// Medication color token was blank.
  emptyColorToken,

  /// DailyInterval endAt is not after startAt.
  invalidTimeRange,

  /// Creating a schedule requires a dose amount and unit.
  doseRequired,

  /// Dose amount is not > 0 or has more than 4 decimal places.
  invalidDoseAmount,

  /// Dose unit is missing or not a catalog code.
  invalidDoseUnit,
}

/// Domain-level failure sealed union.
///
/// .NET analogue: a discriminated union of error cases, similar to
/// `record` sub-types or a custom `Exception` hierarchy, but value-based
/// and exhaustive-pattern-friendly.
///
/// Use cases return `Result<T, Failure>` so errors are explicit in the
/// signature — never throw across layer boundaries.
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  /// The requested entity does not exist.
  const factory Failure.notFound() = NotFound;

  /// The operation would violate a uniqueness or integrity constraint.
  const factory Failure.conflict() = Conflict;

  /// Input validation failed.
  ///
  /// [code] is a machine-readable enum that the presentation layer maps to a
  /// localized message — never embed translated strings in the domain layer.
  const factory Failure.validation({required ValidationCode code}) = Validation;

  /// Authentication failed or token is invalid/expired.
  const factory Failure.unauthorized() = Unauthorized;

  /// Network connection failed or timeout.
  const factory Failure.network() = NetworkFailure;

  /// Server returned an error status code.
  const factory Failure.server({
    required int statusCode,
    String? message,
  }) = ServerFailure;

  /// An unexpected error occurred — wraps the original error object.
  ///
  /// Typed as [Object] rather than [Exception] because Dart allows throwing
  /// any [Object] (including [Error] subclasses), so narrowing to [Exception]
  /// would silently drop `Error`s caught at the data layer.
  const factory Failure.unexpected({
    required Object error,
    StackTrace? stackTrace,
  }) = Unexpected;
}
