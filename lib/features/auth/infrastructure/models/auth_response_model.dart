import '../../domain/entities/user.dart';

class AuthResponseModel {
  final User user;
  final String? sessionId;
  final String? csrfToken;

  AuthResponseModel({
    required this.user,
    this.sessionId,
    this.csrfToken,
  });

  factory AuthResponseModel.fromJson(
    Map<String, dynamic> json,
    List<String>? setCookieHeaders,
  ) {
    final sessionId = _extractSessionId(setCookieHeaders);
    final csrfToken = _extractCsrfToken(setCookieHeaders);

    // API returns user object directly, or nested under 'user' key
    final userData = json.containsKey('user') ? json['user'] : json;

    return AuthResponseModel(
      user: User.fromJson(userData),
      sessionId: sessionId,
      csrfToken: csrfToken,
    );
  }

  /// Extract sessionid from Set-Cookie headers.
  static String? _extractSessionId(List<String>? setCookieHeaders) {
    if (setCookieHeaders == null || setCookieHeaders.isEmpty) return null;
    for (final header in setCookieHeaders) {
      final match = RegExp(r'sessionid=([^;]+)').firstMatch(header);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// Extract csrftoken from Set-Cookie headers.
  static String? _extractCsrfToken(List<String>? setCookieHeaders) {
    if (setCookieHeaders == null || setCookieHeaders.isEmpty) return null;
    for (final header in setCookieHeaders) {
      final match = RegExp(r'csrftoken=([^;]+)').firstMatch(header);
      if (match != null) return match.group(1);
    }
    return null;
  }
}
