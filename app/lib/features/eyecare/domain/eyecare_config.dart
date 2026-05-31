import 'package:flutter/foundation.dart';

/// A simple inclusive minute-of-day range, used for working hours.
@immutable
class MinuteRange {
  const MinuteRange(this.startMinute, this.endMinute);

  /// Minutes since midnight [0, 1440).
  final int startMinute;
  final int endMinute;

  /// Whether [minuteOfDay] falls within the range. Handles ranges that wrap
  /// past midnight (e.g. 22:00 -> 06:00).
  bool contains(int minuteOfDay) {
    if (startMinute <= endMinute) {
      return minuteOfDay >= startMinute && minuteOfDay < endMinute;
    }
    return minuteOfDay >= startMinute || minuteOfDay < endMinute;
  }

  Map<String, Object?> toJson() => {'start': startMinute, 'end': endMinute};

  factory MinuteRange.fromJson(Map<String, Object?> j) =>
      MinuteRange(j['start']! as int, j['end']! as int);
}

/// All user-editable configuration for the eye-care engine.
@immutable
class EyeCareConfig {
  const EyeCareConfig({
    this.enabled = true,
    this.eyeInterval = const Duration(minutes: 20),
    this.eyeBreakDuration = const Duration(seconds: 20),
    this.twoTierEnabled = true,
    this.longInterval = const Duration(minutes: 50),
    this.longBreakDuration = const Duration(minutes: 5),
    this.strict = false,
    this.showTransliteration = true,
    this.snoozeCapPerSession = 3,
    this.snoozePresets = const [
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(minutes: 15),
    ],
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.loudThroughSilence = false,
    this.preBreakHeadsUp = true,
    this.preBreakLeadMicro = const Duration(seconds: 10),
    this.preBreakLeadLong = const Duration(seconds: 30),
    this.idleThreshold = const Duration(minutes: 1),
    this.idleResetThreshold = const Duration(minutes: 5),
    this.workingHoursEnabled = false,
    this.workingHours,
    this.prayerPauseEnabled = false,
    this.prayerPauseWindow = const Duration(minutes: 15),
    this.prayerLatitude = 24.7136, // Riyadh by default
    this.prayerLongitude = 46.6753,
    this.prayerMethod = 'ummAlQura',
    this.prayerMadhab = 'shafi',
    this.mergeWithPomodoro = false,
  });

  final bool enabled;
  final Duration eyeInterval;
  final Duration eyeBreakDuration;
  final bool twoTierEnabled;
  final Duration longInterval;
  final Duration longBreakDuration;
  final bool strict;

  /// Whether the dhikr break shows the Latin transliteration by default.
  final bool showTransliteration;
  final int snoozeCapPerSession;
  final List<Duration> snoozePresets;
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool loudThroughSilence;
  final bool preBreakHeadsUp;
  final Duration preBreakLeadMicro;
  final Duration preBreakLeadLong;

  /// After this much continuous inactivity the timer pauses.
  final Duration idleThreshold;

  /// After this much inactivity the accumulated active time resets to zero.
  final Duration idleResetThreshold;

  final bool workingHoursEnabled;
  final MinuteRange? workingHours;
  final bool prayerPauseEnabled;
  final Duration prayerPauseWindow;
  final double prayerLatitude;
  final double prayerLongitude;
  final String prayerMethod;
  final String prayerMadhab;
  final bool mergeWithPomodoro;

