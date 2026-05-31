import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/progress_controller.dart';
import '../domain/daily_progress.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tarf = context.tarf;

    final all = ref.watch(progressControllerProvider);
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    final now = DateTime.now();
    final today = all[dayKey(now)] ?? DailyProgress.empty('today');
    final week = ProgressMath.lastDays(all, now, 7);
    final weekFocus = week.fold<int>(0, (a, d) => a + d.focusMinutes);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navInsights)),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          // 1. Hero card — eye rests today.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TarfTokens.space4),
              child: Row(
                children: [
                  TarfTimeText(
                    Numerals.formatInt(today.breaksTaken, n),
                    style: theme.textTheme.displaySmall,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: TarfTokens.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.insightsEyeRestsCaption,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.insightsEyeRestsSubline,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: tarf.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Last 7 days — bar chart of eye rests.
          const SizedBox(height: TarfTokens.space4),
          Text(
            l10n.last7Days,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TarfTokens.space3),
          _WeekBars(week: week, numerals: n),

          // 3. Focus metrics — today vs this week.
          const SizedBox(height: TarfTokens.space4),
          Row(
            children: [
              Expanded(
                child: TarfMetricCard(
                  value: _hm(today.focusMinutes, n),
                  label: l10n.focusTodayLabel,
                ),
              ),
              const SizedBox(width: TarfTokens.space2),
              Expanded(
                child: TarfMetricCard(
                  value: _hm(weekFocus, n),
                  label: l10n.insightsThisWeek,
                ),
              ),
            ],
          ),

          // 4. Export.
          const SizedBox(height: TarfTokens.space4),
          Center(
            child: TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: ProgressMath.toCsv(all)),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copiedToClipboard)),
                  );
                }
              },
              child: Text(l10n.exportCsv),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats minutes as a compact "1h 5m" / "5m" string in the chosen numerals.
String _hm(int minutes, NumeralSystem n) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0
      ? '${Numerals.formatInt(h, n)}h ${Numerals.formatInt(m, n)}m'
      : '${Numerals.formatInt(m, n)}m';
}

/// A seven-bar chart of daily eye rests (oldest first). In RTL the Row places
/// the oldest day on the right, which reads correctly; the bars themselves are
/// plain rectangles and need no mirroring.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.week, required this.numerals});

  final List<DailyProgress> week;
  final NumeralSystem numerals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxRests = week.map((d) => d.breaksTaken).fold<int>(0, math.max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TarfTokens.space3),
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in week)
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TarfTokens.space1),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor:
                                  maxRests == 0 ? 0 : d.breaksTaken / maxRests,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(TarfTokens.radiusS),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Numerals.formatInt(_dayOfMonth(d.day), numerals),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Parses the day-of-month from a `yyyy-MM-dd` key.
  static int _dayOfMonth(String day) =>
      int.tryParse(day.split('-').last) ?? 0;
}
