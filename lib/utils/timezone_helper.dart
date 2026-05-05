/// Helper untuk konversi timezone
class TimezoneHelper {
  // Offset dari WIB (dalam menit)
  static const Map<String, int> _offsets = {
    'WIB': 0,      // UTC+7 (baseline)
    'WITA': 60,    // UTC+8 (+1 jam dari WIB)
    'WIT': 120,    // UTC+9 (+2 jam dari WIB)
    'GMT': -420,   // UTC+0 (-7 jam dari WIB)
  };

  static const Map<String, String> _names = {
    'WIB': 'Waktu Indonesia Barat',
    'WITA': 'Waktu Indonesia Tengah',
    'WIT': 'Waktu Indonesia Timur',
    'GMT': 'Greenwich Mean Time',
  };

  /// Convert time from WIB to other timezone
  /// wibMinutes: minutes since midnight in WIB
  /// toTimezone: target timezone code
  static int convertFromWIB(int wibMinutes, String toTimezone) {
    final offset = _offsets[toTimezone] ?? 0;
    int total = wibMinutes + offset;
    
    // Handle overflow (next/previous day)
    total = total % (24 * 60);
    if (total < 0) total += 24 * 60;
    
    return total;
  }

  /// Format minutes to HH:MM string
  static String formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Parse HH:MM:SS or HH:MM string to minutes
  static int? parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return null;
  }

  /// Get timezone name
  static String getTimezoneName(String code) {
    return _names[code] ?? code;
  }

  /// Get all supported timezones
  static List<String> getSupportedTimezones() {
    return ['WIB', 'WITA', 'WIT', 'GMT'];
  }

  /// Build display string for time range
  static String buildTimeDisplay(String? openTime, String? closeTime) {
    final o = formatTimeFromString(openTime);
    final c = formatTimeFromString(closeTime);
    if (o != null && c != null) return '$o – $c WIB';
    if (o != null) return 'Buka $o WIB';
    if (c != null) return 'Tutup $c WIB';
    return '-';
  }

  /// Format HH:MM:SS to HH:MM
  static String? formatTimeFromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return raw;
  }
}
