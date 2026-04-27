import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
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

  // AMBIL DATA TERBARU DARI NODE.JS (Termasuk Data XP dari Game)
  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user_data');
      
      if (userString != null) {
        final localUser = jsonDecode(userString);
        
        // 10.0.2.2 adalah localhost-nya Emulator Android
        final response = await http.get(
          Uri.parse("http://10.0.2.2:3000/api/user/${localUser['id']}"),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final freshData = jsonDecode(response.body);
          setState(() {
            _userData = freshData;
          });
          // Update data lokal biar sinkron
          await prefs.setString('user_data', jsonEncode(freshData));
        }
      }
    } catch (e) {
      debugPrint("Error load profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // UPLOAD FOTO KE FOLDER 'uploads/' NODE.JS
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);
      final file = File(pickedFile.path);

      var request = http.MultipartRequest(
        'POST', 
        Uri.parse("http://10.0.2.2:3000/api/user/upload-avatar")
      );
      
      request.fields['id'] = _userData!['id'];
      request.files.add(await http.MultipartFile.fromPath('avatar', file.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        // Tarik ulang profil untuk mendapatkan URL gambar baru
        await _fetchUserData(); 
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui!')));
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal upload gambar. Cek server Node.js')));
      }
    } catch (e) {
      debugPrint('Error upload image: $e');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // EDIT NAMA KE MYSQL
  Future<void> _editNameDialog() async {
    TextEditingController nameController = TextEditingController(text: _userData?['full_name'] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Nama"),
        content: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Masukkan nama baru")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                await http.post(
                  Uri.parse("http://10.0.2.2:3000/api/user/update-name"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({"id": _userData!['id'], "full_name": nameController.text.trim()}),
                );
                // Langsung refresh nama baru
                await _fetchUserData();
              } catch (e) {
                debugPrint("Error Update Name: $e");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  Color _getAvatarBorderColor(int level) {
    if (level < 5) return Colors.brown.shade400;
    if (level < 10) return Colors.blueGrey.shade300;
    return Colors.amber.shade500;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Ambil total_xp (disesuaikan dengan nama kolom database yang baru)
    int totalXp = _userData?['total_xp'] ?? 0;
    
    // Logika Leveling Progresif
    int currentLevel = 1;
    int xpForCurrent = 0;
    int xpForNext = 100;

    if (totalXp >= 2700) { currentLevel = 10; xpForCurrent = 2700; xpForNext = 2700; }
    else if (totalXp >= 2200) { currentLevel = 9; xpForCurrent = 2200; xpForNext = 2700; }
    else if (totalXp >= 1750) { currentLevel = 8; xpForCurrent = 1750; xpForNext = 2200; }
    else if (totalXp >= 1350) { currentLevel = 7; xpForCurrent = 1350; xpForNext = 1750; }
    else if (totalXp >= 1000) { currentLevel = 6; xpForCurrent = 1000; xpForNext = 1350; }
    else if (totalXp >= 700) { currentLevel = 5; xpForCurrent = 700; xpForNext = 1000; }
    else if (totalXp >= 450) { currentLevel = 4; xpForCurrent = 450; xpForNext = 700; }
    else if (totalXp >= 250) { currentLevel = 3; xpForCurrent = 250; xpForNext = 450; }
    else if (totalXp >= 100) { currentLevel = 2; xpForCurrent = 100; xpForNext = 250; }

    double progress = currentLevel == 10 ? 1.0 : (totalXp - xpForCurrent) / (xpForNext - xpForCurrent);
    String? avatarUrl = _userData?['avatar_url'];
    Color borderColor = _getAvatarBorderColor(currentLevel);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)), 
        centerTitle: true, 
        elevation: 0, 
        backgroundColor: Colors.white,
        actions: [
          // TOMBOL REFRESH UNTUK UPDATE XP SETELAH MAIN GAME
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.black),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchUserData();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [borderColor.withOpacity(0.5), borderColor]),
                        boxShadow: [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: 8)]
                      ),
                      child: CircleAvatar(
                        radius: 40, 
                        backgroundColor: Colors.grey[200], 
                        // Konversi URL 'localhost' dari MySQL agar bisa terbaca oleh Emulator Android (10.0.2.2)
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl.replaceFirst('localhost', '10.0.2.2')) : null, 
                        child: avatarUrl == null 
                          ? const Icon(LucideIcons.user, size: 40, color: Colors.grey) 
                          : (_isUploadingImage ? const CircularProgressIndicator() : null),
                      ),
                    ),
                    Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickImage, child: const CircleAvatar(radius: 14, backgroundColor: Color(0xFF2C3E50), child: Icon(LucideIcons.camera, size: 14, color: Colors.white)))),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(_userData?['full_name'] ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          IconButton(icon: const Icon(LucideIcons.edit3, size: 18), onPressed: _editNameDialog, padding: EdgeInsets.zero, constraints: const BoxConstraints())
                        ],
                      ),
                      Text('Level $currentLevel', style: TextStyle(fontWeight: FontWeight.bold, color: borderColor)),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(borderColor))),
                      const SizedBox(height: 4),
                      Text(currentLevel == 10 ? "Maksimal" : "${xpForNext - totalXp} XP lagi untuk naik level", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            child: TabBar(controller: _tabController, labelColor: const Color(0xFF2C3E50), unselectedLabelColor: Colors.grey, indicatorColor: const Color(0xFF2C3E50), tabs: const [Tab(text: "Pending"), Tab(text: "Aktif"), Tab(text: "Riwayat")]),
          ),
          Expanded(child: TabBarView(controller: _tabController, children: [const Center(child: Text("Kosong")), const Center(child: Text("Kosong")), const Center(child: Text("Kosong"))])),
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
    );
  }
}