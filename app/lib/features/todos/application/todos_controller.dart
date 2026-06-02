import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/data/tarf_repository.dart';
import '../domain/todo.dart';

class TodosController extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    final raw = ref.watch(tarfRepositoryProvider).read(StorageKey.todos);
    if (raw is! List) return const [];
    try {
      return raw.cast<Map<String, Object?>>().map(Todo.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<Todo> next) async {
    state = next;
    await ref
        .read(tarfRepositoryProvider)
        .write(StorageKey.todos, next.map((t) => t.toJson()).toList());
  }

  Future<void> add(String title, {int estimated = 1, required int nowMs}) {
    final todo = Todo(
      id: 't$nowMs',
      title: title.trim(),
      estimatedSessions: estimated < 1 ? 1 : estimated,
      createdAtMs: nowMs,
    );
    return _persist([todo, ...state]);
  }

  Future<void> toggle(String id) => _persist([
        for (final t in state) if (t.id == id) t.copyWith(done: !t.done) else t,
      ]);

  Future<void> remove(String id) =>
      _persist([for (final t in state) if (t.id != id) t]);

  Future<void> incrementActual(String id) => _persist([
        for (final t in state)
          if (t.id == id) t.copyWith(actualSessions: t.actualSessions + 1) else t,
      ]);
}

final todosControllerProvider =
    NotifierProvider<TodosController, List<Todo>>(TodosController.new);
