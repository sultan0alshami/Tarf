import '../../../core/audio/sound_catalog.dart';

/// Sound ids a saved timer can use. Re-exports Phase 1's canonical
/// [SoundCatalog.alarmIds] (default/bell/chime/calm) so per-timer sound stays in
/// lockstep with the alarm editor and their existing l10n keys
/// (soundDefault/soundBell/soundChime/soundCalm).
const String kDefaultTimerSoundId = 'default';
const List<String> timerSoundIds = SoundCatalog.alarmIds;

/// The l10n key for a sound id (label resolved in the widget layer).
String timerSoundL10nKey(String id) => switch (id) {
      'bell' => 'soundBell',
      'chime' => 'soundChime',
      'calm' => 'soundCalm',
      _ => 'soundDefault',
    };
