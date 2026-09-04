// Picks the SQLite backend for the platform we're running on. Native keeps
// the sqflite plugin exactly as before; the browser gets sqlite3 compiled to
// WebAssembly, persisted in IndexedDB.
export 'db_bootstrap_io.dart' if (dart.library.js_interop) 'db_bootstrap_web.dart';
