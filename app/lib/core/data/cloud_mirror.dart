import 'dart:async';

import 'tarf_repository.dart';

/// Receives each local write/delete so it can mirror to the cloud. Default
/// implementation is a NO-OP, preserving local-first/offline behaviour.
abstract interface class CloudMirror {
  bool get isActive;
  Future<void> onChange(RepositoryEvent event, Object? value);
}

/// The default: does nothing. Guest mode and disabled-cloud builds use this.
class NoopCloudMirror implements CloudMirror {
  const NoopCloudMirror();
  @override
  bool get isActive => false;
  @override
  Future<void> onChange(RepositoryEvent event, Object? value) async {}
}

/// Subscribes [mirror] to [repo]'s change stream. Returns a detach callback.
/// Reading the current value happens here so the mirror stays storage-agnostic.
Future<void> Function() attachMirror(TarfRepository repo, CloudMirror mirror) {
  final sub = repo.changes.listen((event) {
    final value = event.deleted ? null : repo.read(event.key);
    // Fire-and-forget; mirror handles its own queueing/retries.
    unawaited(mirror.onChange(event, value));
  });
  return () async => sub.cancel();
}
