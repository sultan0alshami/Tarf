import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/firebase/firebase_flags.dart';

void main() {
  test('cloud is disabled by default (no dart-define, no config)', () {
    const flags = FirebaseFlags(configPresent: false);
    expect(flags.cloudEnabled, isFalse);
    expect(flags.signInAvailable, isFalse);
  });

  test('cloud requires BOTH the compile flag and present config', () {
    // compileEnabled is injected for testability; in prod it reads
    // const bool.fromEnvironment('TARF_CLOUD').
    expect(const FirebaseFlags(configPresent: true, compileEnabled: false).cloudEnabled, isFalse);
    expect(const FirebaseFlags(configPresent: false, compileEnabled: true).cloudEnabled, isFalse);
    expect(const FirebaseFlags(configPresent: true, compileEnabled: true).cloudEnabled, isTrue);
    expect(const FirebaseFlags(configPresent: true, compileEnabled: true).signInAvailable, isTrue);
  });
}
