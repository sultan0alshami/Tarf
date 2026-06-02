import 'package:flutter/foundation.dart';
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
///
/// Why a [ValueNotifier] and not a Riverpod `Notifier`'s `state`: the break must
/// claim the overlay SYNCHRONOUSLY in its `initState` so the banner is gone on
/// the break's very first painted frame (a post-frame/microtask flip lands a
/// frame late, flashing the banner over the fading-in sacred line). Riverpod
/// forbids writing provider state during build/initState, but a plain
/// [ValueNotifier] may be mutated there — and the banner still reacts via the
/// derived [reverentOverlayActiveProvider], which mirrors it.
class ReverentOverlay {
  ReverentOverlay._();

  /// Process-wide count of reverent overlays currently on screen. App chrome is
  /// a single tree, so one shared signal is correct (and lets the break claim it
  /// synchronously from `initState`).
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  /// Call when a reverent overlay appears (e.g. BreakOverlay.initState). Safe to
  /// call synchronously during build/initState.
  static void enter() => count.value = count.value + 1;

  /// Call when it leaves (e.g. BreakOverlay.dispose). Never goes below zero.
  static void leave() => count.value = count.value > 0 ? count.value - 1 : 0;
}

/// True while at least one reverent overlay is on screen. Mirrors the shared
/// [ReverentOverlay.count] ValueNotifier so widgets can `ref.watch` it; rebuilds
/// whenever the count crosses any change (the banner only cares about > 0).
final reverentOverlayActiveProvider = Provider<bool>((ref) {
  final notifier = ReverentOverlay.count;
  void listener() => ref.invalidateSelf();
  notifier.addListener(listener);
  ref.onDispose(() => notifier.removeListener(listener));
  return notifier.value > 0;
});
