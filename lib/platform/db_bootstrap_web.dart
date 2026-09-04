import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

bool _installed = false;

/// Points sqflite at sqlite3-on-WebAssembly, which keeps the database in the
/// browser's IndexedDB. Loads web/sqflite_sw.js + web/sqlite3.wasm; the
/// package tries a SharedWorker first and silently falls back to a dedicated
/// Worker on browsers without one (notably iOS Safari), so this is safe on
/// iPhone. Must run before anything touches [AppDatabase].
Future<void> initDatabaseBackend() async {
  if (_installed) return;
  _installed = true;
  databaseFactory = databaseFactoryFfiWeb;
}

/// IndexedDB has no directories: the file name alone is the storage key.
Future<String> resolveDatabasePath(String fileName) async => fileName;
