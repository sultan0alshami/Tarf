import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/format/numerals.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../audio/break_audio.dart';
import '../domain/dhikr.dart';

/// The full-screen break experience: a depleting countdown ring, one large
/// vocalized Arabic dhikr (auto-fit, never truncated), optional transliteration
/// and English meaning, the source tag, and — unless [strict] — skip/snooze.
///
/// The audio is started on entry for exactly [duration] so the sound ending is
/// the cue to look back.
class BreakOverlay extends StatefulWidget {
  const BreakOverlay({
    super.key,
    required this.dhikr,
    required this.duration,
    required this.audio,
    required this.numerals,
    required this.onFinished,
    this.onSkip,
    this.onSnooze,
    this.strict = false,
    this.soundEnabled = true,
    this.showTransliteration = true,
    this.reduceMotion = false,
  });

  final Dhikr dhikr;
  final Duration duration;
  final BreakAudioPlayer audio;
  final NumeralSystem numerals;
  final VoidCallback onFinished;
  final VoidCallback? onSkip;
  final ValueChanged<Duration>? onSnooze;
  final bool strict;
  final bool soundEnabled;
  final bool showTransliteration;
  final bool reduceMotion;

  @override
  State<BreakOverlay> createState() => _BreakOverlayState();
}

class _BreakOverlayState extends State<BreakOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _breathe;
  bool _finished = false;
  late bool _showTranslit;

  @override
  void initState() {
    super.initState();
    _showTranslit = widget.showTransliteration;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
        }
      });
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (!widget.reduceMotion) _breathe.repeat(reverse: true);
    _controller.forward();
    widget.audio.start(
      duration: widget.duration,
      soundEnabled: widget.soundEnabled,
      dhikr: widget.dhikr,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _breathe.dispose();
    super.dispose();
  }

  void _skip() {
    widget.audio.stop();
    widget.onSkip?.call();
  }

  void _finish() {
    widget.audio.stop();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? TarfTokens.breakBgDark : TarfTokens.breakBgLight;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TarfTokens.space4),
          child: Column(
            children: [
              const Spacer(),
              // Countdown ring with seconds in the center.
              AnimatedBuilder(
                animation: Listenable.merge([_controller, _breathe]),
                builder: (context, _) {
                  final remaining = _finished
                      ? Duration.zero
                      : widget.duration * (1 - _controller.value);
                  final seconds = remaining.inMilliseconds / 1000;
                  return Transform.scale(
                    scale: 1 + 0.02 * _breathe.value,
                    child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: 1 - _controller.value,
                        color: scheme.primary,
                        track: scheme.primary.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          _finished
                              ? '0'
                              : Numerals.formatInt(seconds.ceil(), widget.numerals),
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(fontWeight: FontWeight.w300),
                        ),
                      ),
                    ),
                  ));
                },
              ),
              const SizedBox(height: TarfTokens.space3),
              Text(
                _finished ? l10n.breakOver : l10n.breakLookAway,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // The dhikr — the hero of this screen.
              _DhikrView(
                dhikr: widget.dhikr,
                showTransliteration: _showTranslit,
                onToggleTransliteration: () =>
                    setState(() => _showTranslit = !_showTranslit),
              ),
              const Spacer(),
              _Controls(
                finished: _finished,
                strict: widget.strict,
                onFinish: _finish,
                onSkip: widget.onSkip == null ? null : _skip,
                onSnooze: widget.onSnooze,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DhikrView extends StatelessWidget {
  const _DhikrView({
    required this.dhikr,
    required this.showTransliteration,
    required this.onToggleTransliteration,
  });

  final Dhikr dhikr;
  final bool showTransliteration;
  final VoidCallback onToggleTransliteration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arabic: always RTL, fully vocalized, auto-fit so it never truncates.
        Directionality(
          textDirection: TextDirection.rtl,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dhikr.arabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: TarfTokens.fontArabic,
                fontSize: 50,
                height: 1.75,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        if (showTransliteration) ...[
          const SizedBox(height: TarfTokens.space3),
          Text(
            dhikr.transliteration,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
        const SizedBox(height: TarfTokens.space2),
        Text(
          dhikr.english,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: TarfTokens.space2),
        Text(
          dhikr.reference,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.finished,
    required this.strict,
    required this.onFinish,
    this.onSkip,
    this.onSnooze,
  });

  final bool finished;
  final bool strict;
  final VoidCallback onFinish;
  final VoidCallback? onSkip;
  final ValueChanged<Duration>? onSnooze;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (finished) {
      return FilledButton(
        onPressed: onFinish,
        child: Text(l10n.actionDone),
      );
    }
    // During the break: strict mode hides escape hatches.
    if (strict) return const SizedBox(height: TarfTokens.minTapTarget);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onSnooze != null)
          TextButton(
            onPressed: () => onSnooze!(const Duration(minutes: 5)),
            child: Text(l10n.actionSnooze),
          ),
        const SizedBox(width: TarfTokens.space3),
        if (onSkip != null)
          OutlinedButton(
            onPressed: onSkip,
            child: Text(l10n.actionSkip),
          ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track});

  /// 1.0 = full (start), 0.0 = empty (end).
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - TarfTokens.ringStrokeLarge) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = TarfTokens.ringStrokeLarge
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = TarfTokens.ringStrokeLarge
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
