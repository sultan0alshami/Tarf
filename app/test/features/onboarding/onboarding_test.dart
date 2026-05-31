import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/app.dart';
import 'package:tarf/core/settings/settings_controller.dart';

// Bounded pump (avoid the never-settling live eye-care countdown).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

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
    await settle(tester);

    expect(find.text('أرِح عينيك واذكر الله'), findsOneWidget); // welcome

    await tester.tap(find.text('التالي'));
    await settle(tester);
    await tester.tap(find.text('التالي'));
    await settle(tester);
    await tester.tap(find.text('ابدأ الآن'));
    await settle(tester);

    // We are now in the main shell (Home tab).
    expect(find.text('الرئيسية'), findsWidgets);
  });
}
