import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'database/stash_database.dart';
import 'providers/art_assets_provider.dart';
import 'providers/repository_providers.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.night,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Offline-first: open (and seed on first launch) the on-device stash
  // before the first frame so every notifier starts with real data.
  final repository = await StashDatabase.openRepository();
  final snapshot = await repository.loadAll();
  final icons = await loadIconAssets();

  runApp(ProviderScope(
    overrides: [
      stashRepositoryProvider.overrideWithValue(repository),
      initialSnapshotProvider.overrideWithValue(snapshot),
      artAssetsProvider.overrideWithValue(icons),
    ],
    child: const SquirrelStashApp(),
  ));
}
