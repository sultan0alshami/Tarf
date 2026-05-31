/// Accumulates *active* screen time toward the next eye break.
///
/// This is the antidote to "dumb timer" apps: time only counts while the user
/// is active. Brief inactivity (>= [idleThreshold]) pauses accumulation;
/// prolonged inactivity (>= [idleResetThreshold]) resets it to zero, matching
/// the intuition that after a long break away from the screen the eyes are
/// already rested.
class ActiveTimeTracker {
  ActiveTimeTracker({
    required this.idleThreshold,
    required this.idleResetThreshold,
  });

  final Duration idleThreshold;
  final Duration idleResetThreshold;

  Duration _accumulated = Duration.zero;
  Duration _idleElapsed = Duration.zero;
  bool _paused = false;

  Duration get accumulated => _accumulated;
  bool get isPaused => _paused;

  /// Advances the tracker by [delta]. [active] is whether the user was active
  /// during this slice (screen on, not idle, not on a call, etc.).
  void tick(Duration delta, {required bool active}) {
    if (active) {
      _idleElapsed = Duration.zero;
      _paused = false;
      _accumulated += delta;
      return;
    }

    _idleElapsed += delta;
    if (_idleElapsed >= idleResetThreshold) {
      _accumulated = Duration.zero;
      _paused = true;
    } else if (_idleElapsed >= idleThreshold) {
      _paused = true;
    }
    // Below the idle threshold we simply don't add time (a momentary lull).
  }

  /// Whether enough active time has accumulated to be due for a break.
  bool isDue(Duration interval) => _accumulated >= interval;

  /// Resets accumulation after a break is taken (or skipped).
  void reset() {
    _accumulated = Duration.zero;
    _idleElapsed = Duration.zero;
    _paused = false;
  }
}
