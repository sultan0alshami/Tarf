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
            icon: const Icon(Icons.tune),
            tooltip: l10n.editDurations,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const _FocusDurationsSheet(),
            ),
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

/// Inline editor for the Focus (Pomodoro) durations + daily goal, opened from
/// the home screen so the user never has to dig into Settings.
class _FocusDurationsSheet extends ConsumerWidget {
  const _FocusDurationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(focusConfigProvider);
    final controller = ref.read(focusConfigProvider.notifier);
    final numerals = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(l10n.editDurations,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: TarfTokens.space2),
            _SliderRow(
              label: l10n.phaseWork,
              valueLabel: l10n.minutesShort(config.work.inMinutes),
              value: config.work.inMinutes.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (v) => controller
                  .update(config.copyWith(work: Duration(minutes: v.round()))),
            ),
            _SliderRow(
              label: l10n.phaseShortBreak,
              valueLabel: l10n.minutesShort(config.shortBreak.inMinutes),
              value: config.shortBreak.inMinutes.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (v) => controller.update(
                  config.copyWith(shortBreak: Duration(minutes: v.round()))),
            ),
            _SliderRow(
              label: l10n.phaseLongBreak,
              valueLabel: l10n.minutesShort(config.longBreak.inMinutes),
              value: config.longBreak.inMinutes.toDouble(),
              min: 5,
              max: 45,
              divisions: 40,
              onChanged: (v) => controller.update(
                  config.copyWith(longBreak: Duration(minutes: v.round()))),
            ),
            _SliderRow(
              label: l10n.focusDailyGoal,
              valueLabel: Numerals.formatInt(config.dailyGoalSessions, numerals),
              value: config.dailyGoalSessions.toDouble(),
              min: 1,
              max: 16,
              divisions: 15,
              onChanged: (v) => controller
                  .update(config.copyWith(dailyGoalSessions: v.round())),
            ),
            const SizedBox(height: TarfTokens.space2),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionDone),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              Text(valueLabel,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
