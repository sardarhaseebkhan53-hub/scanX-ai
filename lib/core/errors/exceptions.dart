class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException(statusCode: $statusCode, message: $message)';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class AIException implements Exception {
  final String message;
  final String? provider;

  const AIException({required this.message, this.provider});

  @override
  String toString() => 'AIException(provider: $provider, message: $message)';
}

class SecurityException implements Exception {
  final String message;

  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

class OCRException implements Exception {
  final String message;

  const OCRException(this.message);

  @override
  String toString() => 'OCRException: $message';
}
