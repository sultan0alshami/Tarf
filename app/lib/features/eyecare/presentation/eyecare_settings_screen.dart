import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/eyecare_config_controller.dart';
import '../domain/eyecare_config.dart';

class EyeCareSettingsScreen extends ConsumerWidget {
  const EyeCareSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(eyeCareConfigProvider);
    final controller = ref.read(eyeCareConfigProvider.notifier);
    final numerals = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    void update(EyeCareConfig next) => controller.update(next);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eyeCareTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.eyeCareEnabled),
            value: config.enabled,
            onChanged: (v) => update(config.copyWith(enabled: v)),
          ),
          const Divider(),
          _SliderTile(
            title: l10n.reminderInterval,
            valueLabel: l10n.minutesShort(config.eyeInterval.inMinutes),
            value: config.eyeInterval.inMinutes.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            onChanged: (v) =>
                update(config.copyWith(eyeInterval: Duration(minutes: v.round()))),
          ),
          _SliderTile(
            title: l10n.breakLength,
            valueLabel: l10n.secondsShort(config.eyeBreakDuration.inSeconds),
            value: config.eyeBreakDuration.inSeconds.toDouble(),
            min: 10,
            max: 60,
            divisions: 10,
            onChanged: (v) => update(
              config.copyWith(eyeBreakDuration: Duration(seconds: v.round())),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.twoTierBreaks),
            value: config.twoTierEnabled,
            onChanged: (v) => update(config.copyWith(twoTierEnabled: v)),
          ),
          if (config.twoTierEnabled) ...[
            _SliderTile(
              title: l10n.longBreakInterval,
              valueLabel: l10n.minutesShort(config.longInterval.inMinutes),
              value: config.longInterval.inMinutes.toDouble(),
              min: 30,
              max: 120,
              divisions: 9,
              onChanged: (v) => update(
                config.copyWith(longInterval: Duration(minutes: v.round())),
              ),
            ),
            _SliderTile(
              title: l10n.longBreakLength,
              valueLabel: l10n.minutesShort(config.longBreakDuration.inMinutes),
              value: config.longBreakDuration.inMinutes.toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
              onChanged: (v) => update(
                config.copyWith(longBreakDuration: Duration(minutes: v.round())),
              ),
            ),
          ],
          const Divider(),
          SwitchListTile(
            title: Text(l10n.strictMode),
            value: config.strict,
            onChanged: (v) => update(config.copyWith(strict: v)),
          ),
          SwitchListTile(
            title: Text(l10n.soundLabel),
            value: config.soundEnabled,
            onChanged: (v) => update(config.copyWith(soundEnabled: v)),
          ),
          SwitchListTile(
            title: Text(l10n.hapticsLabel),
            value: config.hapticEnabled,
            onChanged: (v) => update(config.copyWith(hapticEnabled: v)),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.prayerPauseLabel),
            value: config.prayerPauseEnabled,
            onChanged: (v) => update(config.copyWith(prayerPauseEnabled: v)),
          ),
          SwitchListTile(
            title: Text(l10n.loudThroughSilenceLabel),
            value: config.loudThroughSilence,
            onChanged: (v) => update(config.copyWith(loudThroughSilence: v)),
          ),
          const SizedBox(height: TarfTokens.space4),
          // Tiny live summary using the chosen numeral system.
          Center(
            child: Text(
              '${Numerals.formatInt(config.eyeInterval.inMinutes, numerals)}'
              ' · ${Numerals.formatInt(config.eyeBreakDuration.inSeconds, numerals)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: TarfTokens.space4),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              Text(valueLabel,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
