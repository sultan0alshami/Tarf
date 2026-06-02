import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/overlay/reverent_overlay.dart';
import '../../../core/settings/settings_controller.dart';
import '../../insights/application/progress_controller.dart';
import '../application/eyecare_config_controller.dart';
import '../application/eyecare_providers.dart';
import '../core/precedence.dart';
import 'break_overlay.dart';

/// Loads the next dhikr and presents the full-screen break overlay, then
/// advances the rotation. Used by the manual "take a break now" action and by
/// the eye-care engine when a scheduled break becomes due.
Future<void> showEyeBreak(
  BuildContext context,
  WidgetRef ref, {
  BreakKind kind = BreakKind.eyeMicro,
}) async {
  final repo = await ref.read(dhikrRepositoryProvider.future);
  if (repo.isEmpty || !context.mounted) return;

  final config = ref.read(eyeCareConfigProvider);
  final settings = ref.read(settingsControllerProvider);
  final audio = ref.read(breakAudioProvider);
  final index = ref.read(dhikrRotationProvider);
  final dhikr = repo.at(index);
  final duration = kind == BreakKind.longBreak
      ? config.longBreakDuration
      : config.eyeBreakDuration;

  final progress = ref.read(progressControllerProvider.notifier);
  final navigator = Navigator.of(context, rootNavigator: true);
  void recordAndPop({required bool taken}) {
    progress.addBreak(DateTime.now(), taken: taken);
    navigator.pop();
  }

  // Claim the reverent overlay SYNCHRONOUSLY, before pushing, so incidental
  // chrome (e.g. the web tap-to-enable-sound banner) is already gone on the
  // break's first painted frame — never flashing over the fading-in sacred
  // line. The banner is an ancestor of the Navigator (it lives in
  // MaterialApp.router's builder), so it cannot react to the route's own
  // initState in the same frame; claiming at the push site is what makes the
  // suppression effective on frame one. Released when the break is dismissed.
  ReverentOverlay.enter();
  await navigator.push<void>(
    PageRouteBuilder<void>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => BreakOverlay(
        dhikr: dhikr,
        duration: duration,
        audio: audio,
        numerals: settings.effectiveNumerals,
        strict: config.strict,
        soundEnabled: config.soundEnabled,
        reduceMotion: settings.reduceMotion,
        hapticEnabled: config.hapticEnabled,
        onFinished: () => recordAndPop(taken: true),
        onSkip: config.strict ? null : () => recordAndPop(taken: false),
        onSnooze: config.strict ? null : (_) => navigator.pop(),
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  ReverentOverlay.leave();

  ref.read(dhikrRotationProvider.notifier).next();
}
