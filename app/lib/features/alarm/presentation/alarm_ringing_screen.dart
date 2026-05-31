import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/alarm_item.dart';

/// The full-screen alarm-ringing modal (design §8.12): an oversized tabular time
/// hero, the alarm label, and two stacked pills — Snooze (tonal) / Stop (filled).
/// Calm dark ground, no tab bar. Used by the foreground alarm watcher and
/// reachable as a preview route.
class AlarmRingingScreen extends ConsumerWidget {
  const AlarmRingingScreen({
    super.key,
    required this.item,
    this.onSnooze,
    this.onStop,
  });

  final AlarmItem item;
  final VoidCallback? onSnooze;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );
    final time =
        '${Numerals.padded(item.hour, n)}:${Numerals.padded(item.minute, n)}';

    void stop() => onStop != null ? onStop!() : context.pop();
    void snooze() => onSnooze != null ? onSnooze!() : context.pop();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TarfTokens.space5),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Icon(Icons.alarm, size: 44, color: scheme.primary),
              const SizedBox(height: TarfTokens.space4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: TarfTimeText(
                  time,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              if (item.label.isNotEmpty) ...[
                const SizedBox(height: TarfTokens.space2),
                Text(
                  item.label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              const Spacer(flex: 4),
              FilledButton.tonal(
                onPressed: snooze,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(l10n.actionSnooze),
              ),
              const SizedBox(height: TarfTokens.space3),
              FilledButton(
                onPressed: stop,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(l10n.actionStop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
