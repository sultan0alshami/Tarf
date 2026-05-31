import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/alarms_controller.dart';
import '../domain/alarm_item.dart';

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  Future<void> _addAlarm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return;
    if (!context.mounted) return;

    final labelController = TextEditingController();
    var daily = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.alarmLabelHint,
                    ),
                  ),
                  const SizedBox(height: TarfTokens.space2),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.alarmRepeatDaily),
                    value: daily,
                    onChanged: (v) => setState(() => daily = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(alarmsControllerProvider.notifier).add(
          hour: t.hour,
          minute: t.minute,
          label: labelController.text.trim(),
          days: daily ? const {1, 2, 3, 4, 5, 6, 7} : const {},
          nowMs: DateTime.now().millisecondsSinceEpoch,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final alarms = ref.watch(alarmsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alarms),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addAlarm,
            onPressed: () => _addAlarm(context, ref),
          ),
        ],
      ),
      body: alarms.isEmpty
          ? TarfEmptyState(
              icon: Icons.alarm,
              message: l10n.noAlarms,
              actionLabel: l10n.addAlarm,
              onAction: () => _addAlarm(context, ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(TarfTokens.space3),
              itemCount: alarms.length + 1,
              itemBuilder: (context, i) {
                if (i == alarms.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: TarfTokens.space4),
                    child: Text(
                      l10n.alarmNativeNote,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.tarf.warningText),
                    ),
                  );
                }

                final a = alarms[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: TarfTokens.space2),
                  child: Card(
                    child: Dismissible(
                      key: ValueKey(a.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius:
                              BorderRadius.circular(TarfTokens.radiusM),
                        ),
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsetsDirectional.only(
                          end: TarfTokens.space4,
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(alarmsControllerProvider.notifier)
                            .remove(a.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.alarmDeleted)),
                        );
                      },
                      child: _AlarmRow(item: a),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AlarmRow extends ConsumerWidget {
  const _AlarmRow({required this.item});

  final AlarmItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    final timeText =
        '${Numerals.padded(item.hour, n)}:${Numerals.padded(item.minute, n)}';
    final repeat = _repeatLabel(item.days, l10n);
    final hasLabel = item.label.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(TarfTokens.space3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TarfTimeText(
                  timeText,
                  style: textTheme.headlineMedium,
                  color: item.enabled
                      ? scheme.onSurface
                      : context.tarf.textTertiary,
                ),
                const SizedBox(height: 2),
                Text(
                  hasLabel ? item.label : repeat,
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (hasLabel)
                  Text(
                    repeat,
                    style: textTheme.bodySmall
                        ?.copyWith(color: context.tarf.textTertiary),
                  ),
              ],
            ),
          ),
          Switch(
            value: item.enabled,
            onChanged: (_) =>
                ref.read(alarmsControllerProvider.notifier).toggle(item.id),
          ),
        ],
      ),
    );
  }

  String _repeatLabel(Set<int> days, AppLocalizations l10n) {
    if (days.isEmpty) return l10n.alarmRepeatOnce;
    if (days.length == 7) return l10n.alarmRepeatDaily;
    final sorted = days.toList()..sort();
    if (_listEquals(sorted, const [1, 2, 3, 4, 5])) {
      return l10n.alarmRepeatWeekdays;
    }
    if (_listEquals(sorted, const [6, 7])) {
      return l10n.alarmRepeatWeekends;
    }
    return l10n.alarmRepeatCustom;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