  EyeCareConfig copyWith({
    bool? enabled,
    Duration? eyeInterval,
    Duration? eyeBreakDuration,
    bool? twoTierEnabled,
    Duration? longInterval,
    Duration? longBreakDuration,
    bool? strict,
    bool? showTransliteration,
    int? snoozeCapPerSession,
    List<Duration>? snoozePresets,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? loudThroughSilence,
    bool? preBreakHeadsUp,
    Duration? preBreakLeadMicro,
    Duration? preBreakLeadLong,
    Duration? idleThreshold,
    Duration? idleResetThreshold,
    bool? workingHoursEnabled,
    MinuteRange? workingHours,
    bool clearWorkingHours = false,
    bool? prayerPauseEnabled,
    Duration? prayerPauseWindow,
    double? prayerLatitude,
    double? prayerLongitude,
    String? prayerMethod,
    String? prayerMadhab,
    bool? mergeWithPomodoro,
  }) {
    return EyeCareConfig(
      enabled: enabled ?? this.enabled,
      eyeInterval: eyeInterval ?? this.eyeInterval,
      eyeBreakDuration: eyeBreakDuration ?? this.eyeBreakDuration,
      twoTierEnabled: twoTierEnabled ?? this.twoTierEnabled,
      longInterval: longInterval ?? this.longInterval,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      strict: strict ?? this.strict,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      snoozeCapPerSession: snoozeCapPerSession ?? this.snoozeCapPerSession,
      snoozePresets: snoozePresets ?? this.snoozePresets,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      loudThroughSilence: loudThroughSilence ?? this.loudThroughSilence,
      preBreakHeadsUp: preBreakHeadsUp ?? this.preBreakHeadsUp,
      preBreakLeadMicro: preBreakLeadMicro ?? this.preBreakLeadMicro,
      preBreakLeadLong: preBreakLeadLong ?? this.preBreakLeadLong,
      idleThreshold: idleThreshold ?? this.idleThreshold,
      idleResetThreshold: idleResetThreshold ?? this.idleResetThreshold,
      workingHoursEnabled: workingHoursEnabled ?? this.workingHoursEnabled,
      workingHours:
          clearWorkingHours ? null : (workingHours ?? this.workingHours),
      prayerPauseEnabled: prayerPauseEnabled ?? this.prayerPauseEnabled,
      prayerPauseWindow: prayerPauseWindow ?? this.prayerPauseWindow,
      prayerLatitude: prayerLatitude ?? this.prayerLatitude,
      prayerLongitude: prayerLongitude ?? this.prayerLongitude,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      prayerMadhab: prayerMadhab ?? this.prayerMadhab,
      mergeWithPomodoro: mergeWithPomodoro ?? this.mergeWithPomodoro,
    );
  }

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'eyeIntervalS': eyeInterval.inSeconds,
        'eyeBreakS': eyeBreakDuration.inSeconds,
        'twoTier': twoTierEnabled,
        'longIntervalS': longInterval.inSeconds,
        'longBreakS': longBreakDuration.inSeconds,
        'strict': strict,
        'showTranslit': showTransliteration,
        'snoozeCap': snoozeCapPerSession,
        'snoozePresetsS': snoozePresets.map((d) => d.inSeconds).toList(),
        'sound': soundEnabled,
        'haptic': hapticEnabled,
        'loudThroughSilence': loudThroughSilence,
        'preBreakHeadsUp': preBreakHeadsUp,
        'preLeadMicroS': preBreakLeadMicro.inSeconds,
        'preLeadLongS': preBreakLeadLong.inSeconds,
        'idleThresholdS': idleThreshold.inSeconds,
        'idleResetS': idleResetThreshold.inSeconds,
        'workingHoursEnabled': workingHoursEnabled,
        'workingHours': workingHours?.toJson(),
        'prayerPauseEnabled': prayerPauseEnabled,
        'prayerPauseWindowS': prayerPauseWindow.inSeconds,
        'prayerLat': prayerLatitude,
        'prayerLng': prayerLongitude,
        'prayerMethod': prayerMethod,
        'prayerMadhab': prayerMadhab,
        'mergeWithPomodoro': mergeWithPomodoro,
      };

  factory EyeCareConfig.fromJson(Map<String, Object?> j) {
    Duration secs(Object? v, int fallback) =>
        Duration(seconds: (v as int?) ?? fallback);
    return EyeCareConfig(
      enabled: (j['enabled'] as bool?) ?? true,
      eyeInterval: secs(j['eyeIntervalS'], 1200),
      eyeBreakDuration: secs(j['eyeBreakS'], 20),
      twoTierEnabled: (j['twoTier'] as bool?) ?? true,
      longInterval: secs(j['longIntervalS'], 3000),
      longBreakDuration: secs(j['longBreakS'], 300),
      strict: (j['strict'] as bool?) ?? false,
      showTransliteration: (j['showTranslit'] as bool?) ?? true,
      snoozeCapPerSession: (j['snoozeCap'] as int?) ?? 3,
      snoozePresets: ((j['snoozePresetsS'] as List?)?.cast<int>())
              ?.map((s) => Duration(seconds: s))
              .toList() ??
          const [Duration(minutes: 1), Duration(minutes: 5), Duration(minutes: 15)],
      soundEnabled: (j['sound'] as bool?) ?? true,
      hapticEnabled: (j['haptic'] as bool?) ?? true,
      loudThroughSilence: (j['loudThroughSilence'] as bool?) ?? false,
      preBreakHeadsUp: (j['preBreakHeadsUp'] as bool?) ?? true,
      preBreakLeadMicro: secs(j['preLeadMicroS'], 10),
      preBreakLeadLong: secs(j['preLeadLongS'], 30),
      idleThreshold: secs(j['idleThresholdS'], 60),
      idleResetThreshold: secs(j['idleResetS'], 300),
      workingHoursEnabled: (j['workingHoursEnabled'] as bool?) ?? false,
      workingHours: switch (j['workingHours']) {
        final Map<String, Object?> m => MinuteRange.fromJson(m),
        _ => null,
      },
      prayerPauseEnabled: (j['prayerPauseEnabled'] as bool?) ?? false,
      prayerPauseWindow: secs(j['prayerPauseWindowS'], 900),
      prayerLatitude: (j['prayerLat'] as num?)?.toDouble() ?? 24.7136,
      prayerLongitude: (j['prayerLng'] as num?)?.toDouble() ?? 46.6753,
      prayerMethod: (j['prayerMethod'] as String?) ?? 'ummAlQura',
      prayerMadhab: (j['prayerMadhab'] as String?) ?? 'shafi',
      mergeWithPomodoro: (j['mergeWithPomodoro'] as bool?) ?? false,
    );
  }
}
