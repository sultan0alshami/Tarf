import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether a *reverent* full-screen overlay (the dhikr eye-break) is
/// currently on screen. Incidental app chrome — notably the web
/// "tap to enable sound" banner — watches this and hides itself while a break is
/// shown, so nothing ever paints over the sacred line.
///
/// Why a counter and not a bool: a break can be pushed while another is
/// finishing (snooze/restart), and `MaterialApp.router` keeps both routes in the
/// tree briefly during the transition. Counting enter/leave keeps the flag true
/// until the *last* overlay is gone.
///
/// Why this exists at all: with `MaterialApp.router`, the `builder` (where the
/// banner lives) is layered ABOVE the Router's Navigator, so a fullscreen route
/// pushed on the root navigator does NOT cover the banner by z-order alone.
/// Suppressing by state is the reliable guarantee. See [[reverence]] in design.
class ReverentOverlay extends Notifier<int> {
  @override
  int build() => 0;

  /// Call when a reverent overlay appears (e.g. BreakOverlay.initState).
  void enter() {
    if (ref.mounted) state = state + 1;
  }

  /// Call when it leaves (e.g. BreakOverlay.dispose). Never goes below zero.
  /// The leave() is deferred a microtask by callers, so the provider may already
  /// be disposed (e.g. a test tearing down) — guard against that.
  void leave() {
    if (ref.mounted) state = state > 0 ? state - 1 : 0;
  }
}

final reverentOverlayProvider = NotifierProvider<ReverentOverlay, int>(
  ReverentOverlay.new,
);

/// True while at least one reverent overlay is on screen.
final reverentOverlayActiveProvider = Provider<bool>(
  (ref) => ref.watch(reverentOverlayProvider) > 0,
);
