import 'package:flutter/foundation.dart';

/// Per-day tasbih tally. [dayKey] is a local 'YYYY-MM-DD' so a new day resets.
/// Pure value type; the cycle target (33/99) is passed in, not stored, so the
/// model stays agnostic and testable.
@immutable
class TasbihState {
  const TasbihState({required this.dayKey, this.count = 0})
    : _justCompleted = false;

  const TasbihState._({
    required this.dayKey,
    required this.count,
    required this._justCompleted,
  });

  final String dayKey;
  final int count;

  /// Transient UI flag (drives the completion bloom). Set only by [increment];
  /// intentionally NOT persisted (see [toJson]).
  final bool _justCompleted;

  /// Count within the current cycle for [target] (0 when exactly on a multiple).
  int cyclePositionFor(int target) => target <= 0 ? count : count % target;

  /// Convenience for the default 33 cycle.
  int get inCycle => cyclePositionFor(33);

  /// True when [count] just landed on a non-zero multiple of the last target
  /// used in [increment]; false on plain construction / decode.
  bool get justCompletedCycle => _justCompleted;

  TasbihState increment({required int target}) {
    final next = count + 1;
    final completed = target > 0 && next % target == 0;
    return TasbihState._(
      dayKey: dayKey,
      count: next,
      justCompleted: completed,
    );
  }

  TasbihState reset() => TasbihState(dayKey: dayKey);

  Map<String, Object?> toJson() => {'day': dayKey, 'count': count};

  factory TasbihState.fromJson(Map<String, Object?> j) => TasbihState(
    dayKey: (j['day'] as String?) ?? '',
    count: (j['count'] as int?) ?? 0,
  );
}
