enum ApiMode { v2, v2WithLegacyCompat, legacy, demo }

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://startle-kilogram-greeting.ngrok-free.dev',
  );

  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  static const bool enableLegacyCompatibility = bool.fromEnvironment(
    'ENABLE_LEGACY_COMPAT',
    defaultValue: true,
  );

  static ApiMode get apiMode {
    if (demoMode) return ApiMode.demo;
    if (enableLegacyCompatibility) return ApiMode.v2WithLegacyCompat;
    return ApiMode.v2;
  }

  static String get apiModeLabel {
    switch (apiMode) {
      case ApiMode.v2:
        return 'V2';
      case ApiMode.v2WithLegacyCompat:
        return 'V2 + LEGACY COMPAT';
      case ApiMode.legacy:
        return 'LEGACY';
      case ApiMode.demo:
        return 'DEMO';
    }
  }

  static Uri resolve(String endpoint) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path');
  }
}
