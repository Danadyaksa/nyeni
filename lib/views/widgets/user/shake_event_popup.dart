import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/api_config.dart';

/// Popup card rekomendasi event setelah shake
class ShakeEventPopup extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onViewDetail;
  final VoidCallback onDismiss;
  final VoidCallback? onShuffle;

  const ShakeEventPopup({
    super.key,
    required this.event,
    required this.onViewDetail,
    required this.onDismiss,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = event['image_url']?.toString() ?? '';
    final title = event['title']?.toString() ?? '-';
    final category = event['category']?.toString() ?? '';
    final location = event['location']?.toString() ?? '';
    final date = event['event_date']?.toString() ?? '';
    final price = event['price'] ?? 0;
    final priceStr = price == 0
        ? 'Gratis'
        : 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Event Image with Overlay
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: Stack(
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        ApiConfig.normalizeImageUrl(imageUrl),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    else
                      _imagePlaceholder(),

                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Shake badge
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.zap, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Shake Detected!',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    // Category badge
                    if (category.isNotEmpty)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Event Info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label rekomendasi
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Rekomendasi Untukmu',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Date & Location
                    _infoRow(LucideIcons.calendar, date),
                    const SizedBox(height: 6),
                    _infoRow(LucideIcons.mapPin, location),
                    const SizedBox(height: 16),

                    // Price & Shuffle Button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E50).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            priceStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (onShuffle != null)
                          GestureDetector(
                            onTap: onShuffle,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.shuffle,
                                  size: 18, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // View Event Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onViewDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Lihat Event',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            SizedBox(width: 6),
                            Icon(LucideIcons.arrowRight,
                                color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onDismiss,
                        child: const Text('Tutup',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFF2C3E50),
      child: const Icon(LucideIcons.image, color: Colors.white54, size: 48),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
