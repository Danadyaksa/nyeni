import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final data = await AuthService().getEventDetail(widget.eventId);
    if (mounted) {
      setState(() {
        _event = data;
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

    if (ebPrice != null) {
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
        'price': (ebPrice is double) ? ebPrice.toInt() : int.tryParse(ebPrice.toString()) ?? 0,
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
      'type': 'Normal',
      'price': (regPrice is double) ? regPrice.toInt() : int.tryParse(regPrice.toString()) ?? 0,
      'status': regStatus,
      'available': regAvailable,
      'start': regStart,
      'end': regEnd,
      'desc': 'Harga normal acara',
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
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50))));
    }
    if (_event == null) {
      return const Scaffold(body: Center(child: Text("Event tidak ditemukan")));
    }

    final ticketOptions = _buildTicketOptions();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar dengan gambar ──
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
                _event!['image_url'] ?? '',
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _event!['category'] ?? '',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Judul
                  Text(
                    _event!['title'] ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Tanggal
                  Row(children: [
                    const Icon(LucideIcons.calendar, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(_event!['event_date'] ?? '-', style: const TextStyle(color: Colors.grey)),
                  ]),
                  const SizedBox(height: 8),

                  // Lokasi
                  Row(children: [
                    const Icon(LucideIcons.mapPin, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_event!['location'] ?? '-', style: const TextStyle(color: Colors.grey)),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Deskripsi
                  const Text("Tentang Acara", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _event!['description'] ?? 'Tidak ada deskripsi.',
                    style: const TextStyle(color: Colors.grey, height: 1.6),
                  ),
                  const SizedBox(height: 28),

                  // ── Pilihan Tiket ──
                  const Text("Pilih Tiket", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              ? Colors.grey.shade50
                              : isSelected
                                  ? const Color(0xFF2C3E50).withOpacity(0.05)
                                  : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2C3E50)
                                : Colors.grey.shade300,
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
                                // Nama tiket + status
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
                                // Harga
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
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
                                    const Text('/ tiket', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.calendarRange, size: 12, color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(
                                      _buildPeriodText(ticket['start'], ticket['end']),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],

                            // Checkmark kalau dipilih
                            if (isSelected) ...[
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF2C3E50)),
                                  SizedBox(width: 4),
                                  Text('Dipilih', style: TextStyle(fontSize: 11, color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // ── Counter + Tombol Pesan ──
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
                                onPressed: _ticketCount > 1
                                    ? () => setState(() => _ticketCount--)
                                    : null,
                                color: _ticketCount > 1 ? const Color(0xFF2C3E50) : Colors.grey,
                              ),
                              Text(
                                '$_ticketCount',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.plus, size: 16),
                                onPressed: () => setState(() => _ticketCount++),
                                color: const Color(0xFF2C3E50),
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
                                            title: '${_event!['title']} - ${_selectedTicket!['type']}',
                                            organizer: 'Panitia Nyeni',
                                            date: _event!['event_date'],
                                            price: 'Rp $priceInt',
                                            image: _event!['image_url'] ?? '',
                                            category: _event!['category'] ?? '',
                                          ),
                                          count: _ticketCount,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C3E50),
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _selectedTicket == null ? 'Pilih Tiket Dulu' : 'Pesan $_ticketCount Tiket',
                              style: TextStyle(
                                color: _selectedTicket == null ? Colors.grey : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Preview total harga
                  if (_selectedTicket != null) ...[
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
                            '$_ticketCount tiket × Rp ${_fmtPrice(_selectedTicket!['price'])}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            'Rp ${_fmtPrice((_selectedTicket!['price'] as int) * _ticketCount)}',
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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
}
