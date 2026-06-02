import 'package:flutter/foundation.dart';

/// What a platform can honestly do for background delivery. Drives the degraded
/// banner (Phase 3) — we never claim more than the OS provides.
class BackgroundCapability {
  const BackgroundCapability({
    required this.deliversWhenClosed,
    required this.supportsExactAlarms,
  });

  /// Can a scheduled reminder fire when the app/tab is fully closed?
  final bool deliversWhenClosed;

  /// Exact (Doze-piercing) alarms available? Android only.
  final bool supportsExactAlarms;

  static const android =
      BackgroundCapability(deliversWhenClosed: true, supportsExactAlarms: true);
  static const ios =
      BackgroundCapability(deliversWhenClosed: true, supportsExactAlarms: false);
  static const macos =
      BackgroundCapability(deliversWhenClosed: true, supportsExactAlarms: false);
  static const windows =
      BackgroundCapability(deliversWhenClosed: true, supportsExactAlarms: false);

  /// Web/extension: only while the tab/worker is alive. We do NOT pretend.
  static const web =
      BackgroundCapability(deliversWhenClosed: false, supportsExactAlarms: false);

  /// The capability for the platform this build runs on.
  static BackgroundCapability detect() {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web; // conservative: assume foreground-only
    }
  }
}
