import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_haptics.dart';
import '../../../core/format/numerals.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/tasbih_controller.dart';
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
    this.showTasbih = false,
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

  /// Opt-in dhikr tally shown BELOW the sacred line. Default off so the break
  /// stays minimal for users who only recite.
  final bool showTasbih;

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
  late bool _showTasbih;

  @override
  void initState() {
    super.initState();
    _showTranslit = widget.showTransliteration;
    _showTasbih = widget.showTasbih;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
          // Equal cue: the visual bloom + audio end already mark completion;
          // this is the matching haptic (honors hapticEnabled, not reduce-motion).
          widget.haptics.cue(
            HapticKind.breakEnd,
            enabled: widget.hapticEnabled,
          );
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
          // Scrolls only when content can't fit (e.g. short screens with the
          // opt-in tasbih shown); on normal heights the Spacers lay it out
          // exactly as before so the reverent composition is unchanged.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      AnimatedBuilder(
                        animation: Listenable.merge([_controller, _breathe]),
                        builder: (context, _) {
                          final progress = _finished
                              ? 0.0
                              : 1 - _controller.value;
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
                                            ? Numerals.formatInt(
                                                0,
                                                widget.numerals,
                                              )
                                            : Numerals.formatInt(
                                                (remaining.inMilliseconds /
                                                        1000)
                                                    .ceil(),
                                                widget.numerals,
                                              ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w300,
                                            ),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const Spacer(flex: 2),
                      // The sacred block stays the sole hero, undecorated, above.
                      _DhikrView(
                        dhikr: widget.dhikr,
                        showTransliteration: _showTranslit,
                        onToggle: () =>
                            setState(() => _showTranslit = !_showTranslit),
                      ),
                      // Opt-in tasbih sits STRICTLY BELOW the sacred line, quiet and
                      // separate — never overlapping or decorating it.
                      if (_showTasbih) ...[
                        const SizedBox(height: TarfTokens.space4),
                        _TasbihPanel(
                          numerals: widget.numerals,
                          reduceMotion: widget.reduceMotion,
                          hapticEnabled: widget.hapticEnabled,
                          onHide: () => setState(() => _showTasbih = false),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(
                            top: TarfTokens.space3,
                          ),
                          child: TextButton.icon(
                            onPressed: () => setState(() => _showTasbih = true),
                            icon: const Icon(
                              Icons.touch_app_outlined,
                              size: 18,
                            ),
                            label: Text(l10n.tasbihShow),
                          ),
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
            ),
          ),
        ),
      ),
    );
  }
}

/// Opt-in, reverent dhikr tally. Renders BELOW the sacred line as a quiet,
/// compact panel: a >=44px tap target with the running count, a small
/// count/target line, and a quiet reset. A gentle completion bloom on each
/// 33/99 cycle honors reduce-motion. No streaks, badges, or commerce.
class _TasbihPanel extends ConsumerStatefulWidget {
  const _TasbihPanel({
    required this.numerals,
    required this.reduceMotion,
    required this.hapticEnabled,
    required this.onHide,
  });
  final NumeralSystem numerals;
  final bool reduceMotion;
  final bool hapticEnabled;
  final VoidCallback onHide;
  @override
  ConsumerState<_TasbihPanel> createState() => _TasbihPanelState();
}

class _TasbihPanelState extends ConsumerState<_TasbihPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void dispose() {
    _bloom.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    // Gentle haptic is independent of reduce-motion (honored separately below).
    if (widget.hapticEnabled) unawaited(HapticFeedback.selectionClick());
    await ref.read(tasbihControllerProvider.notifier).increment();
    if (!mounted) return;
    if (ref.read(tasbihControllerProvider).justCompletedCycle &&
        !widget.reduceMotion) {
      unawaited(_bloom.forward(from: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tarf;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(tasbihControllerProvider);
    final target = ref.watch(tasbihTargetProvider);
    final inCycle = state.cyclePositionFor(target);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quiet reset (icon-only; min 44px target).
            IconButton(
              tooltip: l10n.tasbihReset,
              onPressed: () =>
                  ref.read(tasbihControllerProvider.notifier).reset(),
              icon: Icon(Icons.refresh, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: TarfTokens.space3),
            Semantics(
              button: true,
              label: l10n.tasbihTapHint,
              child: GestureDetector(
                key: const ValueKey('tasbihTapTarget'),
                onTap: _tap,
                child: AnimatedBuilder(
                  animation: _bloom,
                  builder: (context, _) {
                    final glow = widget.reduceMotion ? 0.0 : _bloom.value;
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.6,
                        ),
                        border: Border.all(
                          color: Color.lerp(t.ringTrack, t.success, glow)!,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TarfTimeText(
                        Numerals.formatInt(state.count, widget.numerals),
                        style: Theme.of(context).textTheme.headlineSmall,
                        color: scheme.onSurface,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: TarfTokens.space3),
            // Hide affordance keeps the counter opt-in within the break.
            IconButton(
              tooltip: l10n.tasbihHide,
              onPressed: widget.onHide,
              icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: TarfTokens.space1),
        // Cycle progress — forced LTR so "count / target" never mirrors.
        Text(
          l10n.tasbihProgress(inCycle, target),
          textDirection: TextDirection.ltr,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: t.dhikrTranslit),
          ),
        ],
        const SizedBox(height: TarfTokens.space2),
        Text(
          dhikr.english,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: t.dhikrEnglish),
        ),
        const SizedBox(height: TarfTokens.space2),
        Text(
          dhikr.reference,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: t.dhikrSource),
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
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

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
