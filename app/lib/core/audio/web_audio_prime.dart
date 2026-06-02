import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../overlay/reverent_overlay.dart';
import 'audio_providers.dart';
import 'sound_spec.dart';
import 'tarf_audio_service.dart';

/// Web-autoplay prime state. On native, [primed] is always true and [needsPrime]
/// is always false. On web, audio may be blocked until a user gesture: when a
/// play() is blocked we [reportBlocked]; the calm banner then offers [prime].
@immutable
class WebAudioPrimeState {
  const WebAudioPrimeState({
    required this.isWeb,
    this.primed = false,
    this.blocked = false,
  });
  final bool isWeb;
  final bool primed;
  final bool blocked;

  /// Show the prime affordance only on web, only after a real block, only once.
  bool get needsPrime => isWeb && blocked && !primed;

  WebAudioPrimeState copyWith({bool? primed, bool? blocked}) =>
      WebAudioPrimeState(
        isWeb: isWeb,
        primed: primed ?? this.primed,
        blocked: blocked ?? this.blocked,
      );
}

class WebAudioPrime extends Notifier<WebAudioPrimeState> {
  @override
  WebAudioPrimeState build() {
    final isWeb = ref.watch(isWebProvider);
    // Native needs no prime.
    return WebAudioPrimeState(isWeb: isWeb, primed: !isWeb);
  }

  /// Called when a play() returned false (autoplay blocked) without a gesture.
  void reportBlocked() {
    if (!state.isWeb || state.primed) return;
    if (!state.blocked) state = state.copyWith(blocked: true);
  }

  /// Tied to a user gesture: play a near-silent prime tone to unlock the audio
  /// context, then mark primed for the session.
  Future<void> prime() async {
    final audio = ref.read(tarfAudioServiceProvider);
    const primeTone = SoundSpec.synth(
      'prime',
      role: SoundRole.breakCue,
      layers: [SoundLayer(frequencyHz: 440, peak: 0.0008, decay: 20)],
      defaultDuration: Duration(milliseconds: 120),
    );
    await audio.play(primeTone, channel: AudioChannel.preview);
    // The container may be torn down during the await (e.g. test/teardown);
    // never mutate state on a disposed notifier.
    if (!ref.mounted) return;
    state = state.copyWith(primed: true, blocked: false);
  }
}

final webAudioPrimeProvider =
    NotifierProvider<WebAudioPrime, WebAudioPrimeState>(WebAudioPrime.new);

/// A calm, one-time "tap to enable sound" strip. Renders nothing unless
/// [WebAudioPrimeState.needsPrime] — and never while a reverent break overlay is
/// on screen, so it can never paint over the sacred dhikr line.
class TapToEnableSoundBanner extends ConsumerWidget {
  const TapToEnableSoundBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(webAudioPrimeProvider);
    if (!state.needsPrime) return const SizedBox.shrink();
    // Reverence: never overlay the dhikr break (this banner sits in the app
    // chrome, which `MaterialApp.router` layers above the Navigator). The break
    // claims the overlay at its push site — before the route builds — so this
    // suppression is already true on the break's first painted frame.
    if (ref.watch(reverentOverlayActiveProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TarfTokens.space3),
        child: Material(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(TarfTokens.radiusM),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ref.read(webAudioPrimeProvider.notifier).prime(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TarfTokens.space3,
                vertical: TarfTokens.space2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_outlined,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: TarfTokens.space2),
                  Flexible(
                    child: Text(
                      l10n.tapToEnableSound,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
