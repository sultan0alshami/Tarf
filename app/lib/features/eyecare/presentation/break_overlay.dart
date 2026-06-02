import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/audio/audio_haptics.dart';
import '../../../core/format/numerals.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../audio/break_audio.dart';
import '../domain/dhikr.dart';

/// The reverent 20-second eye-break (see design.md §3, §8.3). The physiological
/// task is to look ~6 m away (defocus); the dhikr is shown large and static to
/// recite from memory, not to read closely. A soft focal dot gently recedes at
/// the ring's center. The visual end cue (ring to zero + bloom) is authoritative;
/// the chime/haptic are equal cues.
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
    this.hapticEnabled = true,
    this.haptics = const AudioHaptics(),
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

  /// Whether the equal end-cue haptic fires; independent of reduce-motion.
  final bool hapticEnabled;

  /// Injectable so tests can assert the equal haptic cue.
  final AudioHaptics haptics;

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
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
          // Equal cue: the visual bloom + audio end already mark completion;
          // this is the matching haptic (honors hapticEnabled, not reduce-motion).
          widget.haptics.cue(HapticKind.breakEnd, enabled: widget.hapticEnabled);
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
    final t = context.tarf;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: t.dhikrGround,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TarfTokens.space5),
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: Listenable.merge([_controller, _breathe]),
                builder: (context, _) {
                  final progress = _finished ? 0.0 : 1 - _controller.value;
                  final remaining = _finished
                      ? Duration.zero
                      : widget.duration * progress;
                  // Focal dot gently recedes (shrinks) toward the distance.
                  final dotScale = 1.0 - 0.45 * _controller.value;
                  return Transform.scale(
                    scale: 1 + 0.02 * _breathe.value,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: progress,
                          color: scheme.primary,
                          track: t.ringTrack,
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Receding focal dot (a gentle distance cue).
                              Opacity(
                                opacity: _finished ? 0 : 0.18,
                                child: Transform.scale(
                                  scale: dotScale,
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                _finished
                                    ? Numerals.formatInt(0, widget.numerals)
                                    : Numerals.formatInt(
                                        (remaining.inMilliseconds / 1000).ceil(),
                                        widget.numerals,
                                      ),
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: TarfTokens.space3),
              Text(
                _finished ? l10n.breakOver : l10n.breakLookAway,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(flex: 2),
              _DhikrView(
                dhikr: widget.dhikr,
                showTransliteration: _showTranslit,
                onToggle: () => setState(() => _showTranslit = !_showTranslit),
              ),
              const Spacer(flex: 3),
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
    required this.onToggle,
  });

  final Dhikr dhikr;
  final bool showTransliteration;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tarf;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The sacred line — sole hero, never decorated, auto-fit, never truncated.
        Directionality(
          textDirection: TextDirection.rtl,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: GestureDetector(
              onTap: onToggle,
              child: Text(
                dhikr.arabic,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: TarfTokens.fontArabic,
                  fontSize: 52,
                  height: 2.0,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        if (showTransliteration) ...[
          const SizedBox(height: TarfTokens.space3),
          Text(
            dhikr.transliteration,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: t.dhikrTranslit),
          ),
        ],
        const SizedBox(height: TarfTokens.space2),
        Text(
          dhikr.english,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: t.dhikrEnglish),
        ),
        const SizedBox(height: TarfTokens.space2),
        Text(
          dhikr.reference,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: t.dhikrSource),
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
      return FilledButton(onPressed: onFinish, child: Text(l10n.actionDone));
    }
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
          OutlinedButton(onPressed: onSkip, child: Text(l10n.actionSkip)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track});

  /// 1.0 = full (start), 0.0 = empty (end). Depletes clockwise in both LTR/RTL.
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
      old.progress != progress || old.color != color || old.track != track;
}
