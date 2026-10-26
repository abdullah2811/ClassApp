class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static bool get isSecureTransport =>
      apiBaseUrl.startsWith('https://') || apiBaseUrl.startsWith('http://10.0.2.2');
}
