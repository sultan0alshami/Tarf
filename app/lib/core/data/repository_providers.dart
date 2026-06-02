import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/account/application/cloud_account.dart';
import '../../firebase/firebase_flags.dart';
import 'cloud_mirror.dart';
import 'tarf_repository.dart';

/// The app's single repository. Overridden in main() with a PrefsRepository
/// (and, when cloud is enabled, an attached CloudMirror).
final tarfRepositoryProvider = Provider<TarfRepository>(
  (ref) => throw UnimplementedError('tarfRepositoryProvider must be overridden'),
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
