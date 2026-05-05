/// Helper untuk formatting tanggal
class DateHelper {
  static const List<String> _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _monthNamesFull = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// Format ISO date to "12 Mei 2026"
  static String format(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return '${d.day} ${_monthNames[d.month]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Format ISO date to "12 Mei 2026" with full month name
  static String formatFull(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return '${d.day} ${_monthNamesFull[d.month]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Format ISO date to "12/05/2026"
  static String formatShort(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Check if date is in the past
  static bool isPast(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;
    try {
      final date = DateTime.parse(dateString);
      return DateTime.now().isAfter(date);
    } catch (_) {
      return false;
    }
  }

  /// Check if date is in the future
  static bool isFuture(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;
    try {
      final date = DateTime.parse(dateString);
      return DateTime.now().isBefore(date);
    } catch (_) {
      return false;
    }
  }

  /// Get days until date
  static int daysUntil(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 0;
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return date.difference(now).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Format relative time (e.g., "2 hari lagi", "3 hari yang lalu")
  static String formatRelative(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = date.difference(now);
      
      if (diff.inDays > 0) {
        return '${diff.inDays} hari lagi';
      } else if (diff.inDays < 0) {
        return '${-diff.inDays} hari yang lalu';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} jam lagi';
      } else if (diff.inHours < 0) {
        return '${-diff.inHours} jam yang lalu';
      } else {
        return 'Hari ini';
      }
    } catch (_) {
      return dateString;
    }
  }
}
