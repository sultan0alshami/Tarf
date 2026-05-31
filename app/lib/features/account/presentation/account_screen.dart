import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/local_data_manager.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../alarm/application/alarms_controller.dart';
import '../../eyecare/application/eyecare_config_controller.dart';
import '../../focus/application/focus_controller.dart';
import '../../insights/application/progress_controller.dart';
import '../../todos/application/todos_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tarf = context.tarf;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final chevron = isRtl ? Icons.chevron_left : Icons.chevron_right;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          // 1. Guest profile card.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TarfTokens.space4),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tarf.accentContainer,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: scheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: TarfTokens.space3),
                  Expanded(
                    child: Text(
                      l10n.accountGuest,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: TarfTokens.space2),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: TarfTokens.space2,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tarf.accentContainer,
                      borderRadius: BorderRadius.circular(TarfTokens.radiusL),
                    ),
                    child: Text(
                      l10n.syncStatusOffline,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: TarfTokens.space4),

          // 2. Sign-in (disabled — Firebase not wired yet).
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.login),
            label: Text(l10n.signInGoogle),
          ),
          const SizedBox(height: TarfTokens.space2),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.apple),
            label: Text(l10n.signInApple),
          ),
          const SizedBox(height: TarfTokens.space2),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.email_outlined),
            label: Text(l10n.signInEmail),
          ),
          const SizedBox(height: TarfTokens.space2),
          Center(
            child: Text(
              l10n.comingSoon,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tarf.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: TarfTokens.space4),

          // 3. Data management.
          TarfGroup(
            children: [
              TarfListRow(
                icon: Icons.download_outlined,
                iconColor: scheme.primary,
                title: l10n.exportData,
                trailing: Icon(chevron, color: scheme.onSurfaceVariant),
                onTap: () => _export(context, ref),
              ),
              TarfListRow(
                icon: Icons.delete_outline,
                iconColor: scheme.error,
                title: l10n.deleteAllData,
                titleColor: scheme.error,
                trailing: Icon(chevron, color: scheme.error),
                onTap: () => _deleteAll(context, ref),
              ),
            ],
          ),

          const SizedBox(height: TarfTokens.space2),

          // 4. Delete-all caption.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TarfTokens.space3),
            child: Text(
              l10n.deleteAllConfirm,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tarf.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
