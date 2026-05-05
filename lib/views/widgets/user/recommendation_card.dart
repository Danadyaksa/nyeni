import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/api_config.dart';
import '../../../utils/price_helper.dart';

/// Reusable recommendation card widget for horizontal scroll
class RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  final bool showNewBadge;

  const RecommendationCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showNewBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8D0C8)),
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
            // Event image with optional "BARU" badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    ApiConfig.normalizeImageUrl(event['image_url']),
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: const Color(0xFFEAE2DA),
                      child: const Center(
                        child: Icon(LucideIcons.imageOff, color: Color(0xFF78706A)),
                      ),
                    ),
                  ),
                ),
                if (showNewBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9A3412),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BARU',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Event info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE2DA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event['category'],
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        color: const Color(0xFF9A3412),
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
                      fontSize: 12,
                      color: const Color(0xFF3A302A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Event date
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 9, color: Color(0xFF78706A)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['event_date'],
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            color: const Color(0xFF78706A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Price
                  Text(
                    PriceHelper.format(event['price']),
                    style: GoogleFonts.ebGaramond(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9A3412),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
