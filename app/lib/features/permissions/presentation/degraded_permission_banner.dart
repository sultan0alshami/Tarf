import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/background_delivery_status.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// A calm, honest banner that appears only when background delivery is degraded
/// (foreground-only platform, notifications denied, or exact alarms off). It
/// consumes the real [backgroundDeliveryStatusProvider] (Phase 2) and reuses
/// that phase's per-reason messages. Uses [TarfColors.warning] (never error red,
/// never alarmist) and always pairs color with an icon + text (never
/// color-alone). Renders nothing when delivery is reliable.
class DegradedPermissionBanner extends ConsumerWidget {
  const DegradedPermissionBanner({super.key, this.onOpenSettings});

  /// Optional affordance (e.g. open OS settings). Hidden when null.
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backgroundDeliveryStatusProvider);
    final reason = status.reason;
    if (reason == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final t = context.tarf;
    final body = switch (reason) {
      DegradedReason.platformForegroundOnly => l10n.bgForegroundOnlyPlatform,
      DegradedReason.notificationsDenied => l10n.bgRemindersOff,
      DegradedReason.exactAlarmDenied => l10n.bgExactAlarmOff,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: TarfTokens.space3),
      padding: const EdgeInsets.all(TarfTokens.space3),
      decoration: BoxDecoration(
        color: t.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(TarfTokens.radiusM),
        border: Border.all(color: t.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equal non-color cue: the meaning never rides on color alone.
          Icon(Icons.warning_amber_rounded, color: t.warning, size: 24),
          const SizedBox(width: TarfTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.permBannerTitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: t.warningText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: t.warningText),
                ),
                if (onOpenSettings != null) ...[
                  const SizedBox(height: TarfTokens.space2),
                  TextButton(
                    onPressed: onOpenSettings,
                    child: Text(l10n.permOpenSettings),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
