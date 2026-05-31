import 'package:flutter/foundation.dart';

@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    this.done = false,
    this.estimatedSessions = 1,
    this.actualSessions = 0,
    this.createdAtMs = 0,
  });

  final String id;
  final String title;
  final bool done;
  final int estimatedSessions;
  final int actualSessions;
  final int createdAtMs;

  Todo copyWith({
    String? title,
    bool? done,
    int? estimatedSessions,
    int? actualSessions,
  }) =>
      Todo(
        id: id,
        title: title ?? this.title,
        done: done ?? this.done,
        estimatedSessions: estimatedSessions ?? this.estimatedSessions,
        actualSessions: actualSessions ?? this.actualSessions,
        createdAtMs: createdAtMs,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'est': estimatedSessions,
        'act': actualSessions,
        'ts': createdAtMs,
      };

  factory Todo.fromJson(Map<String, Object?> j) => Todo(
        id: j['id']! as String,
        title: j['title']! as String,
        done: (j['done'] as bool?) ?? false,
        estimatedSessions: (j['est'] as int?) ?? 1,
        actualSessions: (j['act'] as int?) ?? 0,
        createdAtMs: (j['ts'] as int?) ?? 0,
      );
}
