/// SQLite factory for Windows/Linux (sqflite_common_ffi). Selected by a
/// conditional import so web builds never see `dart:ffi`.
library;

export 'desktop_db_factory_stub.dart'
    if (dart.library.ffi) 'desktop_db_factory_ffi.dart';
