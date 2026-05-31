import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/alarms_controller.dart';

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    await ref.read(alarmsControllerProvider.notifier).add(
          hour: picked.hour,
          minute: picked.minute,
          nowMs: DateTime.now().millisecondsSinceEpoch,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final alarms = ref.watch(alarmsControllerProvider);
    final controller = ref.read(alarmsControllerProvider.notifier);
    final mat = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alarms)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        tooltip: l10n.addAlarm,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: scheme.secondaryContainer,
            padding: const EdgeInsets.all(TarfTokens.space3),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: scheme.onSecondaryContainer),
                const SizedBox(width: TarfTokens.space2),
                Expanded(
                  child: Text(
                    l10n.alarmNativeNote,
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: alarms.isEmpty
                ? Center(
                    child: Text(l10n.noAlarms,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  )
                : ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (context, i) {
                      final a = alarms[i];
                      return Dismissible(
                        key: ValueKey(a.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: scheme.errorContainer,
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsetsDirectional.only(end: 24),
                          child: Icon(Icons.delete,
                              color: scheme.onErrorContainer),
                        ),
                        onDismissed: (_) => controller.remove(a.id),
                        child: SwitchListTile(
                          value: a.enabled,
                          onChanged: (_) => controller.toggle(a.id),
                          title: Text(
                            mat.formatTimeOfDay(
                              TimeOfDay(hour: a.hour, minute: a.minute),
                            ),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          subtitle: a.label.isEmpty ? null : Text(a.label),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
