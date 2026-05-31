import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../eyecare/presentation/show_break.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: l10n.navInsights,
            onPressed: () => context.push(Routes.insights),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.navSettings,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, size: 72, color: scheme.primary),
            const SizedBox(height: TarfTokens.space3),
            Text(
              l10n.eyeCareTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: TarfTokens.space2),
            Text(
              l10n.breakInstruction,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: TarfTokens.space5),
            FilledButton.icon(
              icon: const Icon(Icons.spa_outlined),
              label: Text(l10n.takeBreakNow),
              onPressed: () => showEyeBreak(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
