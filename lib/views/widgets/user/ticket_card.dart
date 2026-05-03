import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Card untuk pilihan tiket
class TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onPriceTap;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.isSelected,
    this.onTap,
    this.onPriceTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = ticket['available'] == true;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: !isAvailable
              ? Colors.grey.shade50
              : isSelected
                  ? const Color(0xFF2C3E50).withOpacity(0.05)
                  : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ticket name + status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket['type'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket['status'],
                          style: TextStyle(
                            fontSize: 11,
                            color: isAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: isAvailable ? onPriceTap : null,
                      child: Row(
                        children: [
                          Text(
                            'Rp ${_fmtPrice(ticket['price'])}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isAvailable
                                  ? const Color(0xFF2C3E50)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.refreshCcw,
                              size: 12,
                              color: isAvailable
                                  ? Colors.grey
                                  : Colors.grey.shade300),
                        ],
                      ),
                    ),
                    const Text('/ tiket',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                    if (isAvailable)
                      const Text('tap untuk konversi',
                          style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ],
            ),

            // Period dates
            if (ticket['start'] != null || ticket['end'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.calendarRange,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      _buildPeriodText(ticket['start'], ticket['end']),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            // Ticket description
            if (ticket['desc'] != null &&
                ticket['desc'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                ticket['desc'],
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],

            // Checkmark if selected
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(LucideIcons.checkCircle2,
                      size: 14, color: Color(0xFF2C3E50)),
                  SizedBox(width: 4),
                  Text('Dipilih',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtPrice(dynamic price) {
    final p = (price is int)
        ? price
        : (double.tryParse(price.toString()) ?? 0).toInt();
    return p
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _buildPeriodText(dynamic start, dynamic end) {
    final s = start != null ? _fmtDate(start.toString()) : null;
    final e = end != null ? _fmtDate(end.toString()) : null;
    if (s != null && e != null) return '$s – $e';
    if (s != null) return 'Mulai $s';
    if (e != null) return 'Sampai $e';
    return '';
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      const bulan = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${d.day} ${bulan[d.month]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }
}
