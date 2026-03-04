import 'package:dio/dio.dart';
import 'package:leave_management/core/constants/app_constants.dart';
import 'package:leave_management/data/services/storage_service.dart';
import 'package:logger/logger.dart';

class ApiClient {
  late Dio _dio;
  final StorageService _storageService;
  final Logger _logger = Logger();

  ApiClient(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to headers
          final token = await _storageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('FULL URL BEING CALLED: ${options.uri}');

          _logger.d('Request: ${options.method} ${options.uri}');
          _logger.d('Headers: ${options.headers}');
          _logger.d('Data: ${options.data}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i('Response: ${response.statusCode} ${response.requestOptions.path}');
          _logger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          // Check if this is an expected 404 for active session endpoint
          final isActiveSessionNotFound = error.response?.statusCode == 404 &&
              error.requestOptions.path.contains('/time-logs/active') &&
              error.response?.data != null &&
              error.response?.data['message']?.toString().contains('No active session found') == true;

          if (!isActiveSessionNotFound) {
            _logger.e('Error: ${error.message}');
            _logger.e('Response: ${error.response?.data}');
          } else {
            // Silently handle expected "no active session" 404s
            _logger.d('No active session found (expected)');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      print(path);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handler
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      default:
        return Exception('Network error. Please check your connection.');
    }
  }

  Exception _handleResponseError(Response? response) {
    if (response == null) {
      return Exception('Unknown error occurred');
    }

    final statusCode = response.statusCode;
    final data = response.data;

    switch (statusCode) {
      case 400:
        return Exception(data['message'] ?? 'Bad request');
      case 401:
        return Exception('Unauthorized. Please login again.');
      case 403:
        return Exception('Access forbidden');
      case 404:
        return Exception('Resource not found');
      case 422:
        final errors = data['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first;
          return Exception(
              firstError is List ? firstError.first : firstError);
        }
        return Exception(data['message'] ?? 'Validation error');
      case 500:
        print('SERVER CRASH DATA: ${response.data}'); 
        return Exception('Server error. Please try again later.');
        // return Exception('Server error. Please try again later.');
      default:
        return Exception(data['message'] ?? 'An error occurred');
    }
  }
}
