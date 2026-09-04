import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';

/// Native already registers the sqflite plugin as the default backend, so
/// there is nothing to install here — this exists only so the web side can
/// swap in its own factory behind the same call.
Future<void> initDatabaseBackend() async {}

/// The database lives in the app's private sqflite directory, as it always has.
Future<String> resolveDatabasePath(String fileName) async =>
    join(await getDatabasesPath(), fileName);
