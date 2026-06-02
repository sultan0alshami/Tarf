import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/local_data_manager.dart';
import '../../../core/data/repository_providers.dart';
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
import '../application/account_controller.dart';
import '../application/cloud_account.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(tarfRepositoryProvider);
    await Clipboard.setData(ClipboardData(text: exportJsonFromRepo(repo)));
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

    // Cloud-aware, repository-routed: purgeEverything always clears local and,
    // when signed in, deletes the Firestore subtree + auth account first so a
    // failure mid-way still allows a retry. Guest (signed out) clears local only.
    final account = ref.read(accountControllerProvider);
    await purgeEverything(
      repo: ref.read(tarfRepositoryProvider),
      cloudAccount: ref.read(cloudAccountProvider),
      uid: account.isSignedIn ? account.user!.uid : null,
    );
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

    final flags = ref.watch(firebaseFlagsProvider);
    final account = ref.watch(accountControllerProvider);
    final signedIn = account.isSignedIn;
    final canSignIn = flags.signInAvailable;

    final profileLabel = signedIn
        ? l10n.accountSignedInAs(
            account.user!.displayName ?? account.user!.email ?? '')
        : l10n.accountGuest;
    final chipLabel = signedIn ? l10n.syncStatusSynced : l10n.syncStatusOffline;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          // 1. Profile card (guest or signed-in).
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
                      signedIn ? Icons.person : Icons.person_outline,
                      color: scheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: TarfTokens.space3),
                  Expanded(
                    child: Text(
                      profileLabel,
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
                      chipLabel,
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

          // 2. Sign-in / sign-out. Sign-in is enabled ONLY when cloud is fully
          // available (compile flag + present config); otherwise the buttons
          // stay disabled with a "Coming soon" caption. Guest is the default.
          if (signedIn)
            OutlinedButton.icon(
              onPressed: account.busy
                  ? null
                  : () => ref.read(accountControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: Text(l10n.signOut),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: canSignIn
                  ? () => ref.read(accountControllerProvider.notifier).signInWithGoogle()
                  : null,
              icon: const Icon(Icons.login),
              label: Text(l10n.signInGoogle),
            ),
            const SizedBox(height: TarfTokens.space2),
            OutlinedButton.icon(
              onPressed: canSignIn
                  ? () => ref.read(accountControllerProvider.notifier).signInWithApple()
                  : null,
              icon: const Icon(Icons.apple),
              label: Text(l10n.signInApple),
            ),
            const SizedBox(height: TarfTokens.space2),
            OutlinedButton.icon(
              onPressed: canSignIn
                  ? () => _promptEmailSignIn(context, ref)
                  : null,
              icon: const Icon(Icons.email_outlined),
              label: Text(l10n.signInEmail),
            ),
            if (!canSignIn) ...[
              const SizedBox(height: TarfTokens.space2),
              Center(
                child: Text(
                  l10n.comingSoon,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tarf.textTertiary,
                  ),
                ),
              ),
            ],
          ],

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

  /// Minimal email sign-in prompt. The real auth happens in AccountController;
  /// only reachable when cloud is enabled (button is disabled otherwise).
  Future<void> _promptEmailSignIn(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signInEmail),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l10n.emailLabel),
            ),
            const SizedBox(height: TarfTokens.space2),
            TextField(
              controller: passCtrl,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: l10n.passwordLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.signInEmail),
          ),
        ],
      ),
    );
    if (submit != true) return;
    await ref
        .read(accountControllerProvider.notifier)
        .signInWithEmail(emailCtrl.text.trim(), passCtrl.text);
    if (context.mounted) {
      final err = ref.read(accountControllerProvider).lastError;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signInErrorGeneric)),
        );
      }
    }
  }
}
