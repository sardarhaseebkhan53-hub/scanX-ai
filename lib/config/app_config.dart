enum AppEnvironment { dev, staging, prod }

class AppConfig {
  static AppEnvironment currentEnvironment = AppEnvironment.prod;

  static bool get isDev => currentEnvironment == AppEnvironment.dev;
  static bool get isProd => currentEnvironment == AppEnvironment.prod;

  static String get aiProviderDefault => 'groq'; // 'groq', 'gemini', or 'openai'
  static bool get enableAnalytics => currentEnvironment == AppEnvironment.prod;
  static bool get enableCrashlytics => currentEnvironment == AppEnvironment.prod;
}
