import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'just_audio_service.dart';
import 'tarf_audio_service.dart';

/// The shared audio engine. Defaults to silence in pure tests (no real audio in
/// `flutter test`); overridden in `main()` with the real [JustAudioService] and
/// in tests with a [FakeAudioService]. Phase 2/3 read this same provider.
final tarfAudioServiceProvider = Provider<TarfAudioService>((ref) {
  // In the widget tree (real app) this is overridden in main(); the bare default
  // is Silent so any test that forgets to override never touches platform audio.
  return const SilentAudioService();
});

/// Builds the real engine. Call once from `main()` to override the provider:
///   tarfAudioServiceProvider.overrideWith((ref) {
///     final svc = buildRealAudioService();
///     ref.onDispose(svc.dispose);
///     return svc;
///   })
TarfAudioService buildRealAudioService() => JustAudioService();

/// Whether we are on web (autoplay needs a user gesture). Exposed for tests.
final isWebProvider = Provider<bool>((ref) => kIsWeb);
