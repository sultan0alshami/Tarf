import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/just_audio_service.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';

void main() {
  test('JustAudioService constructs and disposes without throwing', () async {
    final svc = JustAudioService();
    expect(svc.isPlaying(AudioChannel.alarm), isFalse);
    await svc.dispose();
  });

  test('tarfAudioServiceProvider is overridable with a Fake', () {
    final fake = FakeAudioService();
    final container = ProviderContainer(
      overrides: [tarfAudioServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    expect(container.read(tarfAudioServiceProvider), same(fake));
  });
}
