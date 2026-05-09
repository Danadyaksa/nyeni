// Konfigurasi API - Ganti baseUrl sesuai jaringan yang dipakai
class ApiConfig {
  // Base URL - Ganti IP sesuai network kamu
  // Emulator: "http://10.0.2.2:3000/api"
  // Local Network: "http://192.168.x.x:3000/api"
  // Kos aksa: "http://192.168.0.162:3000/api"
  static const String baseUrl = "http://192.168.0.162:3000/api";
  
  static String get serverHost => baseUrl.replaceAll('/api', '');

  // Auth endpoints
  static String get loginUrl => "$baseUrl/login";
  static String get registerUrl => "$baseUrl/register";
  
  // Event endpoints
  static String get eventsUrl => "$baseUrl/events";
  static String eventDetailUrl(int id) => "$baseUrl/events/$id";
  
  // Ticket endpoints
  static String get ticketsUrl => "$baseUrl/tickets";
  static String myTicketsUrl(String userId) => "$baseUrl/tickets/my-tickets/$userId";
  
  // User endpoints
  static String userProfileUrl(String userId) => "$baseUrl/user/$userId";
  static String get updateProfileUrl => "$baseUrl/user/update";
  static String get uploadAvatarUrl => "$baseUrl/user/upload-avatar";
  
  // Game endpoints
  static String get updateGameProgressUrl => "$baseUrl/game/progress";
  
  // Feedback endpoints
  static String get feedbacksUrl => "$baseUrl/feedbacks";
  
  // Recommendation endpoints
  static String recommendationsUrl(String userId) => "$baseUrl/recommendations/$userId";
  
  // Admin endpoints
  static String get adminEventsUrl => "$baseUrl/admin/events";
  static String adminEventDetailUrl(int id) => "$baseUrl/admin/events/$id";
  static String get adminUploadImageUrl => "$baseUrl/admin/events/upload-image";
  static String get adminTicketsUrl => "$baseUrl/admin/tickets";
  static String adminTicketAcceptUrl(String id) => "$baseUrl/admin/tickets/$id/accept";
  static String adminTicketDeclineUrl(String id) => "$baseUrl/admin/tickets/$id/decline";
  static String adminTicketScanUrl(String id) => "$baseUrl/admin/tickets/$id/scan";
  static String get adminRevenueUrl => "$baseUrl/admin/revenue";
  static String get adminFeedbacksUrl => "$baseUrl/admin/feedbacks";
  
  // Normalisasi URL gambar - handle path relatif & localhost
  static String normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    if (url.startsWith('/')) {
      return '$serverHost$url';
    }
    
    return url.replaceFirstMapped(
      RegExp(r'http://[^/]+'),
      (_) => serverHost,
    );
  }
  
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
