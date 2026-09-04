/// Native storage lives in the app's own sandbox: nothing to install, and no
/// eviction rules to warn about. These constants keep the UI checks trivial.
Future<bool> isInstalledAsApp() async => true;

Future<bool> requestPersistentStorage() async => true;
