/// Helper untuk konversi mata uang
class CurrencyHelper {
  // Exchange rates (update sesuai kebutuhan)
  static const Map<String, double> _rates = {
    'USD': 0.000063, // 1 IDR = 0.000063 USD
    'EUR': 0.000058, // 1 IDR = 0.000058 EUR
    'JPY': 0.0095,   // 1 IDR = 0.0095 JPY
    'SGD': 0.000085, // 1 IDR = 0.000085 SGD
    'MYR': 0.00030,  // 1 IDR = 0.00030 MYR
  };

  static const Map<String, String> _symbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'EUR': '€',
    'JPY': '¥',
    'SGD': 'S\$',
    'MYR': 'RM',
  };

  /// Convert IDR to other currency
  static double convert(int idrAmount, String toCurrency) {
    if (toCurrency == 'IDR') return idrAmount.toDouble();
    final rate = _rates[toCurrency] ?? 1.0;
    return idrAmount * rate;
  }

  /// Format currency with symbol
  static String format(double amount, String currency) {
    final symbol = _symbols[currency] ?? '';
    if (currency == 'IDR') {
      return '$symbol ${amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';
    }
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  /// Get currency name
  static String getCurrencyName(String code) {
    const names = {
      'IDR': 'Rupiah Indonesia',
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'JPY': 'Japanese Yen',
      'SGD': 'Singapore Dollar',
      'MYR': 'Malaysian Ringgit',
    };
    return names[code] ?? code;
  }

  /// Get all supported currencies
  static List<String> getSupportedCurrencies() {
    return ['IDR', 'USD', 'EUR', 'JPY', 'SGD', 'MYR'];
  }
}
