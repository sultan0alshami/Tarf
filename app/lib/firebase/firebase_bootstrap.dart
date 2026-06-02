import 'package:firebase_core/firebase_core.dart';

/// Result of attempting to bring Firebase online at startup.
class FirebaseAvailability {
  const FirebaseAvailability({required this.ready});
  final bool ready;
}

/// Initializes Firebase only if the master compile flag is on. Any failure
/// (missing config, emulator down) degrades gracefully to guest mode.
///
/// [optionsLoader] returns the generated FirebaseOptions; it is null until the
/// owner runs `flutterfire configure`. We accept it as a parameter so this file
/// compiles WITHOUT firebase_options.dart present.
Future<FirebaseAvailability> bootstrapFirebase({
  required bool compileEnabled,
  Future<FirebaseOptions>? Function()? optionsLoader,
}) async {
  if (!compileEnabled || optionsLoader == null) {
    return const FirebaseAvailability(ready: false);
  }
  try {
    final options = await optionsLoader();
    if (options == null) return const FirebaseAvailability(ready: false);
    await Firebase.initializeApp(options: options);
    return const FirebaseAvailability(ready: true);
  } catch (_) {
    return const FirebaseAvailability(ready: false);
  }
}
