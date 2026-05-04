import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../config/api_config.dart';
import 'checkout_screen.dart';

// ─── Helper: format tanggal ISO → "12 Mei 2026" ──────────────────────────────
const List<String> _bulan = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final d = DateTime.parse(raw);
    return '${d.day} ${_bulan[d.month]} ${d.year}';
  } catch (_) {
    return raw;
  }
}

String _fmtPrice(dynamic price) {
  final p = (price is int) ? price : (double.tryParse(price.toString()) ?? 0).toInt();
  return p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

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
        // Convert Event model to Map for compatibility with existing UI
        _event = event != null ? {
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
        } : null;
        _isLoading = false;
      });
    }
  }

  // ─── Bangun ticket_options dari data event (pakai kolom baru) ───────────────
  List<Map<String, dynamic>> _buildTicketOptions() {
    if (_event == null) return [];

    final now = DateTime.now();
    final List<Map<String, dynamic>> options = [];

    // ── Early Bird ──
    final ebPrice = _event!['early_bird_price'];
    final ebStart = _event!['early_bird_start'];
    final ebEnd = _event!['early_bird_end'] ?? _event!['early_bird_deadline'];

    // Only show early bird if price > 0 AND has start/end dates
    final ebPriceInt = (ebPrice is double) ? ebPrice.toInt() : int.tryParse(ebPrice.toString()) ?? 0;
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

    // ── Reguler ──
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
      'price': (regPrice is double) ? regPrice.toInt() : int.tryParse(regPrice.toString()) ?? 0,
      'status': regStatus,
      'available': regAvailable,
      'start': regStart,
      'end': regEnd,
      'desc': 'Harga reguler acara',
    });

    // Fallback: kalau server masih kirim ticket_options lama
    if (options.isEmpty && _event!['ticket_options'] != null) {
      for (final t in (_event!['ticket_options'] as List)) {
        options.add({
          'type': t['type'],
          'price': (t['price'] is double) ? (t['price'] as double).toInt() : int.tryParse(t['price'].toString()) ?? 0,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF9A3412))));
    }
    if (_event == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Event tidak ditemukan",
            style: GoogleFonts.manrope(color: const Color(0xFF3A302A)),
          ),
        ),
      );
    }

    final ticketOptions = _buildTicketOptions();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EE),
      body: CustomScrollView(
        slivers: [
          // ── App bar dengan gambar ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF9A3412),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                ApiConfig.normalizeImageUrl(_event!['image_url'] ?? ''),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(LucideIcons.image, size: 60, color: Colors.grey),
                ),
              ),
            ),
          ),

          // ── Konten ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120), // Extra bottom padding for sticky section
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9A3412).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _event!['category'] ?? '',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF9A3412),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Judul
                  Text(
                    _event!['title'] ?? '',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A302A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tanggal
                  Row(children: [
                    const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF78706A)),
                    const SizedBox(width: 8),
                    Text(
                      _event!['event_date'] ?? '-',
                      style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  // Lokasi
                  Row(children: [
                    const Icon(LucideIcons.mapPin, size: 18, color: Color(0xFF78706A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _event!['location'] ?? '-',
                        style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  // Jam buka & tutup (tap untuk lihat konversi timezone)
                  if (_event!['open_time'] != null || _event!['close_time'] != null)
                    GestureDetector(
                      onTap: () => _showTimezoneDialog(
                        _event!['open_time']?.toString(),
                        _event!['close_time']?.toString(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9A3412).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD8D0C8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.clock, size: 15, color: Color(0xFF9A3412)),
                            const SizedBox(width: 8),
                            Text(
                              _buildTimeDisplay(
                                _event!['open_time']?.toString(),
                                _event!['close_time']?.toString(),
                              ),
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF9A3412),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.globe, size: 13, color: Color(0xFF78706A)),
                            const SizedBox(width: 3),
                            Text(
                              'Lihat zona waktu lain',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF78706A),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Deskripsi
                  Text(
                    "Tentang Acara",
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A302A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _event!['description'] ?? 'Tidak ada deskripsi.',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF78706A),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Pilihan Tiket ──
                  Text(
                    "Pilih Tiket",
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A302A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...ticketOptions.map((ticket) {
                    final bool isAvailable = ticket['available'] == true;
                    final bool isSelected = _selectedTicket != null &&
                        _selectedTicket!['type'] == ticket['type'];

                    return GestureDetector(
                      onTap: isAvailable ? () => setState(() => _selectedTicket = ticket) : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: !isAvailable
                              ? const Color(0xFFFAFAF9)
                              : isSelected
                                  ? const Color(0xFF9A3412).withOpacity(0.05)
                                  : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF9A3412)
                                : const Color(0xFFD8D0C8),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Nama tiket + status
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket['type'],
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isAvailable ? const Color(0xFF3A302A) : const Color(0xFF78706A),
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
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            color: isAvailable ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Harga
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showCurrencyDialog(ticket['price'] as int),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Rp ${_fmtPrice(ticket['price'])}',
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isAvailable
                                                  ? const Color(0xFF9A3412)
                                                  : const Color(0xFF78706A),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            LucideIcons.refreshCcw,
                                            size: 12,
                                            color: isAvailable ? const Color(0xFF78706A) : const Color(0xFFD8D0C8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '/ tiket',
                                      style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF78706A)),
                                    ),
                                    if (isAvailable)
                                      Text(
                                        'tap untuk konversi',
                                        style: GoogleFonts.manrope(fontSize: 9, color: const Color(0xFF78706A)),
                                      ),
                                  ],
                                ),
                              ],
                            ),

                            // Periode tanggal
                            if (ticket['start'] != null || ticket['end'] != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAE2DA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.calendarRange, size: 12, color: Color(0xFF78706A)),
                                    const SizedBox(width: 5),
                                    Text(
                                      _buildPeriodText(ticket['start'], ticket['end']),
                                      style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF78706A)),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Deskripsi tiket
                            if (ticket['desc'] != null && ticket['desc'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                ticket['desc'],
                                style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF78706A)),
                              ),
                            ],

                            // Checkmark kalau dipilih
                            if (isSelected) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF9A3412)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dipilih',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: const Color(0xFF9A3412),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      // ── Sticky Bottom Section: Counter + Button ──
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAF9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: const Color(0xFFD8D0C8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview total harga
              if (_selectedTicket != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A3412).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_ticketCount tiket × Rp ${_fmtPrice(_selectedTicket!['price'])}',
                        style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 13),
                      ),
                      Text(
                        'Rp ${_fmtPrice((_selectedTicket!['price'] as int) * _ticketCount)}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9A3412),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Counter + Button
              Row(
                children: [
                  // Counter
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD8D0C8)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.minus, size: 16),
                          onPressed: _ticketCount > 1
                              ? () => setState(() => _ticketCount--)
                              : null,
                          color: _ticketCount > 1 ? const Color(0xFF9A3412) : const Color(0xFF78706A),
                        ),
                        Text(
                          '$_ticketCount',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.plus, size: 16),
                          onPressed: () => setState(() => _ticketCount++),
                          color: const Color(0xFF9A3412),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol pesan
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedTicket == null
                          ? null
                          : () {
                              final priceInt = _selectedTicket!['price'] as int;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                    event: Event(
                                      id: widget.eventId,
                                      name: '${_event!['title']} - ${_selectedTicket!['type']}',
                                      description: _event!['description'] ?? '',
                                      date: _event!['event_date'],
                                      location: _event!['location'] ?? '',
                                      latitude: _event!['latitude'] != null ? double.tryParse(_event!['latitude'].toString()) : null,
                                      longitude: _event!['longitude'] != null ? double.tryParse(_event!['longitude'].toString()) : null,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A3412),
                        disabledBackgroundColor: const Color(0xFFD8D0C8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _selectedTicket == null ? 'Pilih Tiket Dulu' : 'Pesan $_ticketCount Tiket',
                        style: GoogleFonts.manrope(
                          color: _selectedTicket == null ? const Color(0xFF78706A) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildPeriodText(dynamic start, dynamic end) {
    final s = start != null ? _fmtDate(start.toString()) : null;
    final e = end != null ? _fmtDate(end.toString()) : null;
    if (s != null && e != null) return '$s – $e';
    if (s != null) return 'Mulai $s';
    if (e != null) return 'Sampai $e';
    return '';
  }

  // ─── Jam buka/tutup helpers ───────────────────────────────────────────────

  String _buildTimeDisplay(String? open, String? close) {
    final o = _fmtTime(open);
    final c = _fmtTime(close);
    if (o != null && c != null) return '$o – $c WIB';
    if (o != null) return 'Buka $o WIB';
    if (c != null) return 'Tutup $c WIB';
    return '-';
  }

  /// Format "HH:MM:SS" → "HH:MM"
  String? _fmtTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return raw;
  }

  /// Parse jam dari string "HH:MM:SS" ke menit sejak tengah malam
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

  /// Konversi menit WIB ke timezone lain
  String _convertTime(int wibMinutes, int offsetFromWib) {
    int total = wibMinutes + offsetFromWib;
    // Handle overflow
    total = total % (24 * 60);
    if (total < 0) total += 24 * 60;
    final h = total ~/ 60;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // ─── Dialog konversi timezone ─────────────────────────────────────────────

  void _showTimezoneDialog(String? openTime, String? closeTime) {
    final openMin = _timeToMinutes(openTime);
    final closeMin = _timeToMinutes(closeTime);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(LucideIcons.globe, color: Color(0xFF9A3412)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _event!['title'] ?? 'Jam Event',
              style: GoogleFonts.ebGaramond(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A302A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Jam operasional dalam berbagai zona waktu:',
              style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 12),
            ),
            const SizedBox(height: 16),
            // WIB (base)
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
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: GoogleFonts.manrope(color: const Color(0xFF9A3412))),
          ),
        ],
      ),
    );
  }

  Widget _tzRow(String zone, String label, int? openMin, int? closeMin, int offsetFromWib) {
    String timeStr;
    if (openMin != null && closeMin != null) {
      timeStr = '${_convertTime(openMin, offsetFromWib)} – ${_convertTime(closeMin, offsetFromWib)}';
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
          Text(
            zone,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: const Color(0xFF3A302A),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF78706A)),
          ),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF9A3412),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            timeStr,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Dialog konversi harga ke mata uang lain ──────────────────────────────

  void _showCurrencyDialog(int priceIdr) {
    String toCurrency = 'USD';
    String resultText = 'Tap Konversi';
    bool isLoading = false;

    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'SGD', 'MYR', 'AUD'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFFFAFAF9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(LucideIcons.refreshCcw, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Konversi Harga Tiket',
              style: GoogleFonts.ebGaramond(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A302A),
              ),
            ),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Harga IDR
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE2DA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Harga dalam IDR',
                      style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 11),
                    ),
                    Text(
                      'Rp ${_fmtPrice(priceIdr)}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: const Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Pilih mata uang tujuan
              Row(
                children: [
                  Text(
                    'Konversi ke:',
                    style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: toCurrency,
                      style: GoogleFonts.manrope(color: const Color(0xFF3A302A)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFD8D0C8)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: currencies
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: GoogleFonts.manrope()),
                              ))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => toCurrency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Hasil konversi
              isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF9A3412))
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        resultText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Tutup',
                style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A3412),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                setStateDialog(() => isLoading = true);
                try {
                  final res = await http.get(Uri.parse(
                      'https://api.frankfurter.app/latest?amount=$priceIdr&from=IDR&to=$toCurrency'));
                  if (res.statusCode == 200) {
                    final data = jsonDecode(res.body);
                    final rate = data['rates'][toCurrency];
                    setStateDialog(() => resultText = '$rate $toCurrency');
                  } else {
                    setStateDialog(() => resultText = 'Gagal memuat kurs');
                  }
                } catch (e) {
                  setStateDialog(() => resultText = 'Error jaringan');
                } finally {
                  setStateDialog(() => isLoading = false);
                }
              },
              child: Text(
                'Konversi',
                style: GoogleFonts.manrope(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
