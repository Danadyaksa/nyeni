import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Header event dengan image, category, title, date, location, dan time
class EventHeader extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback? onTimezoneTap;

  const EventHeader({
    super.key,
    required this.event,
    this.onTimezoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            event['category'] ?? '',
            style: const TextStyle(
                color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        // Title
        Text(
          event['title'] ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Date
        Row(children: [
          const Icon(LucideIcons.calendar, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(event['event_date'] ?? '-',
              style: const TextStyle(color: Colors.grey)),
        ]),
        const SizedBox(height: 8),

        // Location
        Row(children: [
          const Icon(LucideIcons.mapPin, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(event['location'] ?? '-',
                style: const TextStyle(color: Colors.grey)),
          ),
        ]),
        const SizedBox(height: 8),

        // Time (with timezone tap)
        if (event['open_time'] != null || event['close_time'] != null)
          GestureDetector(
            onTap: onTimezoneTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2C3E50).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.clock,
                      size: 15, color: Color(0xFF2C3E50)),
                  const SizedBox(width: 8),
                  Text(
                    _buildTimeDisplay(
                      event['open_time']?.toString(),
                      event['close_time']?.toString(),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.globe, size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  const Text('Lihat zona waktu lain',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _buildTimeDisplay(String? open, String? close) {
    final o = _fmtTime(open);
    final c = _fmtTime(close);
    if (o != null && c != null) return '$o – $c WIB';
    if (o != null) return 'Buka $o WIB';
    if (c != null) return 'Tutup $c WIB';
    return '-';
  }

  String? _fmtTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return raw;
  }
}
