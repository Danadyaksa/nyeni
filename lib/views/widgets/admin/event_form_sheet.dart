import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../controllers/auth_controller.dart';
import '../../../utils/date_utils.dart';

const Color _primary = Color(0xFF2C3E50);

/// Event Form Bottom Sheet - untuk tambah/edit event
class EventFormSheet extends StatefulWidget {
  final Map<String, dynamic>? event;
  final Future<void> Function(Map<String, dynamic> data) onSaved;

  const EventFormSheet({
    super.key,
    this.event,
    required this.onSaved,
  });

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
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
  LatLng? _currentLocation;
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
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

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
    _priceCtrl.text = (e['price'] ?? '').toString();
    _earlyBirdPriceCtrl.text = (e['early_bird_price'] ?? '').toString();
    _descCtrl.text = e['description']?.toString() ?? '';

    if (_categories.contains(e['category'])) {
      _category = e['category'].toString();
    }

    _eventStartDate = DateUtilsHelper.parseDate(e['event_start_date']);
    _eventEndDate = DateUtilsHelper.parseDate(e['event_end_date']);
    _showEndDate = _eventEndDate != null;

    _regularStart = DateUtilsHelper.parseDate(e['regular_start']);
    _regularEnd = DateUtilsHelper.parseDate(e['regular_end']);
    _earlyBirdStart = DateUtilsHelper.parseDate(e['early_bird_start']);
    _earlyBirdEnd = DateUtilsHelper.parseDate(e['early_bird_end']);

    _existingImageUrl = e['image_url']?.toString();
    _isActive = (e['is_active'] == 1 || e['is_active'] == true);

    _openTime = DateUtilsHelper.parseTime(e['open_time']?.toString());
    _closeTime = DateUtilsHelper.parseTime(e['close_time']?.toString());

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
        return body['image_url']?.toString();
      }
      debugPrint('Upload image failed: ${response.statusCode} — ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Upload image exception: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_eventStartDate == null) {
      final rawDate = widget.event?['event_date']?.toString() ?? '';
      if (rawDate.isNotEmpty) {
        _eventStartDate = DateUtilsHelper.parseDateFromString(rawDate);
      }
      _eventStartDate ??= DateTime.now();
    }

    setState(() => _isSaving = true);

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
        return;
      }
    }

    final eventDate = DateUtilsHelper.buildEventDateString(
      _eventStartDate!,
      _showEndDate ? _eventEndDate : null,
    );

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'category': _category,
      'event_date': eventDate,
      'event_start_date': DateUtilsHelper.formatDateIso(_eventStartDate!),
      'event_end_date': (_showEndDate && _eventEndDate != null) ? DateUtilsHelper.formatDateIso(_eventEndDate!) : null,
      'location': _locationCtrl.text.trim(),
      'latitude': _pickedLocation?.latitude,
      'longitude': _pickedLocation?.longitude,
      'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
      'regular_start': _regularStart != null ? DateUtilsHelper.formatDateIso(_regularStart!) : null,
      'regular_end': _regularEnd != null ? DateUtilsHelper.formatDateIso(_regularEnd!) : null,
      'early_bird_price': _earlyBirdPriceCtrl.text.trim().isNotEmpty
          ? int.tryParse(_earlyBirdPriceCtrl.text.trim())
          : null,
      'early_bird_start': _earlyBirdStart != null ? DateUtilsHelper.formatDateIso(_earlyBirdStart!) : null,
      'early_bird_end': _earlyBirdEnd != null ? DateUtilsHelper.formatDateIso(_earlyBirdEnd!) : null,
      'open_time': DateUtilsHelper.formatTime(_openTime),
      'close_time': DateUtilsHelper.formatTime(_closeTime),
      'image_url': imageUrl ?? '',
      'description': _descCtrl.text.trim(),
      'is_active': _isActive ? 1 : 0,
    };

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
            // Form content will be added here
            Expanded(
              child: Center(
                child: Text('Form content - To be implemented'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
