/// A function that returns the current moment in time.
///
/// Injecting [Clock] instead of calling [DateTime.now] directly lets tests
/// control time without patching global state.
///
/// .NET analogue: `TimeProvider` (introduced in .NET 8) — an injectable
/// abstraction over the system clock.
///
/// Default wiring (app providers):
/// ```dart
/// final clockProvider = Provider<Clock>((_) => DateTime.now);
/// ```
///
/// Test override:
/// ```dart
/// final fixed = DateTime(2024, 6, 1, 8, 0);
/// final container = ProviderContainer(
///   overrides: [clockProvider.overrideWithValue(() => fixed)],
/// );
/// ```
typedef Clock = DateTime Function();
