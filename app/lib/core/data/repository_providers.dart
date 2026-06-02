import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/account/application/cloud_account.dart';
import '../../firebase/firebase_flags.dart';
import '../settings/settings_controller.dart';
import 'cloud_mirror.dart';
import 'prefs_repository.dart';
import 'tarf_repository.dart';

/// The app's single persistence seam. Defaults to a [PrefsRepository] built from
/// the already-initialized [sharedPreferencesProvider], so any scope that
/// provides prefs (the app and every existing test) gets a working repository
/// for free. main() overrides it with the SAME PrefsRepository instance that
/// also has a CloudMirror attached when cloud is enabled.
final tarfRepositoryProvider = Provider<TarfRepository>(
  (ref) => PrefsRepository(ref.watch(sharedPreferencesProvider)),
);

/// The active cloud mirror. Defaults to a no-op; replaced when signed in.
final cloudMirrorProvider = Provider<CloudMirror>((ref) => const NoopCloudMirror());

/// Whether optional cloud features are available. Defaults to OFF (guest); the
/// Account screen reads it to gate sign-in. main() overrides it with the real
/// [FirebaseFlags] (compile flag + present config).
final firebaseFlagsProvider = Provider<FirebaseFlags>(
  (ref) => const FirebaseFlags(configPresent: false),
);

/// Deletes the user's cloud footprint on delete-all. Defaults to an in-memory
/// fake (guest never reaches the cloud branch); main() overrides it with a
/// FirestoreCloudAccount when cloud is enabled.
final cloudAccountProvider = Provider<CloudAccount>((ref) => FakeCloudAccount());
