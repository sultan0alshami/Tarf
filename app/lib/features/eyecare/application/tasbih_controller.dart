import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../domain/tasbih_state.dart';

const _key = 'tarf.tasbih.v1';
const _targetKey = 'tarf.tasbih_target.v1';

String _todayKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// Persisted, day-aware tasbih tally. A new day starts fresh.
class TasbihController extends Notifier<TasbihState> {
  @override
  TasbihState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    final today = _todayKey();
    if (raw == null) return TasbihState(dayKey: today);
    try {
      final stored =
          TasbihState.fromJson(jsonDecode(raw) as Map<String, Object?>);
      return stored.dayKey == today ? stored : TasbihState(dayKey: today);
    } catch (_) {
      return TasbihState(dayKey: today);
    }
  }

  Future<void> _persist(TasbihState next) async {
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(next.toJson()));
  }

  Future<void> increment() {
    final target = ref.read(tasbihTargetProvider);
    return _persist(state.increment(target: target));
  }

  Future<void> reset() => _persist(state.reset());
}

final tasbihControllerProvider =
    NotifierProvider<TasbihController, TasbihState>(TasbihController.new);

/// Persisted cycle target: 33 (default) or 99.
class TasbihTarget extends Notifier<int> {
  @override
  int build() {
    final v = ref.watch(sharedPreferencesProvider).getInt(_targetKey);
    return v == 99 ? 99 : 33;
  }

  Future<void> toggle() async {
    final next = state == 33 ? 99 : 33;
    state = next;
    await ref.read(sharedPreferencesProvider).setInt(_targetKey, next);
  }
}

final tasbihTargetProvider =
    NotifierProvider<TasbihTarget, int>(TasbihTarget.new);
