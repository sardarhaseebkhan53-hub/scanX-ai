/// Build-time configuration and secrets for ScanX AI.
///
/// Values are read from `--dart-define` so **no real API keys ever need to
/// live on disk or in source control**. This file is safe to commit and ships
/// with empty defaults, which means a fresh clone builds and runs immediately
/// (AI features simply stay disabled until a key is supplied).
///
/// Usage:
/// ```bash
/// flutter run --dart-define=GROQ_API_KEY=your_real_key_here
/// flutter build apk --release --dart-define=GROQ_API_KEY=your_real_key_here
/// ```
///
/// To rotate or add providers, add another `String.fromEnvironment` entry and
/// pass the matching `--dart-define=NAME=value` at build time.
library;

class EnvSecrets {
  const EnvSecrets._();

  /// Groq API key (https://console.groq.com/keys).
  ///
  /// Defaults to an empty string when not provided via `--dart-define`, in
  /// which case `main.dart` skips provisioning the key and AI features remain
  /// disabled instead of crashing the app.
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
}
