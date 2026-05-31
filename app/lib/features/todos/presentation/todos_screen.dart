import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../focus/application/focus_controller.dart';
import '../application/todos_controller.dart';

class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key});

  Future<void> _addDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final textController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addTask),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.taskHint),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: Text(l10n.actionDone),
          ),
        ],
      ),
    );
    if (title != null && title.trim().isNotEmpty) {
      await ref.read(todosControllerProvider.notifier).add(
            title,
            nowMs: DateTime.now().millisecondsSinceEpoch,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final todos = ref.watch(todosControllerProvider);
    final controller = ref.read(todosControllerProvider.notifier);
    final numerals = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tasks)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(context, ref),
        tooltip: l10n.addTask,
        child: const Icon(Icons.add),
      ),
      body: todos.isEmpty
          ? Center(
              child: Text(l10n.noTasks,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, i) {
                final t = todos[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: scheme.errorContainer,
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsetsDirectional.only(end: 24),
                    child: Icon(Icons.delete, color: scheme.onErrorContainer),
                  ),
                  onDismissed: (_) => controller.remove(t.id),
                  child: ListTile(
                    leading: Checkbox(
                      value: t.done,
                      onChanged: (_) => controller.toggle(t.id),
                    ),
                    title: Text(
                      t.title,
                      style: t.done
                          ? TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: scheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                    subtitle: Text(
                      '${Numerals.formatInt(t.actualSessions, numerals)}'
                      ' / ${Numerals.formatInt(t.estimatedSessions, numerals)}'
                      ' ${l10n.estLabel}',
                    ),
                    trailing: t.done
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.play_circle_outline),
                            tooltip: l10n.startFocus,
                            onPressed: () {
                              ref
                                  .read(focusControllerProvider.notifier)
                                  .startWork(taskId: t.id);
                              Navigator.of(context).pop();
                            },
                          ),
                  ),
                );
              },
            ),
    );
  }
}
