import 'dart:io' show Platform;

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// Windows/Linux use sqflite_common_ffi; Android/iOS/macOS return null and
/// keep sqflite's native driver.
DatabaseFactory? desktopDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux) {
    ffi.sqfliteFfiInit();
    return ffi.databaseFactoryFfi;
  }
  return null;
}
