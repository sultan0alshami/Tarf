import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../domain/todo.dart';

const _key = 'tarf.todos.v1';

class TodosController extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, Object?>>()
          .map(Todo.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<Todo> next) async {
    state = next;
    await ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode(next.map((t) => t.toJson()).toList()),
        );
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
