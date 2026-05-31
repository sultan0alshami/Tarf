import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
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

  final navigator = Navigator.of(context, rootNavigator: true);
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
        onFinished: navigator.pop,
        onSkip: config.strict ? null : navigator.pop,
        onSnooze: config.strict ? null : (_) => navigator.pop(),
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  ref.read(dhikrRotationProvider.notifier).next();
}
