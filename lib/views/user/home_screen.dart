import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/event_controller.dart';
import '../../services/notification_service.dart';
import '../../config/api_config.dart';
import 'event_detail_screen.dart';
import 'notification_screen.dart';
import 'all_events_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Semua';
  String _userName = "User";
  final List<String> _categories = ['Semua', 'Konser', 'Teater', 'Pameran', 'Stand Up'];
  int _unreadNotifCount = 0;
  final _notifService = NotificationService();
  final _eventController = EventController();

  // Search & filter state
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  double _minPrice = 0;
  double _maxPrice = 500000;
  static const double _absoluteMax = 500000;
  bool _filterActive = false;

  List<dynamic> _allEvents = [];
  List<dynamic> _recommendedEvents = []; // Store shuffled recommendations once
  List<Map<String, dynamic>> _promoBanners = []; // {id, title, image_url}
  bool _isLoading = true;

  late PageController _pageController;
  Timer? _timer;
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchEvents();
    _refreshNotifCount();
    // Jalankan daily checks saat home dibuka
    NotificationService().runDailyChecks();

    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentBannerIndex < _promoBanners.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  void _refreshNotifCount() {
    setState(() {
      _unreadNotifCount = _notifService.getUnreadCount();
    });
  }

  Future<void> _loadUserData() async {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (mounted) {
          setState(() {
            _userName = userData['full_name'] ?? "User"; // Tarik namanya pak!
          });
        }
      }
    }
    
  // Fungsi manggil API dari EventController
  Future<void> _fetchEvents() async {
    final events = await _eventController.getAllEvents();
    if (mounted) {
      // Ambil event yang punya gambar, shuffle, ambil max 5 untuk banner
      final withImage = events
          .where((e) => (e.imageUrl ?? '').isNotEmpty)
          .map((e) => {
                'id': e.id,
                'title': e.name,
                'image_url': e.imageUrl!,
              })
          .toList()
        ..shuffle(Random());

      setState(() {
        // Convert Event models to Map for compatibility with existing UI code
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
        
        // Shuffle recommendations ONCE when data is loaded
        _recommendedEvents = List.from(_allEvents)..shuffle(Random());
        
        _promoBanners = withImage.take(5).cast<Map<String, dynamic>>().toList();
        // Fallback kalau belum ada event bergambar
        if (_promoBanners.isEmpty) {
          _promoBanners = [
            {
              'id': null,
              'title': 'Promo Terbatas! Diskon 50%',
              'image_url': 'https://images.unsplash.com/photo-1540039155733-d7696d4f198f?q=80&w=800&auto=format&fit=crop',
            },
            {
              'id': null,
              'title': 'Event Seni Terbaik di Kotamu',
              'image_url': 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?q=80&w=800&auto=format&fit=crop',
            },
            {
              'id': null,
              'title': 'Jangan Sampai Kehabisan Tiket!',
              'image_url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800&auto=format&fit=crop',
            },
          ];
        }
        _isLoading = false;
      });
    }
  }

  /// Tentukan harga yang ditampilkan di card — early bird atau normal
  Widget _buildEventPrice(Map<String, dynamic> event) {
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
              'Rp ${_fmtPrice(displayPrice)}',
              style: GoogleFonts.ebGaramond(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9A3412),
                  fontSize: 13),
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
                    color: labelColor),
              ),
            ),
          ],
        ),
        // Kalau early bird aktif, tampilkan harga coret normal
        if (isEarlyBirdActive)
          Text(
            'Rp ${_fmtPrice(regularPrice)}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  String _fmtPrice(dynamic price) {
    final p = (price is int) ? price : (double.tryParse(price.toString()) ?? 0).toInt();
    return p.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    double tempMin = _minPrice;
    double tempMax = _maxPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(LucideIcons.slidersHorizontal,
                      size: 18, color: Color(0xFF9A3412)),
                  const SizedBox(width: 8),
                  Text('Filter Event',
                      style: GoogleFonts.ebGaramond(
                          fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF3A302A))),
                  const Spacer(),
                  // Reset filter
                  TextButton(
                    onPressed: () {
                      setSheet(() {
                        tempMin = 0;
                        tempMax = _absoluteMax;
                      });
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Filter Tipe Event ──
              Text('Tipe Event',
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF3A302A))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      setSheet(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF9A3412)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Filter Range Harga ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Range Harga',
                      style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: const Color(0xFF3A302A))),
                  Text(
                    tempMin == 0 && tempMax == _absoluteMax
                        ? 'Semua harga'
                        : '${_fmtPriceShort(tempMin)} – ${_fmtPriceShort(tempMax)}',
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF78706A),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(ctx).copyWith(
                  activeTrackColor: const Color(0xFF9A3412),
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: const Color(0xFF9A3412),
                  overlayColor:
                      const Color(0xFF9A3412).withOpacity(0.1),
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 8),
                  trackHeight: 4,
                ),
                child: RangeSlider(
                  values: RangeValues(tempMin, tempMax),
                  min: 0,
                  max: _absoluteMax,
                  divisions: 20,
                  onChanged: (v) =>
                      setSheet(() {
                        tempMin = v.start;
                        tempMax = v.end;
                      }),
                ),
              ),
              // Label harga
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Gratis',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text('500rb+',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol terapkan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = tempMin;
                      _maxPrice = tempMax;
                      _filterActive =
                          !(tempMin == 0 && tempMax == _absoluteMax);
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A3412),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Terapkan Filter',
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
    );
  }

  String _fmtPriceShort(double price) {
    if (price == 0) return 'Gratis';
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}jt';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}rb';
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    // Logic filter: kategori + search + harga
    List<dynamic> filteredEvents = _allEvents;

    // Filter kategori
    if (_selectedCategory != 'Semua') {
      filteredEvents = filteredEvents
          .where((e) => e['category'] == _selectedCategory)
          .toList();
    }

    // Filter search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredEvents = filteredEvents.where((e) {
        final title = (e['title'] ?? '').toString().toLowerCase();
        final location = (e['location'] ?? '').toString().toLowerCase();
        return title.contains(q) || location.contains(q);
      }).toList();
    }

    // Filter harga
    if (_filterActive) {
      filteredEvents = filteredEvents.where((e) {
        final price = int.tryParse(e['price']?.toString() ?? '0') ?? 0;
        return price >= _minPrice && price <= _maxPrice;
      }).toList();
    }

    final hasActiveFilter = _filterActive ||
        _searchQuery.isNotEmpty ||
        _selectedCategory != 'Semua';

    // For recommendations (when no filter active), show max 4 from pre-shuffled list
    List<dynamic> displayedEvents = filteredEvents;
    if (!hasActiveFilter) {
      // Use pre-shuffled recommendations instead of shuffling every build
      displayedEvents = _recommendedEvents.take(4).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Halo, $_userName",
                  style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 12)),
              Text("Mau Nyeni di mana hari ini?",
                  style: GoogleFonts.ebGaramond(
                      color: const Color(0xFF3A302A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, color: Color(0xFF9A3412)),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                  _refreshNotifCount();
                },
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        // Search bar + filter button di bawah title
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                // Search bar
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Cari event atau lokasi...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(LucideIcons.search,
                            size: 16, color: Colors.grey.shade400),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(LucideIcons.x,
                                    size: 14, color: Colors.grey.shade400),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Tombol filter
                GestureDetector(
                  onTap: () => _showFilterSheet(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _filterActive
                          ? const Color(0xFF9A3412)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          LucideIcons.slidersHorizontal,
                          size: 18,
                          color: _filterActive
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        if (_filterActive)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF9A3412)))
      : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // 1. SLIDING BANNER PROMO
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                itemCount: _promoBanners.length,
                itemBuilder: (context, index) {
                  final banner = _promoBanners[index];
                  final eventId = banner['id'];
                  return GestureDetector(
                    onTap: eventId != null
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(eventId: eventId as int),
                              ),
                            )
                        : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(banner['image_url']!),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                banner['title']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (eventId != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white54),
                                ),
                                child: const Text(
                                  'Lihat →',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _promoBanners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentBannerIndex == index ? 24 : 8,
                  decoration: BoxDecoration(color: _currentBannerIndex == index ? const Color(0xFF9A3412) : Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. KATEGORI FILTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Kategori Acara", style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3A302A))),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF9A3412) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF9A3412) : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(cat, style: GoogleFonts.manrope(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 3. GRID 2 KOLOM EVENT DARI DATABASE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasActiveFilter
                        ? '${filteredEvents.length} hasil ditemukan'
                        : _selectedCategory == 'Semua'
                            ? "Rekomendasi Nyeni"
                            : "Kategori: $_selectedCategory",
                    style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A302A)),
                  ),
                  if (hasActiveFilter)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedCategory = 'Semua';
                          _minPrice = 0;
                          _maxPrice = _absoluteMax;
                          _filterActive = false;
                        });
                      },
                      child: const Text('Reset',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllEventsScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Lihat Semua",
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF9A3412),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            if (filteredEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.searchX, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        hasActiveFilter
                            ? 'Tidak ada event yang cocok\ndengan filter kamu'
                            : 'Belum ada event nih',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), 
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72, 
                ),
                itemCount: displayedEvents.length,
                itemBuilder: (context, index) {
                  final event = displayedEvents[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventId: event['id'])));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                ApiConfig.normalizeImageUrl(event['image_url']), // Pastiin key ini sama kaya di database MySQL lu
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Center(child: Icon(LucideIcons.imageOff))),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text(event['category'], style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 6),
                                Text(event['title'], style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3A302A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 10, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(event['event_date'], style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis,),
                                  ],
                                ),
                                const SizedBox(height: 8),
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
              
            // 4. EVENT TERBARU SECTION
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Event Terbaru",
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A302A),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Horizontal scrollable list of latest events
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _allEvents.length > 5 ? 5 : _allEvents.length,
                itemBuilder: (context, index) {
                  // Sort by created_at if available, otherwise show first 5
                  final latestEvents = List.from(_allEvents);
                  // Reverse to show newest first (assuming newer events have higher IDs)
                  latestEvents.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
                  
                  if (index >= latestEvents.length) return const SizedBox();
                  final event = latestEvents[index];
                  
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
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                Text(
                                  'Rp ${_fmtPrice(event['price'])}',
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
                },
              ),
            ),
            
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }
}