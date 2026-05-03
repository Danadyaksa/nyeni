import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Counter tiket + tombol pesan
class TicketCounter extends StatelessWidget {
  final int ticketCount;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onOrder;
  final Map<String, dynamic>? selectedTicket;

  const TicketCounter({
    super.key,
    required this.ticketCount,
    required this.onIncrement,
    required this.onDecrement,
    this.onOrder,
    this.selectedTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Counter + Order button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Counter
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.minus, size: 16),
                      onPressed: ticketCount > 1 ? onDecrement : null,
                      color: ticketCount > 1
                          ? const Color(0xFF2C3E50)
                          : Colors.grey,
                    ),
                    Text(
                      '$ticketCount',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.plus, size: 16),
                      onPressed: onIncrement,
                      color: const Color(0xFF2C3E50),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Order button
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedTicket == null ? null : onOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    selectedTicket == null
                        ? 'Pilih Tiket Dulu'
                        : 'Pesan $ticketCount Tiket',
                    style: TextStyle(
                      color: selectedTicket == null ? Colors.grey : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Price preview
        if (selectedTicket != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E50).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$ticketCount tiket × Rp ${_fmtPrice(selectedTicket!['price'])}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  'Rp ${_fmtPrice((selectedTicket!['price'] as int) * ticketCount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
}
