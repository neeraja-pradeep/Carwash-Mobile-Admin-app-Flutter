import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';

/// Singleton HTTP client shared across the app with session management.
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();

  late Dio _dio;
  static String? _sessionId;
  static String? _csrfToken;

  factory HttpClient() {
    return _instance;
  }

  HttpClient._internal() {
    _initDio();
    // Load session/CSRF asynchronously on startup
    _loadSessionAndCsrfFromStorage();
  }

  /// Load session ID and CSRF token from local storage (no server calls on startup).
  Future<void> _loadSessionAndCsrfFromStorage() async {
    try {
      final box = await Hive.openBox<String>('session');
      _sessionId = box.get('sessionid');
      _csrfToken = box.get('csrftoken');

      if (_sessionId != null) {
        debugPrint('🔐 Session ID loaded: $_sessionId');
      }
      if (_csrfToken != null) {
        debugPrint('🔐 CSRF token loaded: ${_csrfToken!.substring(0, 10)}...');
        // Add loaded token to interceptor's cookies map
        _CsrfInterceptor.addCookie('csrftoken', _csrfToken!);
        debugPrint('💾 CSRF token added to cookies map');
      }
    } catch (e) {
      debugPrint('❌ Error loading session/CSRF: $e');
    }
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

    // Add session and CSRF interceptor
    _dio.interceptors.add(_SessionInterceptor());
    _dio.interceptors.add(_CsrfInterceptor());

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

  /// Save CSRF token to local storage.
  static Future<void> _saveCsrfToStorage(String csrfToken) async {
    try {
      final box = await Hive.openBox<String>('session');
      await box.put('csrftoken', csrfToken);
      debugPrint('💾 CSRF token saved locally');
    } catch (e) {
      debugPrint('❌ Error saving CSRF: $e');
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

  /// Remove session and CSRF from local storage (on logout).
  static Future<void> _removeSessionFromStorage() async {
    try {
      final box = await Hive.openBox<String>('session');
      await box.delete('sessionid');
      await box.delete('csrftoken');
      _csrfToken = null;
      debugPrint('🔓 Session and CSRF cleared');
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

/// Interceptor to handle CSRF tokens for POST/PATCH requests
class _CsrfInterceptor extends Interceptor {
  static final Map<String, String> _cookies = {};

  /// Add a cookie to the cookies map (used to load from storage).
  static void addCookie(String name, String value) {
    _cookies[name] = value;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Merge all stored cookies into request Cookie header
    if (_cookies.isNotEmpty) {
      final cookieList = _cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .toList();

      String cookieHeader = cookieList.join('; ');
      final existingCookie = options.headers['Cookie'] as String?;
      if (existingCookie != null && existingCookie.isNotEmpty) {
        // Merge with existing cookies
        cookieHeader = '$existingCookie; $cookieHeader';
      }

      options.headers['Cookie'] = cookieHeader;
      debugPrint('🍪 Cookies in request: $cookieHeader');
    }

    // For POST/PATCH/PUT/DELETE requests, add CSRF token header
    if (['POST', 'PATCH', 'PUT', 'DELETE'].contains(options.method)) {
      if (HttpClient._csrfToken != null && HttpClient._csrfToken!.isNotEmpty) {
        options.headers['X-CSRFToken'] = HttpClient._csrfToken;
        debugPrint('🔐 X-CSRFToken header added: ${HttpClient._csrfToken!.substring(0, 10)}...');
      } else {
        debugPrint('⚠️ CSRF token missing for ${options.method}');
        // Try to add from cookies if available
        if (_cookies.containsKey('csrftoken')) {
          final token = _cookies['csrftoken']!;
          options.headers['X-CSRFToken'] = token;
          HttpClient._csrfToken = token;
          debugPrint('🔐 CSRF token from cookies: ${token.substring(0, 10)}...');
        }
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Extract cookies from response Set-Cookie headers
    // Dio stores headers as lowercase
    final setCookieHeaders = response.headers['set-cookie'];

    if (setCookieHeaders != null && setCookieHeaders.isNotEmpty) {
      debugPrint('📋 Found ${setCookieHeaders.length} Set-Cookie header(s)');

      for (final cookieStr in setCookieHeaders) {
        debugPrint('🔍 Parsing cookie: $cookieStr');

        // Parse: "name=value; Path=/; HttpOnly; ..."
        final parts = cookieStr.split(';');
        if (parts.isNotEmpty) {
          final nameValue = parts[0].trim();
          if (nameValue.contains('=')) {
            final idx = nameValue.indexOf('=');
            final name = nameValue.substring(0, idx).trim();
            final value = nameValue.substring(idx + 1).trim();

            if (value.isNotEmpty) {
              _cookies[name] = value;
              debugPrint('✅ Stored cookie: $name=${value.substring(0, Math.min(15, value.length))}...');

              // Track CSRF token specifically and save to storage
              if (name.toLowerCase() == 'csrftoken') {
                HttpClient._csrfToken = value;
                HttpClient._saveCsrfToStorage(value);
                debugPrint('🔐 CSRF token updated: ${value.substring(0, 10)}...');
              }
            }
          }
        }
      }
    }

    super.onResponse(response, handler);
  }
}

// Simple Math helper
class Math {
  static int min(int a, int b) => a < b ? a : b;
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
