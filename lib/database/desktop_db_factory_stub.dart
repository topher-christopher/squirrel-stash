import 'package:sqflite/sqflite.dart';

/// Platforms without `dart:ffi` (web): no desktop SQLite factory.
DatabaseFactory? desktopDatabaseFactory() => null;
