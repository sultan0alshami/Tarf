import 'package:flutter/widgets.dart';

/// Motion tokens. Calm, physical, and always overridable by Reduce Motion.
///
/// When [reduceMotion] is true, continuous/looping animations are swapped for
/// stepped or static presentation and durations collapse toward zero.
abstract final class TarfMotion {
  TarfMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 480);

  /// Gentle fade-in for the break overlay.
  static const Duration overlayFade = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuint;

  /// Returns [d] unless reduce-motion is on, in which case animation is removed.
  static Duration when({required bool reduceMotion, required Duration d}) =>
      reduceMotion ? Duration.zero : d;
}

/// Resolves the platform/user reduce-motion preference for a context.
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;
