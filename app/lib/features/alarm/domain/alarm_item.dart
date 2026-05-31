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
  });

  final String id;
  final int hour; // 0..23
  final int minute; // 0..59
  final String label;
  final bool enabled;

  /// Weekdays to repeat on (DateTime.monday=1 .. sunday=7). Empty = one-shot.
  final Set<int> days;

  int get minuteOfDay => hour * 60 + minute;

  AlarmItem copyWith({
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
    Set<int>? days,
  }) =>
      AlarmItem(
        id: id,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        label: label ?? this.label,
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'h': hour,
        'm': minute,
        'label': label,
        'on': enabled,
        'days': days.toList(),
      };

  factory AlarmItem.fromJson(Map<String, Object?> j) => AlarmItem(
        id: j['id']! as String,
        hour: j['h']! as int,
        minute: j['m']! as int,
        label: (j['label'] as String?) ?? '',
        enabled: (j['on'] as bool?) ?? true,
        days: ((j['days'] as List?)?.cast<int>() ?? const []).toSet(),
      );
}
