import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../focus/application/focus_controller.dart';
import '../application/todos_controller.dart';
import '../domain/todo.dart';

class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key});

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final textController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.addTask),
          content: TextField(
            controller: textController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: l10n.taskHint),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(textController.text),
              child: Text(l10n.actionDone),
            ),
          ],
        );
      },
    );
    final trimmed = text?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      await ref.read(todosControllerProvider.notifier).add(
            trimmed,
            nowMs: DateTime.now().millisecondsSinceEpoch,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todos = ref.watch(todosControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasks),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addTask,
            onPressed: () => _addTask(context, ref),
          ),
        ],
      ),
      body: todos.isEmpty
          ? TarfEmptyState(
              icon: Icons.check_circle_outline,
              message: l10n.todosEmptyLine,
              actionLabel: l10n.addTask,
              onAction: () => _addTask(context, ref),
            )
          : ListView(
              padding: const EdgeInsets.all(TarfTokens.space3),
              children: [
                TarfGroup(
                  children: [
                    for (final todo in todos) _TodoRow(todo: todo),
                  ],
                ),
              ],
            ),
    );
  }
}

class _TodoRow extends ConsumerWidget {
  const _TodoRow({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: TarfTokens.space3,
        vertical: TarfTokens.space2,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Checkbox(
                value: todo.done,
                shape: const CircleBorder(),
                onChanged: (_) => ref
                    .read(todosControllerProvider.notifier)
                    .toggle(todo.id),
              ),
            ),
            const SizedBox(width: TarfTokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    todo.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: todo.done
                          ? context.tarf.textTertiary
                          : scheme.onSurface,
                      decoration:
                          todo.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.todoSessions(
                      todo.actualSessions,
                      todo.estimatedSessions,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (!todo.done)
              IconButton(
                icon: Icon(
                  Icons.play_circle_outline,
                  color: scheme.primary,
                ),
                tooltip: l10n.startFocus,
                onPressed: () {
                  ref.read(focusControllerProvider.notifier).startWork();
                  context.push(Routes.focusSession);
                },
              ),
          ],
        ),
      ),
    );
  }
}
