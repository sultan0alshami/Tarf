import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/notifications/notification_sound.dart';

void main() {
  group('NotificationSound', () {
    test('every Phase-1 catalog id maps to a distinct Android channel', () {
      const ids = ['default', 'bell', 'chime', 'calm'];
      final channels = ids.map(NotificationSound.androidChannelId).toSet();
      expect(channels.length, ids.length); // distinct
      for (final c in channels) {
        expect(c.startsWith('tarf_alarm_'), isTrue);
      }
    });

    test('unknown id falls back to default channel (never throws)', () {
      expect(NotificationSound.androidChannelId('does-not-exist'),
          NotificationSound.androidChannelId('default'));
    });

    test('default uses the system sound (null raw resource)', () {
      expect(NotificationSound.androidRawResource('default'), isNull);
    });

    test('custom ids map to a raw resource name without extension', () {
      expect(NotificationSound.androidRawResource('bell'), 'bell');
      expect(NotificationSound.androidRawResource('chime'), 'chime');
      expect(NotificationSound.androidRawResource('calm'), 'calm');
    });

    test('Apple sound file is null until real .caf assets ship (no silent lie)',
        () {
      // No bell.caf/chime.caf/calm.caf are bundled yet, so naming them would
      // make iOS/macOS fall back to silence. Until the owner drops the .caf
      // files in, every id resolves to the audible system default sound (null).
      expect(NotificationSound.appleSoundFile('default'), isNull);
      expect(NotificationSound.appleSoundFile('bell'), isNull);
      expect(NotificationSound.appleSoundFile('chime'), isNull);
      expect(NotificationSound.appleSoundFile('calm'), isNull);
    });

    test('channelName is human-readable per id', () {
      expect(NotificationSound.channelName('calm'), 'Tarf — Calm');
    });
  });
}
