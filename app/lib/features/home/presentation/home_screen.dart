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
import '../../eyecare/application/eyecare_config_controller.dart';
import '../../eyecare/application/eyecare_live.dart';
import '../../focus/application/focus_controller.dart';
import '../../insights/application/progress_controller.dart';
import '../../insights/domain/daily_progress.dart';
import '../../todos/application/todos_controller.dart';

/// The eye-care-led Home (Calm Sanctuary). The 20-20-20 engine is the hero;
/// Focus/metrics are secondary. Consistent with onboarding and Settings.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _hm(int minutes, NumeralSystem n) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${Numerals.formatInt(h, n)}h ${Numerals.formatInt(m, n)}m';
    return '${Numerals.formatInt(m, n)}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final n = ref.watch(settingsControllerProvider.select((s) => s.effectiveNumerals));
    final config = ref.watch(eyeCareConfigProvider);
    final live = ref.watch(eyeCareLiveProvider);
    final today = ref.watch(
      progressControllerProvider.select(
        (m) => m[dayKey(DateTime.now())] ?? DailyProgress.empty('today'),
      ),
    );
    final todos = ref.watch(todosControllerProvider);
    final todosDone = todos.where((t) => t.done).length;

    final intervalSec = config.eyeInterval.inSeconds.clamp(1, 1 << 30);
    final accSec = live.accumulated.inSeconds.clamp(0, intervalSec);
    final remaining = Duration(seconds: intervalSec - accSec);
    final progress = accSec / intervalSec;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
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
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          // ---- Eye-care hero (the dominant object; tap to rest now) ----
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(TarfTokens.radiusM),
              onTap: () => context.push(Routes.eyeCareBreak),
              child: Padding(
              padding: const EdgeInsets.all(TarfTokens.space4),
              child: Row(
                children: [
                  ProgressRing(
                    progress: live.paused ? 0 : progress,
                    size: 96,
                    stroke: TarfTokens.ringStroke,
                    child: Icon(
                      live.paused ? Icons.pause : Icons.visibility_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: TarfTokens.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.nextEyeBreak,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          live.paused ? l10n.pausedLabel : Numerals.timer(remaining, n),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.eyeRestsToday(today.breaksTaken),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.tarf.textTertiary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(live.paused ? Icons.play_arrow : Icons.pause),
                    tooltip: l10n.eyeCareTitle,
                    onPressed: () =>
                        ref.read(eyeCareLiveProvider.notifier).togglePause(),
                  ),
                ],
              ),
            ),
            ),
          ),
          const SizedBox(height: TarfTokens.space3),
          // ---- Bento metrics ----
          Row(
            children: [
              _Metric(value: _hm(today.focusMinutes, n), label: l10n.focusTodayLabel),
              const SizedBox(width: TarfTokens.space2),
              _Metric(
                value: Numerals.formatInt(today.sessions, n),
                label: l10n.labelSessions,
              ),
              const SizedBox(width: TarfTokens.space2),
              _Metric(
                value: '${Numerals.formatInt(todosDone, n)}/'
                    '${Numerals.formatInt(todos.length, n)}',
                label: l10n.todosLabel,
              ),
            ],
          ),
          const SizedBox(height: TarfTokens.space5),
          // ---- Single hero CTA ----
          FilledButton.icon(
            icon: const Icon(Icons.center_focus_strong),
            label: Text(l10n.startFocusSession),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () {
              ref.read(focusControllerProvider.notifier).startWork();
              context.push(Routes.focusSession);
            },
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: TarfTokens.space3,
            horizontal: TarfTokens.space2,
          ),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
