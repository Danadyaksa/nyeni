import 'package:flutter/material.dart';

/// Helper class untuk date formatting dan parsing
class DateUtilsHelper {
  // Indonesian month names
  static const List<String> bulanId = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> bulanIdFull = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// Format date untuk display: "01 Mei 2026"
  static String formatDateDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${bulanId[d.month]} ${d.year}';

  /// Format date untuk ISO: "2026-05-01"
  static String formatDateIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Build event date string: "12 Mei 2026" or "25 Mei - 25 Jul 2026"
  static String buildEventDateString(DateTime start, DateTime? end) {
    if (end == null || isSameDay(start, end)) {
      return '${start.day} ${bulanIdFull[start.month]} ${start.year}';
    }
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${start.day} - ${end.day} ${bulanIdFull[end.month]} ${end.year}';
      }
      return '${start.day} ${bulanIdFull[start.month]} - ${end.day} ${bulanIdFull[end.month]} ${end.year}';
    }
    return '${start.day} ${bulanIdFull[start.month]} ${start.year} - ${end.day} ${bulanIdFull[end.month]} ${end.year}';
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Parse date from dynamic value
  static DateTime? parseDate(dynamic val) {
    if (val == null) return null;
    try {
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }

  /// Parse date from string like "12 Mei 2026" or "2026-05-12"
  static DateTime? parseDateFromString(String raw) {
    // ISO format
    try {
      return DateTime.parse(raw.split(' ').first);
    } catch (_) {}

    // "12 Mei 2026" format
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'jun': 6,
      'jul': 7, 'agu': 8, 'sep': 9, 'okt': 10, 'nov': 11, 'des': 12,
    };
    final parts = raw.toLowerCase().split(RegExp(r'[\s\-]+'));
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]);
      final month = months[parts[1].substring(0, 3)];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  /// Parse TimeOfDay from string "HH:MM" or "HH:MM:SS"
  static TimeOfDay? parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  /// Format TimeOfDay to string "HH:MM"
  static String? formatTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
