import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/api_config.dart';
import '../../../utils/price_helper.dart';

/// Reusable event card widget for grid display
class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  /// Determine which price to display (early bird or regular)
  Widget _buildEventPrice() {
    final now = DateTime.now();
    final regularPrice = event['price'] ?? 0;
    final ebPrice = event['early_bird_price'];
    final ebStart = event['early_bird_start'];
    final ebEnd = event['early_bird_end'] ?? event['early_bird_deadline'];

    // Convert early bird price to int
    final ebPriceInt = (ebPrice is double) 
        ? ebPrice.toInt() 
        : int.tryParse(ebPrice.toString()) ?? 0;

    bool isEarlyBirdActive = false;
    
    // Only consider early bird if price > 0 AND has valid dates
    if (ebPriceInt > 0 && (ebStart != null || ebEnd != null)) {
      try {
        final startOk = ebStart == null || now.isAfter(DateTime.parse(ebStart.toString()));
        final endOk = ebEnd == null || now.isBefore(DateTime.parse(ebEnd.toString()));
        isEarlyBirdActive = startOk && endOk;
      } catch (_) {}
    }

    final displayPrice = isEarlyBirdActive ? ebPriceInt : regularPrice;
    final label = isEarlyBirdActive ? 'Early Bird' : 'Reguler';
    final labelColor = isEarlyBirdActive ? Colors.orange : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              PriceHelper.format(displayPrice),
              style: GoogleFonts.ebGaramond(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9A3412),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
        // Show strikethrough regular price if early bird is active
        if (isEarlyBirdActive)
          Text(
            PriceHelper.format(regularPrice),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  ApiConfig.normalizeImageUrl(event['image_url']),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(LucideIcons.imageOff),
                    ),
                  ),
                ),
              ),
            ),
            // Event info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event['category'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Event title
                  Text(
                    event['title'],
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: const Color(0xFF3A302A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Event date
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 10, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event['event_date'],
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price
                  _buildEventPrice(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
