import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/stopwatch_controller.dart';

class StopwatchScreen extends ConsumerWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = ref.watch(stopwatchControllerProvider);
    final c = ref.read(stopwatchControllerProvider.notifier);
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    // Precompute the split for every lap (newest-first, same as data.laps).
    // split[i] = laps[i] - (the previous, older lap's absolute time).
    final laps = data.laps;
    final splits = <Duration>[
      for (var i = 0; i < laps.length; i++)
        laps[i] - (i + 1 < laps.length ? laps[i + 1] : Duration.zero),
    ];

    Duration? fastestSplit;
    Duration? slowestSplit;
    if (laps.length >= 2) {
      fastestSplit = splits.reduce((a, b) => a <= b ? a : b);
      slowestSplit = splits.reduce((a, b) => a >= b ? a : b);
    }

    const buttonSize = Size(120, 52);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabStopwatch)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TarfTokens.space3),
        child: Column(
          children: [
            const SizedBox(height: TarfTokens.space5),
            Center(
              child: FittedBox(
                child: TarfTimeText(
                  Numerals.stopwatch(data.elapsed, n),
                  style: theme.textTheme.displayLarge,
                ),
              ),
            ),
            const SizedBox(height: TarfTokens.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildButtons(context, l10n, data, c, buttonSize),
            ),
            const SizedBox(height: TarfTokens.space4),
            Expanded(
              child: laps.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noLapsYet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: laps.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final lapNumber = laps.length - i;
                        final total = laps[i];
                        final split = splits[i];
                        return _LapRow(
                          label: l10n.lapNumber(lapNumber),
                          split: split,
                          total: total,
                          numerals: n,
                          isFastest:
                              laps.length >= 2 && split == fastestSplit,
                          isSlowest:
                              laps.length >= 2 && split == slowestSplit,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtons(
    BuildContext context,
    AppLocalizations l10n,
    StopwatchData data,
    StopwatchController c,
    Size buttonSize,
  ) {
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(buttonSize),
    );

    if (data.running) {
      return [
        FilledButton.tonal(
          onPressed: c.lap,
          style: style,
          child: Text(l10n.lap),
        ),
        const SizedBox(width: TarfTokens.space4),
        FilledButton(
          onPressed: c.stop,
          style: style,
          child: Text(l10n.actionStop),
        ),
      ];
    }

    if (data.elapsed > Duration.zero) {
      return [
        OutlinedButton(
          onPressed: c.reset,
          style: style,
          child: Text(l10n.actionReset),
        ),
        const SizedBox(width: TarfTokens.space4),
        FilledButton(
          onPressed: c.start,
          style: style,
          child: Text(l10n.actionStart),
        ),
      ];
    }

    // Initial state: elapsed == Duration.zero, not running.
    return [
      FilledButton.tonal(
        onPressed: null,
        style: style,
        child: Text(l10n.lap),
      ),
      const SizedBox(width: TarfTokens.space4),
      FilledButton(
        onPressed: c.start,
        style: style,
        child: Text(l10n.actionStart),
      ),
    ];
  }
}

class _LapRow extends StatelessWidget {
  const _LapRow({
    required this.label,
    required this.split,
    required this.total,
    required this.numerals,
    required this.isFastest,
    required this.isSlowest,
  });

  final String label;
  final Duration split;
  final Duration total;
  final NumeralSystem numerals;
  final bool isFastest;
  final bool isSlowest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tarf = context.tarf;

    Widget marker;
    if (isFastest) {
      marker = Icon(Icons.arrow_drop_up, size: 20, color: tarf.success);
    } else if (isSlowest) {
      marker = Icon(Icons.arrow_drop_down, size: 20, color: tarf.warning);
    } else {
      marker = const SizedBox(width: 20);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TarfTokens.space3,
          vertical: TarfTokens.space2,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: TarfTimeText(
                  Numerals.stopwatch(split, numerals),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                marker,
                const SizedBox(width: TarfTokens.space2),
                TarfTimeText(
                  Numerals.stopwatch(total, numerals),
                  style: theme.textTheme.bodySmall,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
