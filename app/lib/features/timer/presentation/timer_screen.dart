import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/tarf_wheel_picker.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/timer_controller.dart';

const _presetMinutes = [1, 5, 10, 20, 30, 40];

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
                ? _IdleView(data: data, c: c, n: n, l10n: l10n)
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
  });

  final CountdownData data;
  final TimerController c;
  final NumeralSystem n;
  final AppLocalizations l10n;

  void _apply(int h, int m, int s) => c.setDuration(Duration(
        hours: h.clamp(0, 23),
        minutes: m.clamp(0, 59),
        seconds: s.clamp(0, 59),
      ));

  @override
  Widget build(BuildContext context) {
    final h = data.remaining.inHours.clamp(0, 23);
    final m = data.remaining.inMinutes % 60;
    final s = data.remaining.inSeconds % 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TarfWheelPicker(
          columns: [
            TarfWheelColumn(
              values: [for (var x = 0; x < 24; x++) Numerals.padded(x, n)],
              selected: h,
              onSelected: (i) => _apply(i, m, s),
              separator: ':',
            ),
            TarfWheelColumn(
              values: [for (var x = 0; x < 60; x++) Numerals.padded(x, n)],
              selected: m,
              onSelected: (i) => _apply(h, i, s),
              separator: ':',
            ),
            TarfWheelColumn(
              values: [for (var x = 0; x < 60; x++) Numerals.padded(x, n)],
              selected: s,
              onSelected: (i) => _apply(h, m, i),
            ),
          ],
        ),
        const SizedBox(height: TarfTokens.space5),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: TarfTokens.space3,
          crossAxisSpacing: TarfTokens.space3,
          children: [
            for (final x in _presetMinutes)
              _PresetCircle(
                minutes: x,
                n: n,
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

/// A circular timer preset (e.g. "05:00"); accent-filled when it matches the
/// current duration.
class _PresetCircle extends StatelessWidget {
  const _PresetCircle({
    required this.minutes,
    required this.n,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final NumeralSystem n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: TarfTimeText(
            Numerals.timer(Duration(minutes: minutes), n),
            style: Theme.of(context).textTheme.titleMedium,
            color: selected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
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
