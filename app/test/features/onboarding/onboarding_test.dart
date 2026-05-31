import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/app.dart';
import 'package:tarf/core/settings/settings_controller.dart';

void main() {
  testWidgets('first launch shows onboarding; completing it reaches the shell',
      (tester) async {
    SharedPreferences.setMockInitialValues({}); // onboardingComplete = false
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TarfApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Onboarding welcome (Arabic default).
    expect(find.text('أرِح عينيك واذكر الله'), findsOneWidget);

    // Page 1 -> 2 -> 3, then "Get started".
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();

    // We are now in the main shell.
    expect(find.text('التركيز'), findsWidgets);
  });
}
