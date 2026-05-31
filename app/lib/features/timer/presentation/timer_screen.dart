import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/timer_controller.dart';

const _presets = [
  Duration(minutes: 1),
  Duration(minutes: 3),
  Duration(minutes: 5),
  Duration(minutes: 10),
  Duration(minutes: 15),
  Duration(minutes: 25),
];

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final data = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final numerals = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabTimer)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProgressRing(
              progress: data.progress,
              size: 260,
              color: data.finished ? scheme.error : scheme.primary,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Numerals.timer(data.remaining, numerals),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                  if (data.finished)
                    Text(
                      l10n.timeUp,
                      style: TextStyle(color: scheme.error),
                    ),
                ],
              ),
            ),
            const SizedBox(height: TarfTokens.space4),
            Wrap(
              spacing: TarfTokens.space2,
              children: [
                for (final p in _presets)
                  ChoiceChip(
                    label: Text(Numerals.formatInt(p.inMinutes, numerals)),
                    selected: data.total == p && !data.running,
                    onSelected: (_) => controller.setDuration(p),
                  ),
              ],
            ),
            const SizedBox(height: TarfTokens.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: controller.reset,
                  child: Text(l10n.actionReset),
                ),
                const SizedBox(width: TarfTokens.space3),
                FilledButton.icon(
                  icon: Icon(data.running ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    data.running ? l10n.actionPause : l10n.actionStart,
                  ),
                  onPressed: data.running ? controller.pause : controller.start,
                ),
                const SizedBox(width: TarfTokens.space3),
                OutlinedButton(
                  onPressed: () => controller.addMinutes(1),
                  child: Text('+${Numerals.formatInt(1, numerals)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
