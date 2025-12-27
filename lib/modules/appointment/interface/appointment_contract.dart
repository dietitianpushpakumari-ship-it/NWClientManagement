abstract class AppointmentContract {
  /// Get the current logged-in user's ID
  String getCurrentUserId();

  /// Check if user is a staff member (Dietitian/Admin)
  Future<bool> isStaff(String userId);

  /// Fetch all active dietitians (for pooling availability)
  /// Returns a Map: { 'uid': 'Name' }
  Future<Map<String, String>> getActiveStaff();

  /// 💰 CREDITS: Check if user has enough wallet balance
  Future<bool> hasSufficientCredits(String userId, int cost);

  /// 💰 CREDITS: Reserve credits (Hold)
  Future<void> reserveCredits(String userId, int cost, String reason, String referenceId);

  /// 💰 CREDITS: Consume credits (Finalize)
  Future<void> consumeReservedCredits(String userId, int cost, String referenceId);

  /// 💰 CREDITS: Refund/Release credits
  Future<void> releaseReservedCredits(String userId, int cost, String referenceId);

  /// 🔔 NOTIFICATIONS: Send alert
  Future<void> sendNotification(String userId, String title, String body);
}