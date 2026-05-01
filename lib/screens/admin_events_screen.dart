import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

// ─── Indonesian month names ───────────────────────────────────────────────────
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

const Color _primary = Color(0xFF2C3E50);

// ─── Main Screen ─────────────────────────────────────────────────────────────

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _adminService = AdminService();
  List<dynamic> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final data = await _adminService.getAllEventsAdmin();
    if (mounted) setState(() { _events = data; _isLoading = false; });
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
            result = await _adminService.updateEvent(event['id'] as int, data);
          } else {
            result = await _adminService.createEvent(data);
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
        content: Text('Yakin ingin menghapus "$title"?'),
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
      final ok = await _adminService.deleteEvent(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Event dihapus' : 'Gagal menghapus event'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        if (ok) _loadEvents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Kelola Event',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _primary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: _loadEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Tambah Event', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _events.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  color: _primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _events.length,
                    itemBuilder: (_, i) => _buildEventCard(_events[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
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
                    imageUrl,
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

// ─── Event Form Bottom Sheet ──────────────────────────────────────────────────

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

  // Map
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  static final LatLng _defaultCenter = LatLng(-6.2088, 106.8456); // Jakarta

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
  }

  void _prefillFromEvent() {
    final e = widget.event;
    if (e == null) return;

    _titleCtrl.text = e['title']?.toString() ?? '';
    _locationCtrl.text = e['location']?.toString() ?? '';
    _priceCtrl.text = (e['price'] ?? '').toString();
    _earlyBirdPriceCtrl.text = (e['early_bird_price'] ?? '').toString();
    _descCtrl.text = e['description']?.toString() ?? '';

    if (_categories.contains(e['category'])) {
      _category = e['category'].toString();
    }

    _eventStartDate = _parseDate(e['event_start_date']);
    _eventEndDate = _parseDate(e['event_end_date']);
    _showEndDate = _eventEndDate != null;

    _regularStart = _parseDate(e['regular_start']);
    _regularEnd = _parseDate(e['regular_end']);
    _earlyBirdStart = _parseDate(e['early_bird_start']);
    _earlyBirdEnd = _parseDate(e['early_bird_end']);

    _existingImageUrl = e['image_url']?.toString();

    _isActive = (e['is_active'] == 1 || e['is_active'] == true);

    final lat = e['latitude'];
    final lng = e['longitude'];
    if (lat != null && lng != null) {
      _pickedLocation = LatLng(
        (lat is double) ? lat : double.tryParse(lat.toString()) ?? 0,
        (lng is double) ? lng : double.tryParse(lng.toString()) ?? 0,
      );
    }
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

  // ─── Date Picker ───────────────────────────────────────────────────────────

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

  // ─── Image Picker & Upload ─────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() { _pickedImage = File(picked.path); });
  }

  Future<String?> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      final uri = Uri.parse('${AuthService.baseUrl}/admin/events/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['image_url']?.toString();
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal mulai event'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Upload image if new one picked
    String? imageUrl = _existingImageUrl;
    if (_pickedImage != null) {
      final uploaded = await _uploadImage(_pickedImage!);
      if (uploaded != null) {
        imageUrl = uploaded;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal upload gambar'), backgroundColor: Colors.red),
          );
          setState(() => _isSaving = false);
          return;
        }
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
      'image_url': imageUrl ?? '',
      'description': _descCtrl.text.trim(),
      'is_active': _isActive ? 1 : 0,
    };

    if (mounted) Navigator.pop(context);
    await widget.onSaved(data);
    if (mounted) setState(() => _isSaving = false);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

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

  // ─── Form Widgets ──────────────────────────────────────────────────────────

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

  Widget _buildMapPicker() {
    final center = _pickedLocation ?? _defaultCenter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 14, color: _primary),
            const SizedBox(width: 6),
            Text(
              _pickedLocation != null
                  ? 'Pin: ${_pickedLocation!.latitude.toStringAsFixed(5)}, ${_pickedLocation!.longitude.toStringAsFixed(5)}'
                  : 'Tap peta untuk menentukan lokasi',
              style: TextStyle(fontSize: 12, color: _pickedLocation != null ? _primary : Colors.grey[600]),
            ),
            if (_pickedLocation != null) ...[
              const Spacer(),
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
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12,
                onTap: (tapPos, latLng) {
                  setState(() => _pickedLocation = latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.nyeni_app',
                ),
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
              ],
            ),
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
                  _existingImageUrl!,
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
