import 'package:flutter/foundation.dart';

import 'timer_sound_catalog.dart';

/// A user-saved, named countdown preset. Loaded into the single TimerController
/// runner via runSaved(). Immutable; persisted as JSON in a list.
@immutable
class SavedTimer {
  const SavedTimer({
    required this.id,
    required this.label,
    required this.duration,
    this.soundId = kDefaultTimerSoundId,
  });

  final String id;
  final String label;
  final Duration duration;
  final String soundId;

  SavedTimer copyWith({
    String? label,
    Duration? duration,
    String? soundId,
  }) =>
      SavedTimer(
        id: id,
        label: label ?? this.label,
        duration: duration ?? this.duration,
        soundId: soundId ?? this.soundId,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'durS': duration.inSeconds,
        'snd': soundId,
      };

  factory SavedTimer.fromJson(Map<String, Object?> j) => SavedTimer(
        id: j['id']! as String,
        label: (j['label'] as String?) ?? '',
        duration: Duration(seconds: (j['durS'] as int?) ?? 0),
        soundId: (j['snd'] as String?) ?? kDefaultTimerSoundId,
      );
}
