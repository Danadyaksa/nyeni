import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dialog untuk konversi timezone
class TimezoneDialog extends StatelessWidget {
  final String eventTitle;
  final String? openTime;
  final String? closeTime;

  const TimezoneDialog({
    super.key,
    required this.eventTitle,
    this.openTime,
    this.closeTime,
  });

  static void show(
    BuildContext context, {
    required String eventTitle,
    String? openTime,
    String? closeTime,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => TimezoneDialog(
        eventTitle: eventTitle,
        openTime: openTime,
        closeTime: closeTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openMin = _timeToMinutes(openTime);
    final closeMin = _timeToMinutes(closeTime);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(LucideIcons.globe, color: Color(0xFF2C3E50)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            eventTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Jam operasional dalam berbagai zona waktu:',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          _tzRow('WIB', 'Waktu Indonesia Barat', openMin, closeMin, 0),
          const Divider(height: 16),
          _tzRow('WITA', 'Waktu Indonesia Tengah', openMin, closeMin, 60),
          const Divider(height: 16),
          _tzRow('WIT', 'Waktu Indonesia Timur', openMin, closeMin, 120),
          const Divider(height: 16),
          _tzRow('GMT', 'Greenwich Mean Time', openMin, closeMin, -420),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _tzRow(String zone, String label, int? openMin, int? closeMin,
      int offsetFromWib) {
    String timeStr;
    if (openMin != null && closeMin != null) {
      timeStr =
          '${_convertTime(openMin, offsetFromWib)} – ${_convertTime(closeMin, offsetFromWib)}';
    } else if (openMin != null) {
      timeStr = 'Buka ${_convertTime(openMin, offsetFromWib)}';
    } else if (closeMin != null) {
      timeStr = 'Tutup ${_convertTime(closeMin, offsetFromWib)}';
    } else {
      timeStr = '-';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(zone,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(timeStr,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
      ],
    );
  }

  int? _timeToMinutes(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return null;
  }

  String _convertTime(int wibMinutes, int offsetFromWib) {
    int total = wibMinutes + offsetFromWib;
    total = total % (24 * 60);
    if (total < 0) total += 24 * 60;
    final h = total ~/ 60;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
