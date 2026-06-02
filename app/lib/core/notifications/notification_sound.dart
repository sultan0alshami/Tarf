import '../audio/sound_catalog.dart';

/// Adapter from Phase-1's sound catalog ids to platform notification sound
/// wiring. Android needs ONE channel per sound (a channel's sound is fixed at
/// creation), so each id gets its own high-importance channel. iOS/macOS pass a
/// per-notification sound file. 'default' means "the OS default alarm sound".
///
/// SINGLE SOURCE OF TRUTH for the Phase-1 → notification mapping. The ids come
/// straight from [SoundCatalog.alarmIds] (`default`/`bell`/`chime`/`calm`); if
/// Phase 1 ever changes that list, only this file follows.
abstract final class NotificationSound {
  NotificationSound._();

  /// Phase-1 catalog ids, sourced from the shared [SoundCatalog].
  static const catalogIds = SoundCatalog.alarmIds;

  static bool _known(String id) => catalogIds.contains(id);

  /// One Android channel per sound. Channels are created up-front by the
  /// gateway. Unknown ids fall back to the default channel.
  static String androidChannelId(String soundId) =>
      'tarf_alarm_${_known(soundId) ? soundId : 'default'}';

  static String channelName(String soundId) {
    final id = _known(soundId) ? soundId : 'default';
    return switch (id) {
      'bell' => 'Tarf — Bell',
      'chime' => 'Tarf — Chime',
      'calm' => 'Tarf — Calm',
      _ => 'Tarf — Default',
    };
  }

  /// Android raw resource name (`res/raw/<name>.wav`) without extension, or null
  /// for the system default sound.
  static String? androidRawResource(String soundId) {
    if (!_known(soundId) || soundId == 'default') return null;
    return soundId; // bell|chime|calm -> res/raw/{bell,chime,calm}.wav
  }

  /// iOS/macOS bundled sound file (with extension), or null for the audible
  /// system default sound.
  ///
  /// OWNER DROP-IN: this returns null for *every* id today because no
  /// `bell.caf`/`chime.caf`/`calm.caf` are bundled in the iOS/macOS Runner
  /// targets. Naming a missing file makes the OS fall back to *silence* (a
  /// silent lie), so until the owner adds real `.caf` assets — the same pattern
  /// as the reserved recitation path (`assets/audio/recitation/`) — we use the
  /// system default sound. Once the `.caf` files ship, map `bell|chime|calm` to
  /// `'$soundId.caf'` here (this is the single adapter point).
  static String? appleSoundFile(String soundId) => null;
}
