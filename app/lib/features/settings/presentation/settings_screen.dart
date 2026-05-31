import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: Text(l10n.eyeCareTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.eyeCareSettings),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.accountTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.account),
          ),
          const Divider(),
          _SectionHeader(l10n.appearance),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (m) => controller.setThemeMode(m ?? ThemeMode.system),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text(l10n.themeSystem),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text(l10n.themeLight),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text(l10n.themeDark),
                ),
              ],
            ),
          ),
          SwitchListTile(
            value: settings.reduceMotion,
            onChanged: (v) => controller.setReduceMotion(value: v),
            title: Text(l10n.reduceMotion),
          ),
          const Divider(),
          _SectionHeader(l10n.language),
          RadioGroup<String>(
            groupValue: settings.localeCode,
            onChanged: (c) => controller.setLocale(c ?? 'ar'),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'ar',
                  title: Text(l10n.languageArabic),
                ),
                RadioListTile<String>(
                  value: 'en',
                  title: Text(l10n.languageEnglish),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: scheme.primary),
      ),
    );
  }
}
