/// What kind of thing is being scheduled. The kind is part of every key so a
/// standard alarm and a prayer alarm with the same id never collide.
enum ScheduledKind { standardAlarm, prayerAlarm, eyeBreak }

/// One desired OS-level delivery. Pure data — no platform types. The
/// [NotificationService] turns a set of these into gateway calls.
class ScheduledItem {
  const ScheduledItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.body,
    required this.soundId,
  });

  final ScheduledKind kind;
  final String id;
  final String title;
  final String body;

  /// Phase-1 sound catalog id: 'default' | 'bell' | 'chime' | 'calm'.
  final String soundId;

  /// Stable 31-bit non-negative id for the OS notification slot. Derived from
  /// kind+id only so rescheduling the same logical alarm overwrites its slot.
  int get notificationId {
    final s = '${kind.name}:$id';
    var h = 0;
    for (final c in s.codeUnits) {
      h = 0x1fffffff & (h * 31 + c);
    }
    return h;
  }

  /// Deterministic guard key for the wall-clock [fireAt] minute.
  String guardKeyFor(DateTime fireAt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final d = '${fireAt.year}-${two(fireAt.month)}-${two(fireAt.day)}'
        '-${two(fireAt.hour)}-${two(fireAt.minute)}';
    return '${kind.name}:$id:$d';
  }

  /// Compact payload the OS hands back on tap. Carries the guard key so the
  /// tap handler can claim it (see DoubleFireGuard).
  String encodePayload(DateTime fireAt) =>
      '${kind.name}|$id|$soundId|${guardKeyFor(fireAt)}';

  static DecodedPayload decodePayload(String raw) {
    final p = raw.split('|');
    return DecodedPayload(
      kind: ScheduledKind.values.byName(p[0]),
      id: p[1],
      soundId: p[2],
      guardKey: p[3],
    );
  }
}

/// The parsed result of a tapped notification's payload.
class DecodedPayload {
  const DecodedPayload({
    required this.kind,
    required this.id,
    required this.soundId,
    required this.guardKey,
  });
  final ScheduledKind kind;
  final String id;
  final String soundId;
  final String guardKey;
}
