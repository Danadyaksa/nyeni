/// Helper untuk formatting harga
class PriceHelper {
  /// Format price to IDR with thousand separator
  static String format(dynamic price) {
    final p = (price is int) 
        ? price 
        : (double.tryParse(price.toString()) ?? 0).toInt();
    
    if (p == 0) return 'Gratis';
    
    return 'Rp ${p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  /// Format price without "Rp" prefix
  static String formatNumber(dynamic price) {
    final p = (price is int) 
        ? price 
        : (double.tryParse(price.toString()) ?? 0).toInt();
    
    return p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  /// Parse price string to int
  static int parse(String priceString) {
    // Remove "Rp", spaces, and dots
    final cleaned = priceString
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .trim();
    
    return int.tryParse(cleaned) ?? 0;
  }

  /// Check if price is free
  static bool isFree(dynamic price) {
    final p = (price is int) 
        ? price 
        : (double.tryParse(price.toString()) ?? 0).toInt();
    return p == 0;
  }
}
