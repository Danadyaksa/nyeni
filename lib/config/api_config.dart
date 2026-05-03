/// API Configuration
/// 
/// Centralized API base URL configuration.
/// Change this URL when switching networks (WiFi, mobile data, etc.)
class ApiConfig {
  // ==========================================
  // BASE URL CONFIGURATION
  // ==========================================
  
  /// Main API base URL
  /// 
  /// Options:
  /// - Emulator: "http://10.0.2.2:3000/api"
  /// - Kos Atilla: "http://192.168.0.162:3000/api"
  /// - Kos Apis: "http://192.168.18.85:3000/api"
  /// - Local Network: "http://192.168.x.x:3000/api"
  /// - Production: "https://your-domain.com/api"
  static const String baseUrl = "http://192.168.0.162:3000/api";
  
  /// Server host (without /api suffix)
  /// Used for image URLs and other resources
  static String get serverHost => baseUrl.replaceAll('/api', '');
  
  // ==========================================
  // ENDPOINT HELPERS
  // ==========================================
  
  /// Auth endpoints
  static String get loginUrl => "$baseUrl/login";
  static String get registerUrl => "$baseUrl/register";
  
  /// Event endpoints
  static String get eventsUrl => "$baseUrl/events";
  static String eventDetailUrl(int id) => "$baseUrl/events/$id";
  
  /// Ticket endpoints
  static String get ticketsUrl => "$baseUrl/tickets";
  static String myTicketsUrl(String userId) => "$baseUrl/tickets/my-tickets/$userId";
  
  /// User endpoints
  static String userProfileUrl(String userId) => "$baseUrl/user/$userId";
  static String get updateProfileUrl => "$baseUrl/user/update";
  static String get uploadAvatarUrl => "$baseUrl/user/upload-avatar";
  
  /// Game endpoints
  static String get updateGameProgressUrl => "$baseUrl/game/progress";
  static String get gameScoresUrl => "$baseUrl/game/scores";
  
  /// Feedback endpoints
  static String get feedbacksUrl => "$baseUrl/feedbacks";
  
  /// Admin endpoints
  static String get adminEventsUrl => "$baseUrl/admin/events";
  static String adminEventDetailUrl(int id) => "$baseUrl/admin/events/$id";
  static String get adminUploadImageUrl => "$baseUrl/admin/events/upload-image";
  static String get adminTicketsUrl => "$baseUrl/admin/tickets";
  static String adminTicketAcceptUrl(String id) => "$baseUrl/admin/tickets/$id/accept";
  static String adminTicketDeclineUrl(String id) => "$baseUrl/admin/tickets/$id/decline";
  static String adminTicketScanUrl(String id) => "$baseUrl/admin/tickets/$id/scan";
  static String get adminRevenueUrl => "$baseUrl/admin/revenue";
  static String get adminFeedbacksUrl => "$baseUrl/admin/feedbacks";
  
  // ==========================================
  // UTILITY METHODS
  // ==========================================
  
  /// Normalize image URL to use current server host
  /// 
  /// Replaces localhost URLs with actual server IP
  static String normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    return url
        .replaceAll('http://localhost:3000', serverHost)
        .replaceAll('http://10.0.2.2:3000', serverHost);
  }
  
  /// Check if URL is valid
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
