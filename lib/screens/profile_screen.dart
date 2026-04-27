import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  late TabController _tabController;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase.from('users').select().eq('id', user.id).single();
        setState(() { _userData = data; _isLoading = false; });
      }
    } catch (e) {
      debugPrint("Error load profile: $e");
      setState(() => _isLoading = false);
    }
  }

  // LOGIKA UPLOAD FOTO PROFIL (PERLU BUCKET 'avatars' DI SUPABASE)
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final user = _supabase.auth.currentUser;
      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      final fileName = '${user!.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload ke bucket Supabase bernama 'avatars'
      // Pastikan kamu sudah membuat bucket 'avatars' di menu Storage Supabase
      await _supabase.storage.from('avatars').upload(fileName, file);
      
      // Ambil Public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // Simpan URL ke tabel users
      await _supabase.from('users').update({'avatar_url': imageUrl}).eq('id', user.id);

      _fetchUserData(); // Refresh data
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui!'), backgroundColor: Colors.green));
    } catch (e) {
      debugPrint('Error upload image: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui foto profil. Pastikan bucket "avatars" ada di Supabase.'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // DIALOG EDIT NAMA
  Future<void> _editNameDialog() async {
    TextEditingController nameController = TextEditingController(text: _userData?['full_name'] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Nama"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Masukkan nama baru"),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              await _supabase.from('users').update({'full_name': nameController.text.trim()}).eq('id', _supabase.auth.currentUser!.id);
              _fetchUserData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  // LOGIKA BORDER LEVEL & KALKULASI XP
  Color _getAvatarBorderColor(int level) {
    if (level < 5) return Colors.brown.shade400; // Bronze (Lv 1-4)
    if (level < 10) return Colors.blueGrey.shade300; // Silver (Lv 5-9)
    if (level < 20) return Colors.amber.shade500; // Gold (Lv 10-19)
    return Colors.purpleAccent; // Mythic/Platinum (Lv 20+)
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // AMBIL DATA TOTAL XP DARI SUPABASE
    int totalXp = _userData?['total_xp'] ?? 0;
    
    // LOGIKA LEVELING PROGRESIF (Semakin tinggi level, butuh XP lebih banyak)
    int currentLevel = 1;
    int xpForCurrentLevel = 0;
    int xpForNextLevel = 100; // Default awal

    // Rumus: Lv1(100), Lv2(150), Lv3(200), Lv4(250), Lv5(300), Lv6(350)
    // Akumulasi: Lv1(0), Lv2(100), Lv3(250), Lv4(450), Lv5(700), Lv6(1000)
    if (totalXp >= 2700) { currentLevel = 10; xpForCurrentLevel = 2700; xpForNextLevel = 2700; }
    else if (totalXp >= 2200) { currentLevel = 9; xpForCurrentLevel = 2200; xpForNextLevel = 2700; }
    else if (totalXp >= 1750) { currentLevel = 8; xpForCurrentLevel = 1750; xpForNextLevel = 2200; }
    else if (totalXp >= 1350) { currentLevel = 7; xpForCurrentLevel = 1350; xpForNextLevel = 1750; }
    else if (totalXp >= 1000) { currentLevel = 6; xpForCurrentLevel = 1000; xpForNextLevel = 1350; }
    else if (totalXp >= 700) { currentLevel = 5; xpForCurrentLevel = 700; xpForNextLevel = 1000; }
    else if (totalXp >= 450) { currentLevel = 4; xpForCurrentLevel = 450; xpForNextLevel = 700; }
    else if (totalXp >= 250) { currentLevel = 3; xpForCurrentLevel = 250; xpForNextLevel = 450; }
    else if (totalXp >= 100) { currentLevel = 2; xpForCurrentLevel = 100; xpForNextLevel = 250; }

    int xpInLevelSekarang = totalXp - xpForCurrentLevel;
    int butuhXpKeLevelNext = xpForNextLevel - xpForCurrentLevel;
    double progress = currentLevel == 10 ? 1.0 : (xpInLevelSekarang / butuhXpKeLevelNext);

    String? avatarUrl = _userData?['avatar_url'];
    Color borderColor = _getAvatarBorderColor(currentLevel);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0, backgroundColor: Colors.white),
      body: Column(
        children: [
          // HEADER: FOTO, NAMA, LEVEL & EXP BAR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // FOTO PROFIL DENGAN BORDER
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4), // Ketebalan border
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [borderColor.withOpacity(0.5), borderColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
                      ),
                      child: CircleAvatar(
                        radius: 40, 
                        backgroundColor: Colors.grey[200], 
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null, 
                        child: avatarUrl == null 
                          ? const Icon(LucideIcons.user, size: 40, color: Colors.grey) 
                          : (_isUploadingImage ? const CircularProgressIndicator() : null),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0, 
                      child: GestureDetector(
                        onTap: _pickImage, 
                        child: const CircleAvatar(radius: 14, backgroundColor: Color(0xFF2C3E50), child: Icon(LucideIcons.camera, size: 14, color: Colors.white))
                      )
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                
                // DATA NAMA & LEVEL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(_userData?['full_name'] ?? 'Pemain Nyeni', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.edit3, size: 18, color: Colors.grey),
                            onPressed: _editNameDialog,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Level $currentLevel', style: TextStyle(fontWeight: FontWeight.bold, color: borderColor)),
                          Text('$xpInLevelSekarang / $butuhXpKeLevelNext XP', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // EXP PROGRESS BAR
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(borderColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Kumpulkan ${butuhXpKeLevelNext - xpInLevelSekarang} XP lagi untuk naik level!", style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),                   ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // TAB BAR TIKET
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2C3E50),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2C3E50),
              tabs: const [Tab(text: "Pending"), Tab(text: "Aktif"), Tab(text: "Riwayat")],
            ),
          ),

          // ISI TIKET
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList("Pending", "Menunggu Persetujuan Admin", LucideIcons.clock, Colors.orange),
                _buildTicketList("Aktif", "Tiket siap di-scan (QR)", LucideIcons.qrCode, Colors.green),
                _buildTicketList("Selesai/Expired", "Sudah digunakan atau kadaluwarsa", LucideIcons.checkCircle, Colors.grey),
              ],
            ),
          ),

          // PENGATURAN BAWAH
          Container(
            color: Colors.white,
            child: Column(
              children: [
                const Divider(height: 1),
                ListTile(leading: const Icon(LucideIcons.settings), title: const Text("Pengaturan Akun"), trailing: const Icon(LucideIcons.chevronRight, size: 16)),
                ListTile(
                  leading: const Icon(LucideIcons.logOut, color: Colors.red), 
                  title: const Text("Keluar", style: TextStyle(color: Colors.red)), 
                  onTap: () async { 
                    await _authService.logout(); 
                    if(mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false); 
                  }
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  // WIDGET CARD TIKET
  Widget _buildTicketList(String status, String subtitle, IconData icon, Color color) {
    // TODO: Nanti diganti pakai ListView.builder dari data Supabase tabel 'tickets'
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 1, // Placeholder
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200), 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                const Text("Pameran ARTJOG 2026", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))
              ]
            )
          ),
          const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }
}