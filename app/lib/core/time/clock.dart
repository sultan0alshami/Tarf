/// An injectable clock so time-dependent logic (the eye-care engine, streaks,
/// daily-doc keys) is deterministic in tests.
abstract interface class Clock {
  DateTime now();
  Stream<DateTime> ticks(Duration interval);
}

/// Real wall-clock implementation used in the app.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Stream<DateTime> ticks(Duration interval) =>
      Stream<DateTime>.periodic(interval, (_) => DateTime.now());
}

/// Deterministic clock for tests. Advance time with [advance]; pump ticks with
/// [tick].
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  set current(DateTime value) => _now = value;

  void advance(Duration by) => _now = _now.add(by);

  @override
  DateTime now() => _now;

  @override
  // Tests drive logic via advance()+now() rather than real timers.
  Stream<DateTime> ticks(Duration interval) => const Stream<DateTime>.empty();
}

/// Returns the local-date key (yyyy-MM-dd) used for daily-progress documents.
/// Pairs with a stored timezone so day boundaries are unambiguous across travel.
String dayKey(DateTime localTime) {
  final y = localTime.year.toString().padLeft(4, '0');
  final m = localTime.month.toString().padLeft(2, '0');
  final d = localTime.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
