import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../config/api_config.dart';
import 'checkout_screen.dart';
import '../widgets/user/event_header.dart';
import '../widgets/user/event_description.dart';
import '../widgets/user/ticket_card.dart';
import '../widgets/user/ticket_counter.dart';
import '../widgets/user/timezone_dialog.dart';
import '../widgets/user/currency_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? _event;
  int _ticketCount = 1;
  bool _isLoading = true;
  Map<String, dynamic>? _selectedTicket;
  final _eventController = EventController();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final event = await _eventController.getEventDetail(widget.eventId);
    if (mounted) {
      setState(() {
        _event = event != null
            ? {
                'id': event.id,
                'title': event.name,
                'category': event.category,
                'event_date': event.date,
                'location': event.location,
                'price': event.price,
                'image_url': event.imageUrl,
                'description': event.description,
                'open_time': event.openTime,
                'close_time': event.closeTime,
                'early_bird_price': event.earlyBirdPrice,
                'early_bird_start': event.earlyBirdStart,
                'early_bird_end': event.earlyBirdEnd,
                'regular_start': event.regularStart,
                'regular_end': event.regularEnd,
                'ticket_options': event.ticketOptions,
                'latitude': event.latitude,
                'longitude': event.longitude,
                'created_at': event.createdAt,
              }
            : null;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildTicketOptions() {
    if (_event == null) return [];

    final now = DateTime.now();
    final List<Map<String, dynamic>> options = [];

    // Early Bird
    final ebPrice = _event!['early_bird_price'];
    final ebStart = _event!['early_bird_start'];
    final ebEnd = _event!['early_bird_end'];

    // Only show early bird if price > 0 AND has start/end dates
    final ebPriceInt = (ebPrice is double)
        ? ebPrice.toInt()
        : int.tryParse(ebPrice.toString()) ?? 0;
    final hasValidEarlyBird = ebPriceInt > 0 && (ebStart != null || ebEnd != null);

    if (hasValidEarlyBird) {
      bool available = true;
      String statusLabel = 'AVAILABLE';

      if (ebStart != null) {
        try {
          if (now.isBefore(DateTime.parse(ebStart.toString()))) {
            available = false;
            statusLabel = 'BELUM MULAI';
          }
        } catch (_) {}
      }
      if (available && ebEnd != null) {
        try {
          if (now.isAfter(DateTime.parse(ebEnd.toString()))) {
            available = false;
            statusLabel = 'SOLD OUT';
          }
        } catch (_) {}
      }

      options.add({
        'type': 'Early Bird',
        'price': ebPriceInt,
        'status': statusLabel,
        'available': available,
        'start': ebStart,
        'end': ebEnd,
        'desc': 'Harga spesial early bird',
      });
    }

    // Regular
    final regPrice = _event!['price'] ?? 0;
    final regStart = _event!['regular_start'];
    final regEnd = _event!['regular_end'];

    bool regAvailable = true;
    String regStatus = 'AVAILABLE';

    if (regStart != null) {
      try {
        if (now.isBefore(DateTime.parse(regStart.toString()))) {
          regAvailable = false;
          regStatus = 'BELUM MULAI';
        }
      } catch (_) {}
    }
    if (regAvailable && regEnd != null) {
      try {
        if (now.isAfter(DateTime.parse(regEnd.toString()))) {
          regAvailable = false;
          regStatus = 'SOLD OUT';
        }
      } catch (_) {}
    }

    options.add({
      'type': 'Reguler',
      'price': (regPrice is double)
          ? regPrice.toInt()
          : int.tryParse(regPrice.toString()) ?? 0,
      'status': regStatus,
      'available': regAvailable,
      'start': regStart,
      'end': regEnd,
      'desc': 'Harga reguler acara',
    });

    // Fallback: old ticket_options format
    if (options.isEmpty && _event!['ticket_options'] != null) {
      for (final t in (_event!['ticket_options'] as List)) {
        options.add({
          'type': t['type'],
          'price': (t['price'] is double)
              ? (t['price'] as double).toInt()
              : int.tryParse(t['price'].toString()) ?? 0,
          'status': t['status'],
          'available': t['status'] == 'AVAILABLE',
          'start': null,
          'end': null,
          'desc': t['desc'] ?? '',
        });
      }
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF2C3E50))));
    }
    if (_event == null) {
      return const Scaffold(
          body: Center(child: Text("Event tidak ditemukan")));
    }

    final ticketOptions = _buildTicketOptions();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF2C3E50),
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                ApiConfig.normalizeImageUrl(_event!['image_url'] ?? ''),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(LucideIcons.image,
                      size: 60, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Header
                  EventHeader(
                    event: _event!,
                    onTimezoneTap: () => TimezoneDialog.show(
                      context,
                      eventTitle: _event!['title'] ?? 'Jam Event',
                      openTime: _event!['open_time']?.toString(),
                      closeTime: _event!['close_time']?.toString(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Event Description
                  EventDescription(
                    description: _event!['description'] ?? '',
                  ),
                  const SizedBox(height: 28),

                  // Ticket Selection
                  const Text("Pilih Tiket",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  ...ticketOptions.map((ticket) {
                    final bool isSelected = _selectedTicket != null &&
                        _selectedTicket!['type'] == ticket['type'];

                    return TicketCard(
                      ticket: ticket,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedTicket = ticket),
                      onPriceTap: () => CurrencyDialog.show(
                        context,
                        priceIdr: ticket['price'] as int,
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Ticket Counter + Order Button
                  TicketCounter(
                    ticketCount: _ticketCount,
                    onIncrement: () => setState(() => _ticketCount++),
                    onDecrement: () => setState(() => _ticketCount--),
                    selectedTicket: _selectedTicket,
                    onOrder: () {
                      final priceInt = _selectedTicket!['price'] as int;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            event: Event(
                              id: widget.eventId,
                              name:
                                  '${_event!['title']} - ${_selectedTicket!['type']}',
                              description: _event!['description'] ?? '',
                              date: _event!['event_date'],
                              location: _event!['location'] ?? '',
                              latitude: _event!['latitude'] != null
                                  ? double.tryParse(
                                      _event!['latitude'].toString())
                                  : null,
                              longitude: _event!['longitude'] != null
                                  ? double.tryParse(
                                      _event!['longitude'].toString())
                                  : null,
                              price: priceInt,
                              imageUrl: _event!['image_url'],
                              createdAt: _event!['created_at'] ?? '',
                              category: _event!['category'],
                            ),
                            count: _ticketCount,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
