import 'dart:math' as math;

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
    final data = ref.watch(stopwatchControllerProvider);
    final c = ref.read(stopwatchControllerProvider.notifier);
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    // Precompute the split for every lap (newest-first, same as data.laps).
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
    final showDial = laps.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabStopwatch)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TarfTokens.space3),
        child: Column(
          children: [
            const SizedBox(height: TarfTokens.space5),
            // Analog dial is the hero until the first lap is recorded; after
            // that the digital time + lap list take over (design.md §8.13).
            if (showDial) ...[
              _StopwatchDial(elapsed: data.elapsed, size: 240),
              const SizedBox(height: TarfTokens.space4),
            ],
            Center(
              child: FittedBox(
                child: TarfTimeText(
                  Numerals.stopwatch(data.elapsed, n),
                  style: showDial
                      ? theme.textTheme.displaySmall
                      : theme.textTheme.displayLarge,
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
                  ? const SizedBox.shrink()
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

/// An analog stopwatch face: an outer 60-second ring with ticks + a sweeping
/// second hand, and an inner 30-minute sub-dial with a short hand. Calm, teal.
class _StopwatchDial extends StatelessWidget {
  const _StopwatchDial({required this.elapsed, required this.size});

  final Duration elapsed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StopwatchDialPainter(
          elapsed: elapsed,
          track: context.tarf.ringTrack,
          accent: scheme.primary,
        ),
      ),
    );
  }
}

class _StopwatchDialPainter extends CustomPainter {
  _StopwatchDialPainter({
    required this.elapsed,
    required this.track,
    required this.accent,
  });

  final Duration elapsed;
  final Color track;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = track;
    canvas.drawCircle(center, r - 2, ring);

    // 60 ticks (every second), longer every 5.
    final tick = Paint()
      ..color = track
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      final a = -math.pi / 2 + i * (2 * math.pi / 60);
      final outer = r - 4;
      final inner = outer - (major ? 12 : 6);
      tick.strokeWidth = major ? 2.5 : 1.0;
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        tick,
      );
    }

    // Inner 30-minute sub-dial.
    final innerR = r * 0.42;
    canvas.drawCircle(center, innerR, ring..strokeWidth = 1.5);
    final minFrac = ((elapsed.inSeconds / 60) % 30) / 30;
    final minA = -math.pi / 2 + minFrac * 2 * math.pi;
    canvas.drawLine(
      center,
      center + Offset(math.cos(minA) * innerR * 0.8, math.sin(minA) * innerR * 0.8),
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Sweeping second hand.
    final secFrac = (elapsed.inMilliseconds % 60000) / 60000;
    final secA = -math.pi / 2 + secFrac * 2 * math.pi;
    canvas.drawLine(
      center,
      center + Offset(math.cos(secA) * (r - 16), math.sin(secA) * (r - 16)),
      Paint()
        ..color = accent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 4, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_StopwatchDialPainter old) =>
      old.elapsed != elapsed || old.track != track || old.accent != accent;
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
                  color: isFastest
                      ? tarf.success
                      : (isSlowest ? tarf.warning : null),
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
