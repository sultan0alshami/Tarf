import 'package:flutter/material.dart';

import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// Licenses & Credits screen — renders the asset provenance ledger and surfaces
/// Flutter's built-in package license registry. Accessible from Settings.
///
/// (I can prep): This screen is the in-app companion to assets_ledger/ledger.json.
/// It shows fonts, dhikr content provenance, and an entry point to the full
/// Flutter LicenseRegistry page, satisfying Apple/Play account-deletion-adjacent
/// transparency requirements. See docs/store/release-checklist.md §B.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.licensesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          // ── Fonts ──────────────────────────────────────────────────────────
          TarfSectionHeader(l10n.licensesSubtitleFonts),
          TarfGroup(
            children: [
              _LicenseRow(
                name: 'Amiri',
                author: 'Khaled Hosny',
                license: l10n.licensesSilOfl,
                url: 'https://github.com/aliftype/amiri',
              ),
              _LicenseRow(
                name: 'Inter',
                author: 'Rasmus Andersson',
                license: l10n.licensesSilOfl,
                url: 'https://github.com/rsms/inter',
              ),
            ],
          ),

          // ── Dhikr content ─────────────────────────────────────────────────
          TarfSectionHeader(l10n.licensesSubtitleContent),
          TarfGroup(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  TarfTokens.space3,
                  TarfTokens.space3,
                  TarfTokens.space3,
                  TarfTokens.space3,
                ),
                child: Text(
                  l10n.licensesDhikrNote,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),

          // ── Audio ─────────────────────────────────────────────────────────
          TarfSectionHeader(l10n.licensesSubtitleAudio),
          TarfGroup(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  TarfTokens.space3,
                  TarfTokens.space3,
                  TarfTokens.space3,
                  TarfTokens.space3,
                ),
                child: Text(
                  l10n.licensesAudioNote,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),

          // ── Key open-source packages ───────────────────────────────────────
          TarfSectionHeader(l10n.licensesSubtitlePackages),
          TarfGroup(
            children: [
              _LicenseRow(
                name: 'Flutter & Dart SDK',
                author: 'Google LLC',
                license: l10n.licensesBsd3,
                url: 'https://github.com/flutter/flutter/blob/master/LICENSE',
              ),
              _LicenseRow(
                name: 'flutter_riverpod',
                author: 'Remi Rousselet',
                license: l10n.licensesMit,
                url: 'https://github.com/rrousselGit/riverpod/blob/master/LICENSE',
              ),
              _LicenseRow(
                name: 'go_router',
                author: 'Flutter team',
                license: l10n.licensesBsd3,
                url: 'https://pub.dev/packages/go_router',
              ),
              _LicenseRow(
                name: 'drift',
                author: 'Simon Binder',
                license: l10n.licensesMit,
                url: 'https://pub.dev/packages/drift',
              ),
              _LicenseRow(
                name: 'just_audio',
                author: 'Ryan Heise',
                license: l10n.licensesApache2,
                url: 'https://pub.dev/packages/just_audio',
              ),
              _LicenseRow(
                name: 'adhan',
                author: 'Batoul Apps',
                license: l10n.licensesMit,
                url: 'https://pub.dev/packages/adhan',
              ),
            ],
          ),

          // ── Full license registry ──────────────────────────────────────────
          const SizedBox(height: TarfTokens.space3),
          TarfGroup(
            children: [
              TarfListRow(
                icon: Icons.article_outlined,
                title: l10n.licensesViewAll,
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Tarf — طَرْف',
                  applicationLegalese:
                      '© 2026 Tarf. Built with Flutter.',
                ),
              ),
            ],
          ),

          const SizedBox(height: TarfTokens.space5),
        ],
      ),
    );
  }
}

/// A single row in the licenses list showing the asset/package name, author,
/// and license type. RTL-correct via [TarfListRow].
class _LicenseRow extends StatelessWidget {
  const _LicenseRow({
    required this.name,
    required this.author,
    required this.license,
    required this.url,
  });

  final String name;
  final String author;
  final String license;
  final String url;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        TarfTokens.space3,
        TarfTokens.space2 + 2,
        TarfTokens.space3,
        TarfTokens.space2 + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  author,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  license,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
