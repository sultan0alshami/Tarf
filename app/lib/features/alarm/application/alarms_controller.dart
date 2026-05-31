import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../domain/alarm_item.dart';

const _key = 'tarf.alarms.v1';

class AlarmsController extends Notifier<List<AlarmItem>> {
  @override
  List<AlarmItem> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, Object?>>()
          .map(AlarmItem.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<AlarmItem> next) async {
    final sorted = [...next]..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    state = sorted;
    await ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode(sorted.map((a) => a.toJson()).toList()),
        );
  }

  Future<void> add({
    required int hour,
    required int minute,
    String label = '',
    Set<int> days = const {},
    required int nowMs,
  }) =>
      _persist([
        ...state,
        AlarmItem(id: 'a$nowMs', hour: hour, minute: minute, label: label, days: days),
      ]);

  Future<void> toggle(String id) => _persist([
        for (final a in state)
          if (a.id == id) a.copyWith(enabled: !a.enabled) else a,
      ]);

  Future<void> remove(String id) =>
      _persist([for (final a in state) if (a.id != id) a]);
}

final alarmsControllerProvider =
    NotifierProvider<AlarmsController, List<AlarmItem>>(AlarmsController.new);
