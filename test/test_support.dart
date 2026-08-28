import 'dart:io';

import 'package:app_thu_chi/data/app_database.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// path_provider needs a real OS platform channel normally; this fake
/// answers with the system temp dir so services like BackupService's
/// getTemporaryDirectory() calls work under `flutter test`.
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

/// Call once from `setUpAll` in any test file that touches the database.
void initTestDatabaseFactory() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Call from `setUp` before every test that touches the database. Starts
/// each test from a genuinely empty database file, not just a closed
/// connection — AppDatabase always opens the same fixed on-disk path
/// (shared across every test file in this suite), so a previous test's
/// rows would otherwise still be sitting there on disk.
Future<void> resetTestDatabase() async {
  await AppDatabase.instance.close();
  final dbPath = await databaseFactory.getDatabasesPath();
  final file = File('$dbPath/app_thu_chi.db');
  if (await file.exists()) await file.delete();
}
