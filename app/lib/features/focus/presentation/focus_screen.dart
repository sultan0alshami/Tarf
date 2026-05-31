import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/numerals.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../eyecare/presentation/show_break.dart';
import '../../insights/application/progress_controller.dart';
import '../application/focus_controller.dart';
import '../domain/focus_models.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  String _phaseLabel(AppLocalizations l10n, FocusPhase phase) => switch (phase) {
        FocusPhase.idle => l10n.focusReady,
        FocusPhase.work => l10n.phaseWork,
        FocusPhase.shortBreak => l10n.phaseShortBreak,
        FocusPhase.longBreak => l10n.phaseLongBreak,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(focusControllerProvider);
    final controller = ref.read(focusControllerProvider.notifier);
    final config = ref.watch(focusConfigProvider);
    final numerals = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );
    final todaySessions = ref.watch(
      progressControllerProvider
          .select((m) => m[dayKey(DateTime.now())]?.sessions ?? 0),
    );

    final display = state.phase == FocusPhase.idle ? config.work : state.remaining;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: l10n.restEyes,
            onPressed: () => showEyeBreak(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.checklist_outlined),
            tooltip: l10n.tasks,
            onPressed: () => context.push(Routes.tasks),
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: l10n.navInsights,
            onPressed: () => context.push(Routes.insights),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.navSettings,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _phaseLabel(l10n, state.phase),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: state.isBreak ? scheme.tertiary : scheme.primary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: TarfTokens.space4),
            ProgressRing(
              progress: state.phase == FocusPhase.idle ? 0 : state.progress,
              size: 260,
              color: state.isBreak ? scheme.tertiary : scheme.primary,
              child: Text(
                Numerals.timer(display, numerals),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
              ),
            ),
            const SizedBox(height: TarfTokens.space4),
            _DailyGoal(
              done: todaySessions,
              goal: config.dailyGoalSessions,
            ),
            const SizedBox(height: TarfTokens.space5),
            _Controls(state: state, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _DailyGoal extends StatelessWidget {
  const _DailyGoal({required this.done, required this.goal});
  final int done;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dots = goal.clamp(1, 12);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < dots; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.18),
                ),
              ),
          ],
        ),
        const SizedBox(height: TarfTokens.space2),
        Text(
          l10n.focusSessionsProgress(done, goal),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.controller});
  final FocusState state;
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.phase == FocusPhase.idle) {
      return FilledButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.actionStart),
        onPressed: controller.startWork,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: controller.reset,
          child: Text(l10n.actionReset),
        ),
        const SizedBox(width: TarfTokens.space3),
        FilledButton.icon(
          icon: Icon(state.running ? Icons.pause : Icons.play_arrow),
          label: Text(state.running ? l10n.actionPause : l10n.actionResume),
          onPressed: state.running ? controller.pause : controller.resume,
        ),
        const SizedBox(width: TarfTokens.space3),
        OutlinedButton(
          onPressed: controller.skip,
          child: Text(l10n.actionSkip),
        ),
      ],
    );
  }
}
