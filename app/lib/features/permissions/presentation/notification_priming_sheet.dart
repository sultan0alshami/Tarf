import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// The user's decision on the priming sheet. The CALLER (not the sheet) calls
/// the OS permission API on [enable] — never prompt cold (permissions matrix).
enum PrimingChoice { enable, notNow }

/// A calm bottom sheet explaining why Tarf wants notifications and stating the
/// honest foreground-only fallback. Returns the user's [PrimingChoice].
Future<PrimingChoice> showNotificationPrimingSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final result = await showModalBottomSheet<PrimingChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(TarfTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active_outlined,
              size: 40, color: scheme.primary),
          const SizedBox(height: TarfTokens.space3),
          Text(l10n.notifPrimingTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TarfTokens.space2),
          Text(l10n.notifPrimingBody,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: TarfTokens.space4),
          FilledButton(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).pop(PrimingChoice.enable),
            child: Text(l10n.permEnable),
          ),
          const SizedBox(height: TarfTokens.space2),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(context).pop(PrimingChoice.notNow),
            child: Text(l10n.permNotNow),
          ),
        ],
      ),
    ),
  );
  return result ?? PrimingChoice.notNow;
}
