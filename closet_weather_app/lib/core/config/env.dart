class Environment {
  static const String baseApiUrl = 'http://89.252.179.156:5000';
  
  // ML API Endpoints
  static const String mlRecommendationApi = '$baseApiUrl/api/recommend';
  static const String mlMultipleRecommendationApi = '$baseApiUrl/api/recommend-multiple';
  
  // API Health Check Endpoint
  static const String healthCheckEndpoint = '$baseApiUrl/health';

  // Timeout Durations
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 5);
} 