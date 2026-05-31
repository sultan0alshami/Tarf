import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/numerals.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/focus_controller.dart';
import '../domain/focus_models.dart';

/// A persistent "now playing"–style strip for a running focus session, docked
/// above the tab bar (design §5/§6). Hidden when no session is active; tapping it
/// returns to the full-screen focus session. Replaces the Home hero CTA's role as
/// the single live control while a session runs.
class ActiveSessionShelf extends ConsumerWidget {
  const ActiveSessionShelf({super.key});

  String _label(AppLocalizations l10n, FocusPhase phase) => switch (phase) {
        FocusPhase.work => l10n.phaseWork,
        FocusPhase.shortBreak => l10n.phaseShortBreak,
        FocusPhase.longBreak => l10n.phaseLongBreak,
        FocusPhase.idle => l10n.tabFocus,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusControllerProvider);
    if (state.phase == FocusPhase.idle) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );
    final controller = ref.read(focusControllerProvider.notifier);
    final accent = state.isBreak ? scheme.tertiary : scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: TarfTokens.space2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TarfTokens.radiusL),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(TarfTokens.radiusL),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ring = ProgressRing(
                  progress: state.progress,
                  size: 34,
                  stroke: 4,
                  color: accent,
                );
                // Narrow (navigation rail) → compact: ring + a single control.
                if (constraints.maxWidth < 220) {
                  return Padding(
                    padding: const EdgeInsets.all(TarfTokens.space2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.push(Routes.focusSession),
                          child: ring,
                        ),
                        IconButton(
                          iconSize: 22,
                          icon: Icon(state.running
                              ? Icons.pause
                              : Icons.play_arrow),
                          onPressed:
                              state.running ? controller.pause : controller.resume,
                        ),
                      ],
                    ),
                  );
                }
                return InkWell(
                  borderRadius: BorderRadius.circular(TarfTokens.radiusL),
                  onTap: () => context.push(Routes.focusSession),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      TarfTokens.space3,
                      TarfTokens.space2,
                      TarfTokens.space2,
                      TarfTokens.space2,
                    ),
                    child: Row(
                      children: [
                        ring,
                        const SizedBox(width: TarfTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _label(l10n, state.phase),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              Text(
                                Numerals.timer(state.remaining, n),
                                textDirection: TextDirection.ltr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: state.running
                              ? l10n.actionPause
                              : l10n.actionResume,
                          icon: Icon(
                              state.running ? Icons.pause : Icons.play_arrow),
                          onPressed: state.running
                              ? controller.pause
                              : controller.resume,
                        ),
                        IconButton(
                          tooltip: l10n.actionStop,
                          icon: const Icon(Icons.stop),
                          onPressed: controller.reset,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
