import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/settings_controller.dart';
import '../../insights/application/progress_controller.dart';
import '../application/eyecare_config_controller.dart';
import '../application/eyecare_providers.dart';
import 'break_overlay.dart';

/// Routed full-screen dhikr break — used by the manual "rest now" action (tap
/// the Home eye-care card) and reachable for previews. The auto engine uses its
/// own imperative push.
class BreakScreen extends ConsumerWidget {
  const BreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(dhikrRepositoryProvider);
    final config = ref.watch(eyeCareConfigProvider);
    final settings = ref.watch(settingsControllerProvider);
    final audio = ref.watch(breakAudioProvider);
    final index = ref.watch(dhikrRotationProvider);

    return repoAsync.when(
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (_, _) => const Scaffold(body: SizedBox.shrink()),
      data: (repo) {
        if (repo.isEmpty) return const Scaffold(body: SizedBox.shrink());
        final dhikr = repo.at(index);

        void close({required bool taken}) {
          ref.read(progressControllerProvider.notifier).addBreak(
                DateTime.now(),
                taken: taken,
              );
          ref.read(dhikrRotationProvider.notifier).next();
          if (context.canPop()) context.pop();
        }

        return BreakOverlay(
          dhikr: dhikr,
          duration: config.eyeBreakDuration,
          audio: audio,
          numerals: settings.effectiveNumerals,
          strict: config.strict,
          soundEnabled: config.soundEnabled,
          showTransliteration: config.showTransliteration,
          reduceMotion: settings.reduceMotion,
          onFinished: () => close(taken: true),
          onSkip: config.strict ? null : () => close(taken: false),
          onSnooze: config.strict
              ? null
              : (_) {
                  if (context.canPop()) context.pop();
                },
        );
      },
    );
  }
}
