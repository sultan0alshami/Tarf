import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/progress_controller.dart';
import '../domain/daily_progress.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(progressControllerProvider);
    final numerals = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    final now = DateTime.now();
    final today = all[dayKey(now)] ?? DailyProgress.empty(dayKey(now));
    final week = ProgressMath.lastDays(all, now, 7);
    final streak = ProgressMath.currentStreak(all, now);
    final hasData = all.values.any((d) => d.sessions > 0 || d.focusMinutes > 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navInsights),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.exportCsv,
            onPressed: hasData
                ? () async {
                    await Clipboard.setData(
                      ClipboardData(text: ProgressMath.toCsv(all)),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.copiedToClipboard)),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
      body: !hasData
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(TarfTokens.space4),
                child: Text(
                  l10n.noDataYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(TarfTokens.space3),
              children: [
                if (streak > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TarfTokens.space3),
                    child: Chip(
                      avatar: const Icon(Icons.local_fire_department, size: 18),
                      label: Text(l10n.insightsStreak(streak)),
                    ),
                  ),
                Text(l10n.insightsToday,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: TarfTokens.space2),
                Row(
                  children: [
                    _Stat(
                      value: Numerals.formatInt(today.focusMinutes, numerals),
                      label: l10n.labelFocusMinutes,
                    ),
                    _Stat(
                      value: Numerals.formatInt(today.sessions, numerals),
                      label: l10n.labelSessions,
                    ),
                    _Stat(
                      value: Numerals.formatInt(today.breaksTaken, numerals),
                      label: l10n.labelBreaks,
                    ),
                  ],
                ),
                const SizedBox(height: TarfTokens.space4),
                Text(l10n.last7Days,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: TarfTokens.space3),
                _WeekChart(week: week, numerals: numerals),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TarfTokens.space3),
          child: Column(
            children: [
              Text(value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      )),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.week, required this.numerals});
  final List<DailyProgress> week;
  final NumeralSystem numerals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMin =
        week.fold<int>(1, (m, d) => d.focusMinutes > m ? d.focusMinutes : m);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in week)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    Numerals.formatInt(d.focusMinutes, numerals),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 110 * (d.focusMinutes / maxMin),
                    decoration: BoxDecoration(
                      color: d.focusMinutes > 0
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.day.substring(8), // dd
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
