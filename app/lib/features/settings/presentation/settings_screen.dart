import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/numerals.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../eyecare/application/eyecare_config_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tarf = context.tarf;

    final s = ref.watch(settingsControllerProvider);
    final settings = ref.read(settingsControllerProvider.notifier);
    final cfg = ref.watch(eyeCareConfigProvider);
    final eyeCare = ref.read(eyeCareConfigProvider.notifier);

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final chevron = Icon(
      isRtl ? Icons.chevron_left : Icons.chevron_right,
      color: tarf.textTertiary,
    );

    final tabularTrailing = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: tarf.textTertiary,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          // ---- Eye care ----
          TarfSectionHeader(l10n.settingsEyeCare),
          TarfGroup(
            children: [
              TarfListRow(
                icon: Icons.schedule,
                title: l10n.settingsBreakInterval,
                trailing: Text(
                  l10n.minutesShort(cfg.eyeInterval.inMinutes),
                  style: tabularTrailing,
                  textDirection: TextDirection.ltr,
                ),
              ),
              TarfListRow(
                icon: Icons.timer_outlined,
                title: l10n.settingsBreakDuration,
                trailing: Text(
                  l10n.secondsShort(cfg.eyeBreakDuration.inSeconds),
                  style: tabularTrailing,
                  textDirection: TextDirection.ltr,
                ),
              ),
              TarfListRow(
                icon: Icons.block_outlined,
                title: l10n.strictMode,
                trailing: Switch(
                  value: cfg.strict,
                  onChanged: (v) => eyeCare.update(cfg.copyWith(strict: v)),
                ),
              ),
              TarfListRow(
                icon: Icons.tune,
                title: l10n.settingsMoreEyeCare,
                trailing: chevron,
                onTap: () => context.push(Routes.eyeCareSettings),
              ),
            ],
          ),

          // ---- Dhikr & audio ----
          TarfSectionHeader(l10n.settingsDhikrAudio),
          TarfGroup(
            children: [
              TarfListRow(
                icon: Icons.translate,
                title: l10n.transliterationShow,
                trailing: Switch(
                  value: cfg.showTransliteration,
                  onChanged: (v) =>
                      eyeCare.update(cfg.copyWith(showTransliteration: v)),
                ),
              ),
              TarfListRow(
                icon: Icons.volume_up_outlined,
                title: l10n.soundLabel,
                trailing: Switch(
                  value: cfg.soundEnabled,
                  onChanged: (v) =>
                      eyeCare.update(cfg.copyWith(soundEnabled: v)),
                ),
              ),
            ],
          ),

          // ---- Appearance ----
          TarfSectionHeader(l10n.appearance),
          TarfGroup(
            children: [
              _ControlRow(
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (set) =>
                      settings.setThemeMode(set.first),
                ),
              ),
              _ControlRow(
                label: l10n.language,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'ar',
                      label: Text(l10n.languageArabic),
                    ),
                    ButtonSegment(
                      value: 'en',
                      label: Text(l10n.languageEnglish),
                    ),
                  ],
                  selected: {s.localeCode},
                  onSelectionChanged: (set) => settings.setLocale(set.first),
                ),
              ),
              TarfListRow(
                title: l10n.reduceMotion,
                trailing: Switch(
                  value: s.reduceMotion,
                  onChanged: (v) => settings.setReduceMotion(value: v),
                ),
              ),
              _ControlRow(
                label: l10n.settingsNumerals,
                child: SegmentedButton<NumeralSystem>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: NumeralSystem.western,
                      label: Text('1234'),
                    ),
                    ButtonSegment(
                      value: NumeralSystem.arabicIndic,
                      label: Text('٠١٢٣'),
                    ),
                  ],
                  selected: {s.effectiveNumerals},
                  onSelectionChanged: (set) =>
                      settings.setNumeralSystem(set.first),
                ),
              ),
            ],
          ),

          // ---- Account ----
          TarfGroup(
            children: [
              TarfListRow(
                icon: Icons.account_circle_outlined,
                title: l10n.settingsAccount,
                trailing: chevron,
                onTap: () => context.push(Routes.account),
              ),
            ],
          ),

          // ---- About ----
          TarfGroup(
            children: [
              TarfListRow(
                icon: Icons.info_outline,
                title: l10n.settingsLicenses,
                trailing: chevron,
                onTap: () => context.push(Routes.licenses),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A grouped row that hosts a full-width control (e.g. a [SegmentedButton]) with
/// an optional small leading [label]. The control scrolls horizontally if it
/// would overflow on narrow widths; RTL is honored via directional padding.
class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: TarfTokens.space3,
          vertical: TarfTokens.space2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: TarfTokens.space2),
            ],
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
