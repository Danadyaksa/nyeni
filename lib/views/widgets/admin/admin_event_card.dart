import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/api_config.dart';

const Color _primary = Color(0xFF2C3E50);

/// Card untuk menampilkan event di admin list
class AdminEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminEventCard({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = (event['is_active'] == 1 || event['is_active'] == true);
    final imageUrl = event['image_url']?.toString() ?? '';
    final price = event['price'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    ApiConfig.normalizeImageUrl(imageUrl),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + active badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event['title']?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? Colors.green : Colors.grey, width: 1),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Category
                _infoRow(LucideIcons.tag, event['category']?.toString() ?? '-', Colors.purple),
                const SizedBox(height: 4),
                // Location
                _infoRow(LucideIcons.mapPin, event['location']?.toString() ?? '-', Colors.red),
                const SizedBox(height: 4),
                // Date
                _infoRow(LucideIcons.calendar, event['event_date']?.toString() ?? '-', Colors.blue),
                const SizedBox(height: 4),
                // Price
                _infoRow(
                  LucideIcons.ticket,
                  price == 0 ? 'Gratis' : 'Rp ${_formatPrice(price)}',
                  Colors.teal,
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(LucideIcons.pencil, size: 15),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(LucideIcons.trash2, size: 15),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(LucideIcons.image, size: 48, color: Colors.grey[400]),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatPrice(dynamic price) {
    final p = (price is int) ? price : int.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}jt';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}rb';
    return p.toString();
  }
}
