import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../domain/saved_timer.dart';

const _key = 'tarf.saved_timers.v1';

/// Persisted list of saved timers (label + duration + soundId). Mirrors the
/// AlarmsController persistence pattern.
class SavedTimersController extends Notifier<List<SavedTimer>> {
  @override
  List<SavedTimer> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, Object?>>()
          .map(SavedTimer.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<SavedTimer> next) async {
    state = next;
    await ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode(next.map((t) => t.toJson()).toList()),
        );
  }

  /// Adds [item] if its id is new, otherwise replaces the timer with that id.
  Future<void> upsert(SavedTimer item) {
    final exists = state.any((t) => t.id == item.id);
    final next = exists
        ? [for (final t in state) if (t.id == item.id) item else t]
        : [...state, item];
    return _persist(next);
  }

  Future<void> remove(String id) =>
      _persist([for (final t in state) if (t.id != id) t]);
}

final savedTimersControllerProvider =
    NotifierProvider<SavedTimersController, List<SavedTimer>>(
  SavedTimersController.new,
);
