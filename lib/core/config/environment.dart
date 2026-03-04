enum Environment { development, production }

class EnvironmentConfig {
  static const Environment _currentEnvironment = Environment.production; // Change this for local development
  
  static Environment get currentEnvironment => _currentEnvironment;
  
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isProduction => _currentEnvironment == Environment.production;
  
  static String get baseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://localhost:8000/api';
      case Environment.production:
        return 'http://31.97.71.5/leave-api/api';
    }
  }
  
  static Map<String, dynamic> get config {
    switch (_currentEnvironment) {
      case Environment.development:
        return {
          'baseUrl': 'http://localhost:8000/api',
          'debug': true,
          'logLevel': 'verbose',
        };
      case Environment.production:
        return {
          'baseUrl': 'http://31.97.71.5/leave-api/api',
          'debug': false,
          'logLevel': 'error',
        };
    }
  }
}