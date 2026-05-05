import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/event_controller.dart';
import '../../config/api_config.dart';
import '../../utils/price_helper.dart';
import 'event_detail_screen.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  final _eventController = EventController();
  List<dynamic> _allEvents = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Konser', 'Teater', 'Pameran', 'Stand Up'];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final events = await _eventController.getAllEvents();
    if (mounted) {
      setState(() {
        _allEvents = events.map((e) => {
          'id': e.id,
          'title': e.name,
          'category': e.category,
          'event_date': e.date,
          'location': e.location,
          'price': e.price,
          'image_url': e.imageUrl ?? '',
          'early_bird_price': e.earlyBirdPrice,
          'early_bird_start': e.earlyBirdStart,
          'early_bird_end': e.earlyBirdEnd,
        }).toList();
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredEvents {
    if (_selectedCategory == 'Semua') return _allEvents;
    return _allEvents.where((e) => e['category'] == _selectedCategory).toList();
  }

  Widget _buildEventPrice(Map<String, dynamic> event) {
    final now = DateTime.now();
    final regularPrice = event['price'] ?? 0;
    final ebPrice = event['early_bird_price'];
    final ebStart = event['early_bird_start'];
    final ebEnd = event['early_bird_end'];

    final ebPriceInt = (ebPrice is double) 
        ? ebPrice.toInt() 
        : int.tryParse(ebPrice.toString()) ?? 0;

    bool isEarlyBirdActive = false;
    
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
              PriceHelper.formatNumber(displayPrice),
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
        if (isEarlyBirdActive)
          Text(
            PriceHelper.formatNumber(regularPrice),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EE),
      appBar: AppBar(
        title: Text(
          'Semua Event',
          style: GoogleFonts.libreBaskerville(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A302A),
          ),
        ),
        backgroundColor: const Color(0xFFFAFAF9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A302A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9A3412)))
          : Column(
              children: [
                // Category filter
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF9A3412) : const Color(0xFFFAFAF9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF9A3412) : const Color(0xFFD8D0C8),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.manrope(
                              color: isSelected ? Colors.white : const Color(0xFF3A302A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Event grid
                Expanded(
                  child: _filteredEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.searchX, size: 48, color: const Color(0xFFD8D0C8)),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada event di kategori ini',
                                style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = _filteredEvents[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventDetailScreen(eventId: event['id']),
                                  ),
                                );
                              },
                              child: Container(
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
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          ApiConfig.normalizeImageUrl(event['image_url']),
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: const Color(0xFFEAE2DA),
                                            child: const Center(
                                              child: Icon(LucideIcons.imageOff, color: Color(0xFF78706A)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event['title'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: const Color(0xFF3A302A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.calendar, size: 10, color: Color(0xFF78706A)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  event['event_date'] ?? '-',
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
                                          _buildEventPrice(event),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
