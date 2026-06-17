class Session {
  final String sessionId;
  final String csrfToken;
  final DateTime expiresAt;

  Session({
    required this.sessionId,
    required this.csrfToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
