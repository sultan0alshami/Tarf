import 'package:flutter/foundation.dart';

@immutable
class AlarmItem {
  const AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.enabled = true,
    this.days = const <int>{},
    this.sound = 'default',
    this.ringDurationSeconds = 60,
    this.snoozeMinutes = 5,
  });

  final String id;
  final int hour; // 0..23
  final int minute; // 0..59
  final String label;
  final bool enabled;

  /// Weekdays to repeat on (DateTime.monday=1 .. sunday=7). Empty = one-shot.
  final Set<int> days;

  /// Sound id (e.g. 'default'); stored now, played once a native audio backend
  /// lands (see User_Actions.md).
  final String sound;

  /// How long the alarm rings before it auto-dismisses.
  final int ringDurationSeconds;

  /// Minutes added to the time when the user snoozes.
  final int snoozeMinutes;

  int get minuteOfDay => hour * 60 + minute;

  AlarmItem copyWith({
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
    Set<int>? days,
    String? sound,
    int? ringDurationSeconds,
    int? snoozeMinutes,
  }) =>
      AlarmItem(
        id: id,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        label: label ?? this.label,
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
        sound: sound ?? this.sound,
        ringDurationSeconds: ringDurationSeconds ?? this.ringDurationSeconds,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'h': hour,
        'm': minute,
        'label': label,
        'on': enabled,
        'days': days.toList(),
        'snd': sound,
        'rds': ringDurationSeconds,
        'snz': snoozeMinutes,
      };

  factory AlarmItem.fromJson(Map<String, Object?> j) => AlarmItem(
        id: j['id']! as String,
        hour: j['h']! as int,
        minute: j['m']! as int,
        label: (j['label'] as String?) ?? '',
        enabled: (j['on'] as bool?) ?? true,
        days: ((j['days'] as List?)?.cast<int>() ?? const []).toSet(),
        sound: (j['snd'] as String?) ?? 'default',
        ringDurationSeconds: (j['rds'] as int?) ?? 60,
        snoozeMinutes: (j['snz'] as int?) ?? 5,
      );
}
