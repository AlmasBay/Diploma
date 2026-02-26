class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Default for current host network (as in original working setup).
    defaultValue: 'http://172.20.10.2:8080/api',
  );
}
