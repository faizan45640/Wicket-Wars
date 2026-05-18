final class AppEnvironment {
  AppEnvironment._();

  static bool _useFirebase = true;

  static bool get useFirebase => _useFirebase;

  static void useLocalData() {
    _useFirebase = false;
  }
}
