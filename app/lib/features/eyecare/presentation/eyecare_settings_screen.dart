import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
