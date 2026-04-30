import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import 'event_detail_screen.dart'; // Pastiin file ini udah lu bikin ye pak!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Semua';
  String _userName = "User";
  final List<String> _categories = ['Semua', 'Konser', 'Teater', 'Pameran', 'Stand Up'];

  final List<String> _promoBanners = [
    'https://images.unsplash.com/photo-1540039155733-d7696d4f198f?q=80&w=800&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?q=80&w=800&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800&auto=format&fit=crop',
  ];

  List<dynamic> _allEvents = [];
  bool _isLoading = true;

  late PageController _pageController;
  Timer? _timer;
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchEvents(); // Narik data pas layar dibuka
    
    // Settingan banner jalan otomatis
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
    
  // Fungsi manggil API dari AuthService
  Future<void> _fetchEvents() async {
    final events = await AuthService().getAllEvents();
    if (mounted) {
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logic filter kategori
    final filteredEvents = _selectedCategory == 'Semua' 
        ? _allEvents 
        : _allEvents.where((e) => e['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
     appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // CONST DI SINI GUA ILANGIN YE MON!
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Halo, $_userName", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            // Const-nya pindah ke bawah sini aje yang teksnya statis
            const Text("Mau Nyeni di mana hari ini?", style: TextStyle(color: Color(0xFF2C3E50), fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Color(0xFF2C3E50)),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50)))
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
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(image: NetworkImage(_promoBanners[index]), fit: BoxFit.cover),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent]),
                      ),
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      child: const Text("Promo Terbatas! Diskon 50%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  decoration: BoxDecoration(color: _currentBannerIndex == index ? const Color(0xFF2C3E50) : Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. KATEGORI FILTER
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Kategori Acara", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
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
                        color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
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
                  Text(_selectedCategory == 'Semua' ? "Rekomendasi Nyeni" : "Kategori: $_selectedCategory", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const Text("Lihat Semua", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            if (filteredEvents.isEmpty)
              const Padding(padding: EdgeInsets.all(32.0), child: Center(child: Text("Yah acaranye belom ada nih pak!", style: TextStyle(color: Colors.grey))))
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
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
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
                                event['image_url'], // Pastiin key ini sama kaya di database MySQL lu
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
                                Text(event['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 10, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(event['event_date'], style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis,),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text("Rp ${event['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }
}