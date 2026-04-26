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
  File? _imageFile;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final data = await _supabase.from('users').select().eq('id', user.id).single();
      setState(() { _userData = data; _isLoading = false; });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) { setState(() { _imageFile = File(pickedFile.path); }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0, backgroundColor: Colors.white),
      body: Column(
        children: [
          // HEADER: FOTO & NAMA
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(radius: 45, backgroundColor: Colors.grey[200], backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null, child: _imageFile == null ? const Icon(LucideIcons.user, size: 40) : null),
                    Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickImage, child: const CircleAvatar(radius: 15, backgroundColor: Color(0xFF2C3E50), child: Icon(LucideIcons.camera, size: 15, color: Colors.white)))),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_userData?['full_name'] ?? 'Aksa', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Level ${_userData?['level']} • ${_userData?['total_xp']} XP', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text("Edit Data", style: TextStyle(fontSize: 12))),
                  ]),
                ),
              ],
            ),
          ),

          // TAB BAR TIKET
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2C3E50),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2C3E50),
            tabs: const [Tab(text: "Pending"), Tab(text: "Aktif"), Tab(text: "Selesai")],
          ),

          // ISI TIKET
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList("Pending", LucideIcons.clock, Colors.orange),
                _buildTicketList("Aktif", LucideIcons.ticket, Colors.green),
                _buildTicketList("Selesai", LucideIcons.checkCircle, Colors.blue),
              ],
            ),
          ),

          // PENGATURAN BAWAH
          const Divider(),
          ListTile(leading: const Icon(LucideIcons.fingerprint), title: const Text("Pengaturan Biometrik"), subtitle: const Text("Segera Hadir"), trailing: const Icon(LucideIcons.chevronRight)),
          ListTile(leading: const Icon(LucideIcons.logOut, color: Colors.red), title: const Text("Keluar", style: TextStyle(color: Colors.red)), onTap: () async { await _authService.logout(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false); }),
        ],
      ),
    );
  }

  Widget _buildTicketList(String status, IconData icon, Color color) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 1, // Placeholder
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Pameran ARTJOG 2026", style: TextStyle(fontWeight: FontWeight.bold)), Text("Status: $status", style: TextStyle(color: color, fontSize: 12))])),
          const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }
}