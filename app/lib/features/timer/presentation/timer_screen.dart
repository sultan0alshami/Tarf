import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/timer_controller.dart';

const _presetMinutes = [1, 5, 10, 20];

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = ref.watch(timerControllerProvider);
    final c = ref.read(timerControllerProvider.notifier);
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    final isIdle = !data.running && !data.finished;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabTimer)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(TarfTokens.space4),
            child: isIdle
                ? _IdleView(data: data, c: c, n: n, l10n: l10n, theme: theme)
                : _ActiveView(
                    data: data,
                    c: c,
                    n: n,
                    l10n: l10n,
                    scheme: scheme,
                    theme: theme,
                  ),
          ),
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.data,
    required this.c,
    required this.n,
    required this.l10n,
    required this.theme,
  });

  final CountdownData data;
  final TimerController c;
  final NumeralSystem n;
  final AppLocalizations l10n;
  final ThemeData theme;

  void _apply(int h, int m, int s) {
    final hh = h.clamp(0, 23);
    final mm = m.clamp(0, 59);
    final ss = s.clamp(0, 59);
    HapticFeedback.selectionClick();
    c.setDuration(Duration(hours: hh, minutes: mm, seconds: ss));
  }

  @override
  Widget build(BuildContext context) {
    final h = data.remaining.inHours;
    final m = data.remaining.inMinutes % 60;
    final s = data.remaining.inSeconds % 60;

    final colonStyle = theme.textTheme.displayMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Stepper(
              value: h,
              unit: l10n.unitHours,
              numerals: n,
              onIncrement: () => _apply(h + 1, m, s),
              onDecrement: () => _apply(h - 1, m, s),
            ),
            Text(':', style: colonStyle),
            _Stepper(
              value: m,
              unit: l10n.unitMinutes,
              numerals: n,
              onIncrement: () => _apply(h, m + 1, s),
              onDecrement: () => _apply(h, m - 1, s),
            ),
            Text(':', style: colonStyle),
            _Stepper(
              value: s,
              unit: l10n.unitSeconds,
              numerals: n,
              onIncrement: () => _apply(h, m, s + 1),
              onDecrement: () => _apply(h, m, s - 1),
            ),
          ],
        ),
        const SizedBox(height: TarfTokens.space5),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: TarfTokens.space2,
          runSpacing: TarfTokens.space2,
          children: [
            for (final x in _presetMinutes)
              TarfPresetChip(
                label: l10n.minutesShort(x),
                selected: data.total == Duration(minutes: x),
                onTap: () {
                  HapticFeedback.selectionClick();
                  c.setDuration(Duration(minutes: x));
                },
              ),
          ],
        ),
        const SizedBox(height: TarfTokens.space5),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: data.remaining > Duration.zero ? c.start : null,
            child: Text(l10n.actionStart),
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.numerals,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int value;
  final String unit;
  final NumeralSystem numerals;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          onPressed: onIncrement,
        ),
        TarfTimeText(
          Numerals.padded(value, numerals),
          style: theme.textTheme.displayMedium,
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: onDecrement,
        ),
        Text(
          unit,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView({
    required this.data,
    required this.c,
    required this.n,
    required this.l10n,
    required this.scheme,
    required this.theme,
  });

  final CountdownData data;
  final TimerController c;
  final NumeralSystem n;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final ThemeData theme;

  static String _fmt(Duration d, NumeralSystem n) {
    if (d.inHours > 0) {
      return '${Numerals.padded(d.inHours, n)}:'
          '${Numerals.padded(d.inMinutes % 60, n)}:'
          '${Numerals.padded(d.inSeconds % 60, n)}';
    }
    return Numerals.timer(d, n);
  }

  @override
  Widget build(BuildContext context) {
    final displayStyle = theme.textTheme.displayMedium;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(
          progress: data.progress,
          size: 280,
          color: data.finished ? scheme.error : scheme.primary,
          child: data.finished
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.timeUp,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                    const SizedBox(height: TarfTokens.space2),
                    TarfTimeText(
                      Numerals.timer(Duration.zero, n),
                      style: displayStyle,
                    ),
                  ],
                )
              : TarfTimeText(
                  _fmt(data.remaining, n),
                  style: displayStyle,
                ),
        ),
        const SizedBox(height: TarfTokens.space5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: c.reset,
              child: Text(l10n.actionReset),
            ),
            const SizedBox(width: TarfTokens.space3),
            FilledButton(
              onPressed: data.running ? c.pause : c.start,
              child: Text(data.running ? l10n.actionPause : l10n.actionStart),
            ),
          ],
        ),
      ],
    );
  }
}
