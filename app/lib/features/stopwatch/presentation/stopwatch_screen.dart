import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/stopwatch_controller.dart';

class StopwatchScreen extends ConsumerWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final data = ref.watch(stopwatchControllerProvider);
    final controller = ref.read(stopwatchControllerProvider.notifier);
    final numerals = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabStopwatch)),
      body: Column(
        children: [
          const SizedBox(height: TarfTokens.space5),
          Center(
            child: Text(
              Numerals.stopwatch(data.elapsed, numerals),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w200,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
          const SizedBox(height: TarfTokens.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: data.elapsed == Duration.zero && !data.running
                    ? null
                    : (data.running ? controller.lap : controller.reset),
                child: Text(data.running ? l10n.lap : l10n.actionReset),
              ),
              const SizedBox(width: TarfTokens.space4),
              FilledButton(
                onPressed: data.running ? controller.stop : controller.start,
                child: Text(data.running ? l10n.actionStop : l10n.actionStart),
              ),
            ],
          ),
          const SizedBox(height: TarfTokens.space3),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: data.laps.length,
              itemBuilder: (context, index) {
                final lapNumber = data.laps.length - index;
                final lap = data.laps[index];
                return ListTile(
                  dense: true,
                  leading: Text(
                    Numerals.formatInt(lapNumber, numerals),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  trailing: Text(
                    Numerals.stopwatch(lap, numerals),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
