import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../eyecare/application/eyecare_config_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  static const _lastPage = 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _lastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      ref.read(settingsControllerProvider.notifier).completeOnboarding();
      context.go(Routes.focus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _page = p),
                children: const [
                  _WelcomePage(),
                  _ThemePage(),
                  _QuickSetupPage(),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i <= _lastPage; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.all(4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(TarfTokens.space4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page == _lastPage ? l10n.onbGetStarted : l10n.onbNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends ConsumerWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(TarfTokens.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility_outlined, size: 88, color: scheme.primary),
          const SizedBox(height: TarfTokens.space4),
          Text(
            l10n.onbTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: TarfTokens.space3),
          Text(
            l10n.onbBody,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TarfTokens.space5),
          Text(l10n.onbChooseLanguage,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: TarfTokens.space2),
          Wrap(
            spacing: TarfTokens.space2,
            children: [
              ChoiceChip(
                label: Text(l10n.languageArabic),
                selected: settings.localeCode == 'ar',
                onSelected: (_) => controller.setLocale('ar'),
              ),
              ChoiceChip(
                label: Text(l10n.languageEnglish),
                selected: settings.localeCode == 'en',
                onSelected: (_) => controller.setLocale('en'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemePage extends ConsumerWidget {
  const _ThemePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(TarfTokens.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.onbChooseTheme,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: TarfTokens.space4),
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
        ],
      ),
    );
  }
}

class _QuickSetupPage extends ConsumerWidget {
  const _QuickSetupPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(eyeCareConfigProvider);
    final controller = ref.read(eyeCareConfigProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(TarfTokens.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onbQuickSetup,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: TarfTokens.space4),
          Text(
            '${l10n.reminderInterval}: '
            '${l10n.minutesShort(config.eyeInterval.inMinutes)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: config.eyeInterval.inMinutes.toDouble().clamp(5, 60),
            min: 5,
            max: 60,
            divisions: 11,
            label: l10n.minutesShort(config.eyeInterval.inMinutes),
            onChanged: (v) => controller.update(
              config.copyWith(eyeInterval: Duration(minutes: v.round())),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.soundLabel),
            value: config.soundEnabled,
            onChanged: (v) => controller.update(config.copyWith(soundEnabled: v)),
          ),
        ],
      ),
    );
  }
}
