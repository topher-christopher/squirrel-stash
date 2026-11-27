import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'desktop_db_factory.dart';
import 'memory_stash_repository.dart';
import 'schema.dart';
import 'seed_data.dart';
import 'sqlite_stash_repository.dart';
import 'stash_repository.dart';

/// Opens the on-device stash and seeds the demo hollow on first launch.
abstract final class StashDatabase {
  static const fileName = 'squirrel_stash.db';

  static Future<Database> openDatabaseFile() async {
    final factory = desktopDatabaseFactory() ?? databaseFactory;
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return factory.openDatabase(
      p.join(dir.path, fileName),
      options: OpenDatabaseOptions(
        version: Schema.version,
        onCreate: Schema.create,
        onUpgrade: Schema.upgrade,
      ),
    );
  }

  /// Returns a ready repository. Falls back to an in-memory stash (and logs)
  /// if the database cannot be opened so the app still launches.
  static Future<StashRepository> openRepository() async {
    if (kIsWeb) {
      // Browser preview only: sqflite has no web driver, so the demo hollow
      // lives in memory and resets on reload. Native targets use SQLite.
      debugPrint('SquirrelStash: web preview — using in-memory demo stash');
      return MemoryStashRepository(SeedData.demo(DateTime.now()));
    }
    try {
      final repo = SqliteStashRepository(await openDatabaseFile());
      final existing = await repo.loadAll();
      if (existing.isEmpty) {
        await repo.replaceAll(SeedData.demo(DateTime.now()));
      }
      return repo;
    } catch (error, stack) {
      debugPrint('SquirrelStash: SQLite unavailable ($error)\n$stack');
      return MemoryStashRepository(SeedData.demo(DateTime.now()));
    }
  }
}
