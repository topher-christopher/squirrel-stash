import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Custom icon PNGs bundled under `assets/images/icons/` (loaded once in
/// `main()`), so widgets can swap painted icons for hand-drawn art.
final artAssetsProvider = Provider<Set<String>>((ref) => const {});

Future<Set<String>> loadIconAssets() async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where((a) => a.startsWith('assets/images/icons/') && a.endsWith('.png'))
        .toSet();
  } catch (error) {
    debugPrint('SquirrelStash art: no custom icons ($error)');
    return const {};
  }
}
