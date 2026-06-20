import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';

/// Singleton HTTP client shared across the app with session management.
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();

  late Dio _dio;
  static String? _sessionId;

  factory HttpClient() {
    return _instance;
  }

  HttpClient._internal() {
    _initDio();
    _loadSessionFromStorage();
  }

  Dio get dio => _dio;

  /// Set session ID (called after login).
  static void setSessionId(String sessionId) {
    _sessionId = sessionId;
    _saveSessionToStorage(sessionId);
    debugPrint('🔐 Session ID stored: $sessionId');
  }

  /// Clear session (called on logout).
  static void clearSessionId() {
    _sessionId = null;
    _removeSessionFromStorage();
    debugPrint('🔓 Session ID cleared');
  }

  void _initDio() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      persistentConnection: true,
    ));

    // Add session interceptor to include sessionid in all requests
    _dio.interceptors.add(_SessionInterceptor());

    // Enable detailed logging in debug mode only
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );

      _dio.interceptors.add(_CustomLoggingInterceptor());
    }
  }

  /// Load session ID from local storage.
  Future<void> _loadSessionFromStorage() async {
    try {
      final box = await Hive.openBox<String>('session');
      _sessionId = box.get('sessionid');
      if (_sessionId != null) {
        debugPrint('🔐 Session ID loaded from storage: $_sessionId');
      }
    } catch (e) {
      debugPrint('❌ Error loading session: $e');
    }
  }

  /// Save session ID to local storage.
  static Future<void> _saveSessionToStorage(String sessionId) async {
    try {
      final box = await Hive.openBox<String>('session');
      await box.put('sessionid', sessionId);
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
    }
  }

  /// Remove session from local storage.
  static Future<void> _removeSessionFromStorage() async {
    try {
      final box = await Hive.openBox<String>('session');
      await box.delete('sessionid');
    } catch (e) {
      debugPrint('❌ Error removing session: $e');
    }
  }
}

/// Interceptor to add session ID to all requests.
class _SessionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add session ID as cookie if available
    if (HttpClient._sessionId != null && HttpClient._sessionId!.isNotEmpty) {
      options.headers['Cookie'] = 'sessionid=${HttpClient._sessionId}';
      debugPrint('🍪 Added session cookie to request');
    }
    // Increase timeout for dashboard queries (they're complex)
    options.connectTimeout = const Duration(seconds: 60);
    options.receiveTimeout = const Duration(seconds: 60);
    super.onRequest(options, handler);
  }
}

/// Custom logging interceptor to show API calls in clean format
class _CustomLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🔵 API REQUEST: ${options.method}');
      debugPrint('Endpoint: ${options.path}');
      debugPrint('Body: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🟢 API SUCCESS: ${response.statusCode}');
      debugPrint('Endpoint: ${response.requestOptions.path}');
      debugPrint('Response: ${response.data}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🔴 API ERROR: ${err.response?.statusCode}');
      debugPrint('Endpoint: ${err.requestOptions.path}');
      debugPrint('Error: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}
