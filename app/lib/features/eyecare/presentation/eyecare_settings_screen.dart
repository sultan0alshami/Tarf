import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/sound_catalog.dart';
import '../../../core/audio/sound_spec.dart';
import '../../../core/audio/tarf_audio_service.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/eyecare_config_controller.dart';
import '../domain/eyecare_config.dart';

/// Pushed eye-care configuration screen. Calm grouped sections that read the
/// same in light and dark, with directional padding for correct RTL mirroring.
class EyeCareSettingsScreen extends ConsumerWidget {
  const EyeCareSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cfg = ref.watch(eyeCareConfigProvider);

    void update(EyeCareConfig next) =>
        ref.read(eyeCareConfigProvider.notifier).update(next);

    // Build the "longer break" group children with collection-if so the two
    // tier sliders only appear when two-tier breaks are enabled.
    final longerBreakChildren = <Widget>[
      TarfListRow(
        title: l10n.twoTierBreaks,
        trailing: Switch(
          value: cfg.twoTierEnabled,
          onChanged: (v) => update(cfg.copyWith(twoTierEnabled: v)),
        ),
      ),
      if (cfg.twoTierEnabled)
        TarfSliderTile(
          label: l10n.longBreakInterval,
          valueLabel: l10n.minutesShort(cfg.longInterval.inMinutes),
          value: cfg.longInterval.inMinutes.toDouble().clamp(30, 120).toDouble(),
          min: 30,
          max: 120,
          divisions: 18,
          onChanged: (v) =>
              update(cfg.copyWith(longInterval: Duration(minutes: v.round()))),
        ),
      if (cfg.twoTierEnabled)
        TarfSliderTile(
          label: l10n.longBreakLength,
          valueLabel: l10n.minutesShort(cfg.longBreakDuration.inMinutes),
          value: cfg.longBreakDuration.inMinutes.toDouble().clamp(1, 15).toDouble(),
          min: 1,
          max: 15,
          divisions: 14,
          onChanged: (v) => update(
            cfg.copyWith(longBreakDuration: Duration(minutes: v.round())),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eyeCareSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          // 1. Master enable.
          TarfGroup(
            children: [
              TarfListRow(
                icon: Icons.visibility_outlined,
                title: l10n.eyeCareEnabled,
                trailing: Switch(
                  value: cfg.enabled,
                  onChanged: (v) => update(cfg.copyWith(enabled: v)),
                ),
              ),
            ],
          ),

          // 2. Core break cadence.
          TarfSectionHeader(l10n.coreBreakGroupLabel),
          TarfGroup(
            children: [
              TarfSliderTile(
                label: l10n.reminderInterval,
                valueLabel: l10n.minutesShort(cfg.eyeInterval.inMinutes),
                value: cfg.eyeInterval.inMinutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                onChanged: (v) => update(
                  cfg.copyWith(eyeInterval: Duration(minutes: v.round())),
                ),
              ),
              TarfSliderTile(
                label: l10n.breakLength,
                valueLabel: l10n.secondsShort(cfg.eyeBreakDuration.inSeconds),
                value: cfg.eyeBreakDuration.inSeconds.toDouble(),
                min: 10,
                max: 60,
                divisions: 10,
                onChanged: (v) => update(
                  cfg.copyWith(eyeBreakDuration: Duration(seconds: v.round())),
                ),
              ),
            ],
          ),

          // 3. Longer stand & stretch break.
          TarfSectionHeader(l10n.longerBreakGroupLabel),
          TarfGroup(children: longerBreakChildren),

          // 4. Behavior & alerts.
          TarfSectionHeader(l10n.behaviorAlertsGroupLabel),
          TarfGroup(
            children: [
              TarfListRow(
                title: l10n.strictMode,
                trailing: Switch(
                  value: cfg.strict,
                  onChanged: (v) => update(cfg.copyWith(strict: v)),
                ),
              ),
              TarfListRow(
                title: l10n.soundLabel,
                trailing: Switch(
                  value: cfg.soundEnabled,
                  onChanged: (v) => update(cfg.copyWith(soundEnabled: v)),
                ),
              ),
              TarfListRow(
                icon: Icons.library_music_outlined,
                title: l10n.breakSoundLabel,
                trailing: Text(
                  _soundtrackLabel(l10n, cfg.breakSoundtrack),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () =>
                    _pickBreakSound(context, ref, cfg.breakSoundtrack),
              ),
              TarfListRow(
                title: l10n.hapticsLabel,
                trailing: Switch(
                  value: cfg.hapticEnabled,
                  onChanged: (v) => update(cfg.copyWith(hapticEnabled: v)),
                ),
              ),
              TarfListRow(
                title: l10n.prayerPauseLabel,
                trailing: Switch(
                  value: cfg.prayerPauseEnabled,
                  onChanged: (v) =>
                      update(cfg.copyWith(prayerPauseEnabled: v)),
                ),
              ),
              TarfListRow(
                title: l10n.loudThroughSilenceLabel,
                trailing: Switch(
                  value: cfg.loudThroughSilence,
                  onChanged: (v) =>
                      update(cfg.copyWith(loudThroughSilence: v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Localized display name for a break soundtrack id (the curated subset).
String _soundtrackLabel(AppLocalizations l10n, String id) => switch (id) {
      'chime' => l10n.soundChime,
      _ => l10n.soundCalm,
    };

/// Bottom-sheet chooser for the dhikr-break soundtrack. Selecting an option
/// persists it and previews the sound on the dedicated preview channel so the
/// choice is audible immediately (the visual check is the equal non-audio cue).
Future<void> _pickBreakSound(
    BuildContext context, WidgetRef ref, String current) async {
  final l10n = AppLocalizations.of(context);
  final audio = ref.read(tarfAudioServiceProvider);
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) {
      final scheme = Theme.of(sheetCtx).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final id in SoundCatalog.breakSoundtrackIds)
              ListTile(
                title: Text(_soundtrackLabel(l10n, id)),
                trailing: id == current
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () {
                  final cfg = ref.read(eyeCareConfigProvider);
                  ref
                      .read(eyeCareConfigProvider.notifier)
                      .update(cfg.copyWith(breakSoundtrack: id));
                  final base = SoundCatalog.byId(id);
                  audio.play(
                    SoundSpec.synth(base.id,
                        role: SoundRole.breakBed,
                        layers: base.layers,
                        defaultDuration: base.defaultDuration,
                        gain: base.gain),
                    channel: AudioChannel.preview,
                  );
                  Navigator.of(sheetCtx).pop();
                },
              ),
          ],
        ),
      );
    },
  );
}
