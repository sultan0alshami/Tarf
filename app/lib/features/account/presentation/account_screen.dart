import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/local_data_manager.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../alarm/application/alarms_controller.dart';
import '../../eyecare/application/eyecare_config_controller.dart';
import '../../focus/application/focus_controller.dart';
import '../../insights/application/progress_controller.dart';
import '../../todos/application/todos_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _comingSoon(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await Clipboard.setData(ClipboardData(text: LocalDataManager.exportJson(prefs)));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).dataExported)),
      );
    }
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Text(l10n.deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAllData),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await LocalDataManager.deleteAll(ref.read(sharedPreferencesProvider));
    // Reset every in-memory store so the app returns to a clean state.
    ref
      ..invalidate(settingsControllerProvider)
      ..invalidate(eyeCareConfigProvider)
      ..invalidate(focusConfigProvider)
      ..invalidate(progressControllerProvider)
      ..invalidate(todosControllerProvider)
      ..invalidate(alarmsControllerProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.dataDeleted)));
      context.go(Routes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.accountGuest),
          ),
          Padding(
            padding: const EdgeInsets.all(TarfTokens.space3),
            child: Text(
              l10n.syncSetupNote,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.login),
            label: Text(l10n.signInGoogle),
            onPressed: () => _comingSoon(context, l10n.syncSetupNote),
          ),
          const SizedBox(height: TarfTokens.space2),
          OutlinedButton.icon(
            icon: const Icon(Icons.apple),
            label: Text(l10n.signInApple),
            onPressed: () => _comingSoon(context, l10n.syncSetupNote),
          ),
          const SizedBox(height: TarfTokens.space2),
          OutlinedButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: Text(l10n.signInEmail),
            onPressed: () => _comingSoon(context, l10n.syncSetupNote),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.exportData),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: scheme.error),
            title: Text(l10n.deleteAllData, style: TextStyle(color: scheme.error)),
            onTap: () => _deleteAll(context, ref),
          ),
        ],
      ),
    );
  }
}
