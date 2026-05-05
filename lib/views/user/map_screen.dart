import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/event_controller.dart';
import '../../utils/price_helper.dart';
import 'event_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final _eventController = EventController();

  List<dynamic> _events = [];
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  String? _locationError;

  static const LatLng _defaultCenter = LatLng(-7.7956, 110.3695); // Yogyakarta
  int? _selectedEventId;
  double _radiusKm = 5.0; // bisa diubah user

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _getUserLocation();
  }

  // ─── Load events dari server ──────────────────────────────────────────────

  Future<void> _loadEvents() async {
    final events = await _eventController.getAllEvents();
    if (mounted) {
      setState(() {
        // Convert Event models to Map and filter only events with coordinates
        _events = events
            .where((e) => e.latitude != null && e.longitude != null)
            .map((e) => {
              'id': e.id,
              'title': e.name,
              'category': e.category,
              'event_date': e.date,
              'location': e.location,
              'price': e.price,
              'image_url': e.imageUrl ?? '',
              'latitude': e.latitude,
              'longitude': e.longitude,
              'early_bird_price': e.earlyBirdPrice,
              'early_bird_start': e.earlyBirdStart,
              'early_bird_end': e.earlyBirdEnd,
            })
            .toList();
      });
    }
  }

  // ─── Ambil lokasi user ────────────────────────────────────────────────────

  Future<void> _getUserLocation() async {
    setState(() { _isLoadingLocation = true; _locationError = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'GPS tidak aktif. Nyalakan lokasi di pengaturan.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Izin lokasi ditolak.';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Izin lokasi ditolak permanen. Buka pengaturan app.';
          _isLoadingLocation = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _isLoadingLocation = false;
        });
        // Pindahkan peta ke lokasi user
        _mapController.move(_userLocation!, 13.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Gagal mendapatkan lokasi: $e';
          _isLoadingLocation = false;
        });
      }
    }
  }

  // ─── Hitung jarak (Haversine formula) ────────────────────────────────────

  double _distanceKm(LatLng a, LatLng b) {
    const r = 6371.0; // radius bumi km
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinDLat = sin(dLat / 2);
    final sinDLon = sin(dLon / 2);
    final x = sinDLat * sinDLat +
        cos(_toRad(a.latitude)) * cos(_toRad(b.latitude)) * sinDLon * sinDLon;
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }

  double _toRad(double deg) => deg * pi / 180;

  // ─── Event terdekat (dalam radius 5 km, sorted) ───────────────────────────

  List<Map<String, dynamic>> get _nearbyEvents {
    if (_userLocation == null) return [];
    final List<Map<String, dynamic>> result = [];
    for (final e in _events) {
      final lat = double.tryParse(e['latitude'].toString());
      final lng = double.tryParse(e['longitude'].toString());
      if (lat == null || lng == null) continue;
      final dist = _distanceKm(_userLocation!, LatLng(lat, lng));
      if (dist <= _radiusKm) {
        result.add({...Map<String, dynamic>.from(e), '_dist': dist});
      }
    }
    result.sort((a, b) => (a['_dist'] as double).compareTo(b['_dist'] as double));
    return result;
  }

  // ─── Format jarak ─────────────────────────────────────────────────────────

  String _fmtDist(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  // ─── Tentukan harga yang ditampilkan (early bird atau reguler) ───────────

  Map<String, dynamic> _getEventPrice(Map<String, dynamic> event) {
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
      } catch (e) {
        // Error parsing dates, skip early bird
      }
    }

    final displayPrice = isEarlyBirdActive ? ebPriceInt : regularPrice;
    final label = isEarlyBirdActive ? 'Early Bird' : 'Reguler';

    return {
      'price': displayPrice,
      'label': label,
      'isEarlyBird': isEarlyBirdActive,
    };
  }

  // ─── Bottom sheet setting radius ─────────────────────────────────────────

  void _showRadiusSheet() {
    double tempRadius = _radiusKm;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFD8D0C8),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(LucideIcons.circleDot, size: 18, color: Color(0xFF9A3412)),
                    const SizedBox(width: 8),
                    Text('Atur Radius Pencarian',
                        style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF3A302A))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9A3412),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${tempRadius.toStringAsFixed(0)} km',
                        style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Event dalam radius ${tempRadius.toStringAsFixed(0)} km dari lokasimu',
                  style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 12),
                ),
                const SizedBox(height: 16),
                // Slider
                SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor: const Color(0xFF9A3412),
                    inactiveTrackColor: const Color(0xFFD8D0C8),
                    thumbColor: const Color(0xFF9A3412),
                    overlayColor: const Color(0xFF9A3412).withOpacity(0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: tempRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    onChanged: (v) => setSheet(() => tempRadius = v),
                  ),
                ),
                // Label min-max
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 km', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF78706A))),
                      Text('10 km', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF78706A))),
                      Text('25 km', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF78706A))),
                      Text('50 km', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF78706A))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Preset cepat
                Row(
                  children: [5, 10, 15, 25, 50].map((km) {
                    final selected = tempRadius.round() == km;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => tempRadius = km.toDouble()),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF9A3412)
                                : const Color(0xFFEAE2DA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$km km',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : const Color(0xFF78706A),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _radiusKm = tempRadius);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9A3412),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Terapkan',
                        style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearby = _nearbyEvents;
    final center = _userLocation ?? _defaultCenter;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EE),
      body: Stack(
        children: [
          // ── Peta ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              onTap: (_, __) {
                if (_selectedEventId != null) {
                  setState(() => _selectedEventId = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nyeni_app',
              ),

              // Lingkaran radius 5 km dari posisi user
              if (_userLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _userLocation!,
                      radius: _radiusKm * 1000, // meter
                      useRadiusInMeter: true,
                      color: const Color(0xFF9A3412).withOpacity(0.08),
                      borderColor: const Color(0xFF9A3412).withOpacity(0.4),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Marker event — pin tanpa background bulat, tap = popup nama
              MarkerLayer(
                markers: _events.map((e) {
                  final lat = double.tryParse(e['latitude'].toString()) ?? 0;
                  final lng = double.tryParse(e['longitude'].toString()) ?? 0;
                  final isNearby = _userLocation != null &&
                      _distanceKm(_userLocation!, LatLng(lat, lng)) <= _radiusKm;
                  final isSelected = _selectedEventId == e['id'];

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 36,
                    height: 44,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          // Toggle: klik lagi = tutup popup
                          _selectedEventId = isSelected ? null : e['id'] as int;
                        });
                      },
                      child: Icon(
                        LucideIcons.mapPin,
                        color: isSelected
                            ? Colors.blue
                            : isNearby
                                ? Colors.orange
                                : const Color(0xFF2C3E50),
                        size: isSelected ? 38 : 32,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Popup nama event di atas pin yang dipilih
              if (_selectedEventId != null)
                MarkerLayer(
                  markers: _events.where((e) => e['id'] == _selectedEventId).map((e) {
                    final lat = double.tryParse(e['latitude'].toString()) ?? 0;
                    final lng = double.tryParse(e['longitude'].toString()) ?? 0;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 200,
                      height: 80,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(eventId: e['id'] as int),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e['title']?.toString() ?? '-',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: const Color(0xFF3A302A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.externalLink, size: 10, color: Colors.blue),
                                      const SizedBox(width: 3),
                                      Text('Lihat detail',
                                          style: GoogleFonts.manrope(fontSize: 10, color: Colors.blue)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Segitiga kecil di bawah popup
                            CustomPaint(
                              size: const Size(12, 6),
                              painter: _TrianglePainter(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Marker posisi user
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── AppBar custom — 1 bar solid rapi ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF9A3412),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      // Judul
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi Event',
                              style: GoogleFonts.libreBaskerville(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Temukan event di sekitarmu',
                              style: GoogleFonts.manrope(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tombol radius
                      GestureDetector(
                        onTap: _showRadiusSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white30, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.circleDashed,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                '${_radiusKm.toStringAsFixed(0)} km',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Status lokasi
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white30, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _userLocation != null
                                    ? Colors.greenAccent
                                    : _isLoadingLocation
                                        ? Colors.orange
                                        : Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _userLocation != null
                                  ? '${_nearbyEvents.length} event'
                                  : _isLoadingLocation
                                      ? 'Mencari...'
                                      : 'Tidak ada',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Error lokasi ──
          if (_locationError != null)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_locationError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                    GestureDetector(
                      onTap: _getUserLocation,
                      child: const Text('Coba lagi',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Card list event terdekat (bottom sheet) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildNearbySheet(nearby),
          ),

          // ── FAB: kembali ke lokasi user ──
          Positioned(
            bottom: nearby.isEmpty ? 80 : (nearby.length > 2 ? 260 : 180),
            right: 16,
            child: FloatingActionButton(
              heroTag: 'map_location_fab',
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 14.0);
                } else {
                  _getUserLocation();
                }
              },
              backgroundColor: const Color(0xFF9A3412),
              mini: true,
              child: Icon(
                _userLocation != null ? LucideIcons.navigation : LucideIcons.locateFixed,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom sheet event terdekat ──────────────────────────────────────────

  Widget _buildNearbySheet(List<Map<String, dynamic>> nearby) {
    if (_userLocation == null && !_isLoadingLocation) {
      return const SizedBox.shrink();
    }

    if (_isLoadingLocation) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9A3412))),
            const SizedBox(width: 12),
            Text('Mencari lokasi kamu...', style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 13)),
          ],
        ),
      );
    }

    if (nearby.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.mapPin, color: const Color(0xFF78706A), size: 20),
            const SizedBox(width: 12),
            Text(
              'Tidak ada event dalam radius ${_radiusKm.toInt()} km dari lokasimu',
              style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.mapPin, color: Colors.orange, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  '${nearby.length} Event dalam ${_radiusKm.toInt()} km',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF3A302A)),
                ),
              ],
            ),
          ),
          // List event terdekat (max 3 tampil, bisa scroll)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: nearby.length,
              itemBuilder: (context, index) {
                final e = nearby[index];
                final dist = e['_dist'] as double;
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailScreen(eventId: e['id'] as int),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD8D0C8)),
                    ),
                    child: Row(
                      children: [
                        // Nomor urut
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.orange
                                : const Color(0xFF9A3412).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: index == 0 ? Colors.white : const Color(0xFF9A3412),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Info event
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['title']?.toString() ?? '-',
                                style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: const Color(0xFF3A302A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 10, color: Color(0xFF78706A)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      e['location']?.toString() ?? '-',
                                      style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF78706A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Jarak + harga
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _fmtDist(dist),
                                style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
                              ),
                            ),
                            const SizedBox(height: 3),
                            _buildPriceWithBadge(e),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
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
  // ─── Build price with badge ───────────────────────────────────────────────

  Widget _buildPriceWithBadge(Map<String, dynamic> event) {
    final priceInfo = _getEventPrice(event);
    final displayPrice = priceInfo['price'] as int;
    final label = priceInfo['label'] as String;
    final isEarlyBird = priceInfo['isEarlyBird'] as bool;
    final labelColor = isEarlyBird ? Colors.orange : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              PriceHelper.formatNumber(displayPrice),
              style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: const Color(0xFF3A302A),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: labelColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Segitiga kecil di bawah popup ───────────────────────────────────────────
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
