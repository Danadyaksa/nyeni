import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../config/api_config.dart';

// Indonesian month names
const List<String> _bulanId = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> _bulanIdFull = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _formatDateDisplay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_bulanId[d.month]} ${d.year}';

String _formatDateIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "12 Mei 2026" or "25 Mei - 25 Jul 2026"
String _buildEventDateString(DateTime start, DateTime? end) {
  if (end == null || _isSameDay(start, end)) {
    return '${start.day} ${_bulanIdFull[start.month]} ${start.year}';
  }
  if (start.year == end.year) {
    if (start.month == end.month) {
      return '${start.day} - ${end.day} ${_bulanIdFull[end.month]} ${end.year}';
    }
    return '${start.day} ${_bulanIdFull[start.month]} - ${end.day} ${_bulanIdFull[end.month]} ${end.year}';
  }
  return '${start.day} ${_bulanIdFull[start.month]} ${start.year} - ${end.day} ${_bulanIdFull[end.month]} ${end.year}';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime? _parseDate(dynamic val) {
  if (val == null) return null;
  try {
    return DateTime.parse(val.toString());
  } catch (_) {
    return null;
  }
}

const Color _primary = Color(0xFF9A3412);
const Color _background = Color(0xFFFAF5EE);
const Color _cardBorder = Color(0xFFD8D0C8);
const Color _textPrimary = Color(0xFF3A302A);
const Color _textSecondary = Color(0xFF78706A);

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _adminController = AdminController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _events = [];
  List<dynamic> _filteredEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterEvents();
    });
  }

  void _filterEvents() {
    if (_searchQuery.isEmpty) {
      _filteredEvents = _events;
    } else {
      _filteredEvents = _events.where((event) {
        final title = event['title']?.toString().toLowerCase() ?? '';
        final category = event['category']?.toString().toLowerCase() ?? '';
        final location = event['location']?.toString().toLowerCase() ?? '';
        return title.contains(_searchQuery) ||
               category.contains(_searchQuery) ||
               location.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final data = await _adminController.getAllEventsAdmin();
    if (mounted) {
      setState(() {
        _events = data;
        _filterEvents();
        _isLoading = false;
      });
    }
  }

  void _openForm({Map<String, dynamic>? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventFormSheet(
        event: event,
        onSaved: (data) async {
          Map<String, dynamic> result;
          if (event != null) {
            result = await _adminController.updateEvent(
              id: event['id'] as int,
              name: data['title'],
              category: data['category'] ?? 'Pameran',
              description: data['description'] ?? '',
              date: data['event_date'],
              location: data['location'],
              latitude: data['latitude'],
              longitude: data['longitude'],
              price: data['price'],
              imageUrl: data['image_url'],
              isActive: (data['is_active'] == 1 || data['is_active'] == true),
              eventStartDate: data['event_start_date'],
              eventEndDate: data['event_end_date'],
              openTime: data['open_time'],
              closeTime: data['close_time'],
              regularStart: data['regular_start'],
              regularEnd: data['regular_end'],
              earlyBirdPrice: data['early_bird_price'],
              earlyBirdStart: data['early_bird_start'],
              earlyBirdEnd: data['early_bird_end'],
            );
          } else {
            print('🔵 Creating new event with data: $data');
            result = await _adminController.createEvent(
              name: data['title'],
              category: data['category'] ?? 'Pameran',
              description: data['description'] ?? '',
              date: data['event_date'],
              location: data['location'],
              latitude: data['latitude'],
              longitude: data['longitude'],
              price: data['price'],
              imageUrl: data['image_url'],
              isActive: (data['is_active'] == 1 || data['is_active'] == true),
              eventStartDate: data['event_start_date'],
              eventEndDate: data['event_end_date'],
              openTime: data['open_time'],
              closeTime: data['close_time'],
              regularStart: data['regular_start'],
              regularEnd: data['regular_end'],
              earlyBirdPrice: data['early_bird_price'],
              earlyBirdStart: data['early_bird_start'],
              earlyBirdEnd: data['early_bird_end'],
            );
            print('🔵 Create event result: $result');
          }
          if (result.containsKey('error')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal: ${result['error']}'), backgroundColor: Colors.red),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(event != null ? 'Event berhasil diperbarui' : 'Event berhasil ditambahkan'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadEvents();
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteEvent(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Event', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "$title"?\n\nEvent yang sudah dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await _adminController.deleteEvent(id);
      if (mounted) {
        final success = result['success'] == true;
        String message = success 
            ? (result['message'] ?? 'Event berhasil dihapus')
            : (result['error'] ?? 'Gagal menghapus event');
        
        // Tambahkan suggestion jika ada
        if (!success && result['suggestion'] != null) {
          message += '\n\n💡 ${result['suggestion']}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: Duration(seconds: success ? 3 : 5),
          ),
        );
        if (success) _loadEvents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          'Kelola Event',
          style: GoogleFonts.libreBaskerville(
            fontWeight: FontWeight.w700,
            color: _primary,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFFAFAF9),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF78716C)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF78716C), size: 20),
            onPressed: _loadEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          'Tambah Event',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAF9),
                    border: Border(
                      bottom: BorderSide(
                        color: _cardBorder.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari event...',
                      hintStyle: GoogleFonts.manrope(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        color: _textSecondary,
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                LucideIcons.x,
                                color: _textSecondary,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      color: _textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Event list
                Expanded(
                  child: _filteredEvents.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadEvents,
                          color: _primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (_, i) => _buildEventCard(_filteredEvents[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    if (_searchQuery.isNotEmpty) {
      // Empty search results
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil untuk "$_searchQuery"',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }
    
    // No events at all
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarX, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Belum ada event', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tap tombol + untuk menambahkan event baru', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
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
                // Title + active badge + expired badge
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
                    // Badge Expired (jika event sudah lewat)
                    if (event['is_expired'] == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: const Text(
                          'Berakhir',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    // Badge Active/Nonaktif
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
                        onPressed: () => _openForm(event: event),
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
                        onPressed: () => _deleteEvent(event['id'] as int, event['title']?.toString() ?? ''),
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

class _EventFormSheet extends StatefulWidget {
  final Map<String, dynamic>? event;
  final Future<void> Function(Map<String, dynamic> data) onSaved;

  const _EventFormSheet({this.event, required this.onSaved});

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _earlyBirdPriceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Category
  String _category = 'Konser';
  final List<String> _categories = ['Konser', 'Teater', 'Pameran', 'Stand Up', 'Festival', 'Workshop'];

  // Dates
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;
  bool _showEndDate = false;
  DateTime? _regularStart;
  DateTime? _regularEnd;
  DateTime? _earlyBirdStart;
  DateTime? _earlyBirdEnd;

  // Jam buka & tutup
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  // Map
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  static final LatLng _defaultCenter = LatLng(-7.7956, 110.3695); // Yogyakarta (default)
  LatLng? _currentLocation; // Lokasi GPS user
  bool _isLoadingLocation = false;

  // Image
  File? _pickedImage;
  String? _existingImageUrl;
  bool _isUploadingImage = false;

  // Active
  bool _isActive = true;

  // Saving
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prefillFromEvent();
    _getCurrentLocation(); // Ambil lokasi GPS saat form dibuka
  }

  // Get current location (GPS)
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Cek permission dulu
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission ditolak, pakai default Yogyakarta
          if (mounted) setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission ditolak permanent, pakai default Yogyakarta
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      // Ambil posisi GPS
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _prefillFromEvent() {
    final e = widget.event;
    if (e == null) return;

    _titleCtrl.text = e['title']?.toString() ?? '';
    _locationCtrl.text = e['location']?.toString() ?? '';
    
    // Fix: Pastikan price tidak kosong
    final price = e['price'];
    if (price != null && price.toString().isNotEmpty && price.toString() != 'null') {
      _priceCtrl.text = price.toString();
    }
    
    // Fix: Pastikan early bird price tidak kosong
    final earlyBirdPrice = e['early_bird_price'];
    if (earlyBirdPrice != null && earlyBirdPrice.toString().isNotEmpty && earlyBirdPrice.toString() != 'null') {
      _earlyBirdPriceCtrl.text = earlyBirdPrice.toString();
    }
    
    _descCtrl.text = e['description']?.toString() ?? '';

    if (_categories.contains(e['category'])) {
      _category = e['category'].toString();
    }

    // Fix: Parse tanggal dengan lebih robust
    _eventStartDate = _parseDate(e['event_start_date']);
    _eventEndDate = _parseDate(e['event_end_date']);
    _showEndDate = _eventEndDate != null;

    _regularStart = _parseDate(e['regular_start']);
    _regularEnd = _parseDate(e['regular_end']);
    _earlyBirdStart = _parseDate(e['early_bird_start']);
    _earlyBirdEnd = _parseDate(e['early_bird_end']);

    _existingImageUrl = e['image_url']?.toString();

    _isActive = (e['is_active'] == 1 || e['is_active'] == true);

    // Parse jam buka/tutup dari format "HH:MM:SS" atau "HH:MM"
    _openTime = _parseTime(e['open_time']?.toString());
    _closeTime = _parseTime(e['close_time']?.toString());

    // Fix: Parse koordinat dengan lebih robust
    final lat = e['latitude'];
    final lng = e['longitude'];
    if (lat != null && lng != null) {
      final latDouble = (lat is double) ? lat : double.tryParse(lat.toString());
      final lngDouble = (lng is double) ? lng : double.tryParse(lng.toString());
      
      if (latDouble != null && lngDouble != null && latDouble != 0 && lngDouble != 0) {
        _pickedLocation = LatLng(latDouble, lngDouble);
      }
    }
    
    // Debug log untuk cek data yang di-load
    debugPrint('🔵 Prefill data:');
    debugPrint('  - Event Start: $_eventStartDate');
    debugPrint('  - Event End: $_eventEndDate');
    debugPrint('  - Regular Start: $_regularStart');
    debugPrint('  - Regular End: $_regularEnd');
    debugPrint('  - Early Bird Start: $_earlyBirdStart');
    debugPrint('  - Early Bird End: $_earlyBirdEnd');
    debugPrint('  - Open Time: $_openTime');
    debugPrint('  - Close Time: $_closeTime');
    debugPrint('  - Location: $_pickedLocation');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _earlyBirdPriceCtrl.dispose();
    _descCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Date picker
  Future<DateTime?> _pickDate({DateTime? initial, DateTime? firstDate, DateTime? lastDate}) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
  }

  /// Parse tanggal dari string seperti "12 Mei 2026" atau "2026-05-12"
  DateTime? _parseDateFromString(String raw) {
    // ISO format
    try { return DateTime.parse(raw.split(' ').first); } catch (_) {}
    // "12 Mei 2026" format
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'jun': 6,
      'jul': 7, 'agu': 8, 'sep': 9, 'okt': 10, 'nov': 11, 'des': 12,
    };
    final parts = raw.toLowerCase().split(RegExp(r'[\s\-]+'));
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]);
      final month = months[parts[1].substring(0, 3)];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  /// Parse TimeOfDay dari string "HH:MM" atau "HH:MM:SS"
  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  /// Format TimeOfDay ke string "HH:MM" untuk dikirim ke server
  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Tampilkan time picker
  Future<TimeOfDay?> _pickTime({TimeOfDay? initial}) async {
    return showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
  }

  // Image picker & upload
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() { _pickedImage = File(picked.path); });
  }

  Future<String?> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      final uri = Uri.parse('${AuthController.baseUrl}/admin/events/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final url = body['image_url']?.toString();
        return url;
      }
      // Log error response supaya bisa debug
      debugPrint('Upload image failed: ${response.statusCode} — ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Upload image exception: $e');
      return null;
    } finally {
      // Cek mounted sebelum setState karena bisa dipanggil setelah pop
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // Save event
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Kalau event_start_date null (event lama), parse dari event_date string
    if (_eventStartDate == null) {
      // Coba parse dari event_date yang ada
      final rawDate = widget.event?['event_date']?.toString() ?? '';
      if (rawDate.isNotEmpty) {
        _eventStartDate = _parseDateFromString(rawDate);
      }
      // Kalau masih null, pakai hari ini sebagai fallback
      _eventStartDate ??= DateTime.now();
    }

    setState(() => _isSaving = true);

    // Upload gambar dulu sebelum apapun — tunggu sampai selesai
    String? imageUrl = _existingImageUrl;
    if (_pickedImage != null) {
      final uploaded = await _uploadImage(_pickedImage!);
      if (uploaded != null) {
        imageUrl = uploaded;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal upload gambar, coba lagi'), backgroundColor: Colors.red),
          );
          setState(() => _isSaving = false);
        }
        return; // Berhenti — jangan lanjut save kalau upload gagal
      }
    }

    final eventDate = _buildEventDateString(
      _eventStartDate!,
      _showEndDate ? _eventEndDate : null,
    );

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'category': _category,
      'event_date': eventDate,
      'event_start_date': _formatDateIso(_eventStartDate!),
      'event_end_date': (_showEndDate && _eventEndDate != null) ? _formatDateIso(_eventEndDate!) : null,
      'location': _locationCtrl.text.trim(),
      'latitude': _pickedLocation?.latitude,
      'longitude': _pickedLocation?.longitude,
      'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
      'regular_start': _regularStart != null ? _formatDateIso(_regularStart!) : null,
      'regular_end': _regularEnd != null ? _formatDateIso(_regularEnd!) : null,
      'early_bird_price': _earlyBirdPriceCtrl.text.trim().isNotEmpty
          ? int.tryParse(_earlyBirdPriceCtrl.text.trim())
          : null,
      'early_bird_start': _earlyBirdStart != null ? _formatDateIso(_earlyBirdStart!) : null,
      'early_bird_end': _earlyBirdEnd != null ? _formatDateIso(_earlyBirdEnd!) : null,
      'open_time': _formatTime(_openTime),
      'close_time': _formatTime(_closeTime),
      'image_url': imageUrl ?? '',
      'description': _descCtrl.text.trim(),
      'is_active': _isActive ? 1 : 0,
    };

    // Tutup sheet SETELAH data siap, SEBELUM memanggil onSaved
    // supaya context masih valid saat onSaved menampilkan SnackBar
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }

    await widget.onSaved(data);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(isEdit ? LucideIcons.pencil : LucideIcons.plus, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Event' : 'Tambah Event',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _sectionLabel('Informasi Dasar'),
                    _buildTextField(
                      controller: _titleCtrl,
                      label: 'Judul Event',
                      icon: LucideIcons.type,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 20),

                    _sectionLabel('Tanggal Event'),
                    _buildDateField(
                      label: 'Tanggal Mulai *',
                      date: _eventStartDate,
                      icon: LucideIcons.calendarDays,
                      onTap: () async {
                        final d = await _pickDate(initial: _eventStartDate);
                        if (d != null) setState(() => _eventStartDate = d);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (!_showEndDate)
                      TextButton.icon(
                        onPressed: () => setState(() { _showEndDate = true; }),
                        icon: const Icon(LucideIcons.calendarPlus, size: 16),
                        label: const Text('Tambah Tanggal Selesai'),
                        style: TextButton.styleFrom(foregroundColor: _primary),
                      )
                    else ...[
                      _buildDateField(
                        label: 'Tanggal Selesai (opsional)',
                        date: _eventEndDate,
                        icon: LucideIcons.calendarCheck,
                        onTap: () async {
                          final d = await _pickDate(
                            initial: _eventEndDate ?? _eventStartDate,
                            firstDate: _eventStartDate,
                          );
                          if (d != null) setState(() => _eventEndDate = d);
                        },
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: Colors.grey),
                          onPressed: () => setState(() { _showEndDate = false; _eventEndDate = null; }),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    _sectionLabel('Lokasi'),
                    _buildTextField(
                      controller: _locationCtrl,
                      label: 'Nama Lokasi / Venue',
                      icon: LucideIcons.mapPin,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildMapPicker(),
                    const SizedBox(height: 20),

                    _sectionLabel('Harga Reguler'),
                    _buildTextField(
                      controller: _priceCtrl,
                      label: 'Harga Reguler (Rp)',
                      icon: LucideIcons.ticket,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Harga wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Mulai Reguler',
                            date: _regularStart,
                            icon: LucideIcons.calendar,
                            onTap: () async {
                              final d = await _pickDate(initial: _regularStart);
                              if (d != null) setState(() => _regularStart = d);
                            },
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateField(
                            label: 'Selesai Reguler',
                            date: _regularEnd,
                            icon: LucideIcons.calendar,
                            onTap: () async {
                              final d = await _pickDate(initial: _regularEnd ?? _regularStart);
                              if (d != null) setState(() => _regularEnd = d);
                            },
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel('Harga Early Bird (Opsional)'),
                    _buildTextField(
                      controller: _earlyBirdPriceCtrl,
                      label: 'Harga Early Bird (Rp)',
                      icon: LucideIcons.zap,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Mulai Early Bird',
                            date: _earlyBirdStart,
                            icon: LucideIcons.calendar,
                            onTap: () async {
                              final d = await _pickDate(initial: _earlyBirdStart);
                              if (d != null) setState(() => _earlyBirdStart = d);
                            },
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateField(
                            label: 'Selesai Early Bird',
                            date: _earlyBirdEnd,
                            icon: LucideIcons.calendar,
                            onTap: () async {
                              final d = await _pickDate(initial: _earlyBirdEnd ?? _earlyBirdStart);
                              if (d != null) setState(() => _earlyBirdEnd = d);
                            },
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel('Jam Operasional (Opsional)'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeField(
                            label: 'Jam Buka',
                            time: _openTime,
                            icon: LucideIcons.doorOpen,
                            onTap: () async {
                              final t = await _pickTime(initial: _openTime);
                              if (t != null) setState(() => _openTime = t);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeField(
                            label: 'Jam Tutup',
                            time: _closeTime,
                            icon: LucideIcons.doorClosed,
                            onTap: () async {
                              final t = await _pickTime(initial: _closeTime ?? _openTime);
                              if (t != null) setState(() => _closeTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel('Gambar Event'),
                    _buildImagePicker(),
                    const SizedBox(height: 20),

                    _sectionLabel('Deskripsi'),
                    _buildTextField(
                      controller: _descCtrl,
                      label: 'Deskripsi event...',
                      icon: LucideIcons.alignLeft,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel('Status'),
                    _buildActiveToggle(),
                    const SizedBox(height: 28),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(isEdit ? LucideIcons.save : LucideIcons.plus, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : (isEdit ? 'Simpan Perubahan' : 'Tambah Event'),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Form widgets
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: const Icon(LucideIcons.tag, size: 18, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
      items: _categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) { if (v != null) setState(() => _category = v); },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    bool compact = false,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 10 : 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[350]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? _formatDateDisplay(date) : label,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  color: date != null ? Colors.black87 : Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final display = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                display,
                style: TextStyle(
                  fontSize: 14,
                  color: time != null ? Colors.black87 : Colors.grey[500],
                ),
              ),
            ),
            if (time != null)
              GestureDetector(
                onTap: () => setState(() {
                  if (icon == LucideIcons.doorOpen) {
                    _openTime = null;
                  } else {
                    _closeTime = null;
                  }
                }),
                child: const Icon(LucideIcons.x, size: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPicker() {
    // Prioritas: 1. Lokasi yang sudah dipilih, 2. Lokasi GPS user, 3. Default Yogyakarta
    final center = _pickedLocation ?? _currentLocation ?? _defaultCenter;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 14, color: _primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _pickedLocation != null
                    ? 'Pin: ${_pickedLocation!.latitude.toStringAsFixed(5)}, ${_pickedLocation!.longitude.toStringAsFixed(5)}'
                    : _isLoadingLocation
                        ? 'Mengambil lokasi Anda...'
                        : _currentLocation != null
                            ? 'Peta di lokasi Anda (tap untuk pin)'
                            : 'Tap peta untuk menentukan lokasi',
                style: TextStyle(
                  fontSize: 12,
                  color: _pickedLocation != null ? _primary : Colors.grey[600],
                ),
              ),
            ),
            if (_pickedLocation != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _pickedLocation = null),
                child: const Icon(LucideIcons.x, size: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15, // Zoom lebih dekat untuk lokasi user
                    onTap: (tapPos, latLng) {
                      setState(() => _pickedLocation = latLng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.nyeni_app',
                    ),
                    // Marker lokasi yang dipilih (merah)
                    if (_pickedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(LucideIcons.mapPin, color: Colors.red, size: 36),
                          ),
                        ],
                      ),
                    // Marker lokasi user saat ini (biru) - hanya tampil kalau belum pilih lokasi
                    if (_pickedLocation == null && _currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.navigation, color: Colors.blue, size: 24),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                // Loading indicator
                if (_isLoadingLocation)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Info tambahan
        if (_currentLocation != null && _pickedLocation == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 12, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Marker biru = lokasi Anda saat ini. Tap peta untuk pin lokasi event.',
                    style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview
        if (_pickedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _pickedImage!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _pickedImage = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          )
        else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiConfig.normalizeImageUrl(_existingImageUrl!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imageEmptyBox(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _existingImageUrl = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          )
        else
          _imageEmptyBox(),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploadingImage ? null : _pickImage,
            icon: _isUploadingImage
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                  )
                : const Icon(LucideIcons.image, size: 16),
            label: Text(_isUploadingImage ? 'Mengupload...' : 'Pilih Gambar dari Galeri'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imageEmptyBox() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.image, size: 36, color: Colors.grey[400]),
          const SizedBox(height: 6),
          Text('Belum ada gambar', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[350]!),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? LucideIcons.eye : LucideIcons.eyeOff,
            size: 18,
            color: _isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  _isActive ? 'Aktif - tampil di aplikasi' : 'Nonaktif - tersembunyi dari pengguna',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: _primary,
          ),
        ],
      ),
    );
  }
}
