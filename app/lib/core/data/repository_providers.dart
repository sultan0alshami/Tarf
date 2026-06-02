import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud_mirror.dart';
import 'tarf_repository.dart';

/// The app's single repository. Overridden in main() with a PrefsRepository
/// (and, when cloud is enabled, an attached CloudMirror).
final tarfRepositoryProvider = Provider<TarfRepository>(
  (ref) => throw UnimplementedError('tarfRepositoryProvider must be overridden'),
);

/// The active cloud mirror. Defaults to a no-op; replaced when signed in.
final cloudMirrorProvider = Provider<CloudMirror>((ref) => const NoopCloudMirror());
