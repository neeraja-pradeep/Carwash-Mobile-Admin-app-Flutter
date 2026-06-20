/// Local data source for notifications (deprecated - use API instead).
/// Kept only for emergency fallback if API is completely unavailable.
class NotificationsLocalDs {
  const NotificationsLocalDs();

  /// Deprecated: Use NotificationsApi instead. Throws to force API usage.
  Future<List<dynamic>> fetchNotifications() async {
    throw UnimplementedError(
      'Mock data removed. Notifications now uses API exclusively. '
      'If you see this error, the API call failed.',
    );
  }
}
