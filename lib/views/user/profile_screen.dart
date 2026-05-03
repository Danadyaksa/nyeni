import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../controllers/auth_controller.dart';
import '../../config/api_config.dart';
import '../../controllers/biometric_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/ticket_controller.dart';
import '../../services/notification_service.dart';
import 'login_screen.dart';
import 'ticket_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authController = AuthController();
  final _biometricController = BiometricController();
  final _profileController = ProfileController();
  final _ticketController = TicketController();
  late TabController _tabController;

  Map<String, dynamic>? _userData;
  List<dynamic> _tickets = [];
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
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user_data');

      if (userString != null) {
        final localUser = jsonDecode(userString);
        final freshUser = await _profileController.getUserProfile(localUser['id']);
        
        if (freshUser != null) {
          final tickets = await _ticketController.getMyTickets(freshUser.id);

          // Cek apakah ada tiket yang baru berubah dari PENDING → ACTIVE
          await _checkNewlyActivatedTickets(tickets.map((t) => {
            'id': t.id,
            'status': t.status,
            'transaction_id': t.transactionId,
            'event_name': t.eventName,
          }).toList(), prefs);

          if (mounted) {
            setState(() {
              _userData = freshUser.toJson();
              _tickets = tickets.map((t) => {
                'id': t.id,
                'user_id': t.userId,
                'event_name': t.eventName,
                'event_date': t.eventDate,
                'status': t.status,
                'transaction_id': t.transactionId,
                'image_url': t.imageUrl,
              }).toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error load profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Cek tiket yang baru di-acc admin sejak terakhir kali user buka app.
  /// Flag "sudah dinotifikasi" disimpan di Hive (bukan SharedPreferences)
  /// supaya tidak hilang saat logout.
  Future<void> _checkNewlyActivatedTickets(
      List<dynamic> freshTickets, SharedPreferences prefs) async {
    try {
      // Gunakan Hive box 'nyeni_box' untuk menyimpan flag notifikasi
      // sehingga tidak ikut terhapus saat logout (SharedPreferences.clear)
      final box = Hive.box('nyeni_box');

      final List<String> nowActive = freshTickets
          .where((t) => t['status'] == 'ACTIVE')
          .map((t) => t['id'].toString())
          .toList();

      // Daftar tiket aktif yang sudah pernah dinotifikasi (disimpan di Hive)
      final List<dynamic> rawKnown = box.get('known_active_tickets', defaultValue: []);
      final List<String> knownActive = rawKnown.map((e) => e.toString()).toList();

      // Tiket yang baru aktif = ada di nowActive tapi belum di knownActive
      final newlyActivated = nowActive
          .where((id) => !knownActive.contains(id))
          .toList();

      for (final ticketId in newlyActivated) {
        final ticket = freshTickets.firstWhere(
          (t) => t['id'].toString() == ticketId,
          orElse: () => null,
        );
        if (ticket == null) continue;

        // Hitung berapa tiket dalam transaksi yang sama
        final txId = ticket['transaction_id']?.toString();
        int count = 1;
        if (txId != null && txId.isNotEmpty) {
          count = freshTickets
              .where((t) =>
                  t['transaction_id']?.toString() == txId &&
                  t['status'] == 'ACTIVE')
              .length;
        }

        // Kirim notifikasi hanya 1x per transaksi — flag di Hive
        final notifKey = 'notif_sent_${txId ?? ticketId}';
        final alreadySent = box.get(notifKey, defaultValue: false) as bool;
        if (!alreadySent) {
          await NotificationService().notifyPaymentAccepted(
            eventName: ticket['event_name']?.toString() ?? 'Event',
            ticketCount: count,
          );
          await box.put(notifKey, true);
        }
      }

      // Update daftar tiket aktif yang sudah diketahui — simpan di Hive
      await box.put('known_active_tickets', nowActive);
    } catch (e) {
      debugPrint('Error check newly activated: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);
      final file = File(pickedFile.path);

      final success = await _profileController.uploadAvatar(_userData!['id'].toString(), file);
      
      if (success) {
        await _fetchUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto profil berhasil diperbarui!')));
        }
      }
    } catch (e) {
      debugPrint('Error upload image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ─── SETTINGS MODAL ──────────────────────────────────────────────────────────

  void _showSettingsModal() async {
    // Cek biometric availability
    final biometricAvailable = await _biometricController.isBiometricAvailable();
    final userId = _userData?['id']?.toString();
    final biometricEnabled = userId != null ? await _biometricController.isBiometricEnabled(userId) : false;
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Pengaturan Akun",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(LucideIcons.user),
                  title: const Text("Ganti Nama"),
                  onTap: () {
                    Navigator.pop(context);
                    _editNameDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.mail),
                  title: const Text("Ganti Email"),
                  onTap: () {
                    Navigator.pop(context);
                    _editEmailDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.lock),
                  title: const Text("Ganti Password"),
                  onTap: () {
                    Navigator.pop(context);
                    _editPasswordDialog();
                  },
                ),
                
                // ── Biometric Toggle (jika device support) ──
                if (biometricAvailable && userId != null) ...[
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(LucideIcons.fingerprint),
                    title: const Text("Login Biometric"),
                    subtitle: const Text("Gunakan sidik jari atau face ID"),
                    value: biometricEnabled,
                    activeColor: const Color(0xFF2C3E50),
                    onChanged: (bool value) async {
                      if (value) {
                        // Enable biometric - simpan credentials
                        final email = _userData?['email']?.toString() ?? '';
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _showEnableBiometricDialog(userId, email);
                        }
                      } else {
                        // Disable biometric - hapus credentials user ini saja
                        await _biometricController.clearBiometricCredentials(userId);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login biometric dinonaktifkan'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ],
                
                const Divider(),
                ListTile(
                  leading: const Icon(LucideIcons.logOut, color: Colors.red),
                  title: const Text("Keluar",
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _authController.logout();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── DIALOG ENABLE BIOMETRIC ──────────────────────────────────────────────────
  
  void _showEnableBiometricDialog(String userId, String email) {
    final _formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    bool isObscure = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(LucideIcons.fingerprint, color: Color(0xFF2C3E50), size: 20),
                SizedBox(width: 8),
                Text("Aktifkan Login Biometric", style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan password Anda untuk mengaktifkan login biometric',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscure ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () => setStateDialog(() => isObscure = !isObscure),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  
                  // Verifikasi password TANPA update session
                  final verified = await _authController.verifyPassword(email, passwordController.text.trim());
                  
                  if (verified) {
                    // Password benar, simpan credentials
                    await _biometricController.setBiometricEnabled(userId, true);
                    await _biometricController.saveBiometricCredentials(userId, email, passwordController.text.trim());
                    await _biometricController.setLastBiometricUserId(userId);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Login biometric berhasil diaktifkan! 🎉'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password salah, gagal mengaktifkan biometric'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                  
                  if (mounted) setState(() => _isLoading = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Aktifkan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── DIALOG GANTI NAMA ────────────────────────────────────────────────────────

  Future<void> _editNameDialog() async {
    TextEditingController nameController =
        TextEditingController(text: _userData?['full_name'] ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Nama"),
        content: TextField(
            controller: nameController,
            decoration:
                const InputDecoration(hintText: "Masukkan nama baru")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final success = await _profileController.updateName(
                  _userData!['id'].toString(),
                  nameController.text.trim(),
                );
                if (success) {
                  await _fetchUserData();
                }
              } catch (e) {
                debugPrint("Error Update Name: $e");
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E50)),
            child: const Text("Simpan",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── DIALOG GANTI EMAIL ───────────────────────────────────────────────────────

  Future<void> _editEmailDialog() async {
    final _formKey = GlobalKey<FormState>();
    final currentEmail = _userData?['email']?.toString() ?? '';
    TextEditingController emailController = TextEditingController(text: currentEmail);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.mail, color: Color(0xFF2C3E50), size: 20),
            SizedBox(width: 8),
            Text("Ganti Email", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email saat ini: $currentEmail',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Masukkan email baru dengan format yang valid',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "contoh@gmail.com",
                  prefixIcon: const Icon(LucideIcons.mail, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email wajib diisi';
                  }
                  // Validasi format email
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
                    return 'Format email tidak valid';
                  }
                  // Validasi email tidak boleh sama dengan email saat ini
                  if (v.trim().toLowerCase() == currentEmail.toLowerCase()) {
                    return 'Email baru tidak boleh sama dengan email lama';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                final result = await _profileController.updateEmail(
                  _userData!['id'].toString(),
                  emailController.text.trim(),
                );
                
                if (result['error'] == null) {
                  await _fetchUserData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email berhasil diubah!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error'] ?? 'Gagal mengubah email'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint("Error Update Email: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Koneksi server gagal'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── DIALOG GANTI PASSWORD ────────────────────────────────────────────────────

  Future<void> _editPasswordDialog() async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController passController = TextEditingController();
    TextEditingController confirmPassController = TextEditingController();
    bool isObscurePass = true;
    bool isObscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(LucideIcons.lock, color: Color(0xFF2C3E50), size: 20),
                SizedBox(width: 8),
                Text("Ganti Password", style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passController,
                    obscureText: isObscurePass,
                    decoration: InputDecoration(
                      hintText: "Password Baru (min. 6 karakter)",
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscurePass ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () => setStateDialog(() => isObscurePass = !isObscurePass),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      if (v.length < 6) return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: isObscureConfirm,
                    decoration: InputDecoration(
                      hintText: "Ulangi Password Baru",
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () => setStateDialog(() => isObscureConfirm = !isObscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                      if (v != passController.text) return 'Password tidak cocok';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  
                  try {
                    final result = await _profileController.updatePassword(
                      _userData!['id'].toString(),
                      passController.text.trim(),
                    );
                    
                    if (result['error'] == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password berhasil diubah!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['error'] ?? 'Gagal mengubah password'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint("Error Update Password: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Koneksi server gagal'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Color _getAvatarBorderColor(int level) {
    if (level < 5) return Colors.brown.shade400;
    if (level < 10) return Colors.blueGrey.shade300;
    return Colors.amber.shade500;
  }

  // ─── TICKET LIST ─────────────────────────────────────────────────────────────

  Widget _buildTicketList(String statusFilter) {
    final filteredTickets =
        _tickets.where((t) => t['status'] == statusFilter).toList();

    if (filteredTickets.isEmpty) {
      return Center(
          child: Text("Kaga ada tiket $statusFilter nih pak",
              style: const TextStyle(color: Colors.grey)));
    }

    // Normalisasi URL localhost → IP server yang dipakai app
    final String serverHost = ProfileController.baseUrl.replaceAll('/api', '');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTickets.length,
      itemBuilder: (context, index) {
        final ticket = filteredTickets[index];

        // ── Resolve gambar tiket dari JOIN events ──
        String? rawImage = ticket['image_url']?.toString();
        String ticketImage;
        if (rawImage != null && rawImage.isNotEmpty) {
          ticketImage = rawImage
              .replaceAll('http://localhost:3000', serverHost)
              .replaceAll('http://10.0.2.2:3000', serverHost);
        } else {
          // Fallback kalau JOIN gagal / event tidak ditemukan
          ticketImage =
              'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?q=80&w=400&auto=format&fit=crop';
        }

        // ── Badge status ──
        Widget statusBadge;
        switch (statusFilter) {
          case 'PENDING':
            statusBadge = _buildBadge("Menunggu Verifikasi", Colors.orange);
            break;
          case 'ACTIVE':
            statusBadge = _buildBadge("Tiket Aktif", Colors.green);
            break;
          default:
            // USED / EXPIRED / DECLINED → tab Riwayat
            statusBadge =
                _buildBadge("Kadaluarsa / Selesai", Colors.red);
        }

        return InkWell(
          onTap: () {
            if (statusFilter == 'ACTIVE') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketDetailScreen(
                    qrData: ticket['id'].toString(),
                    eventName: ticket['event_name'],
                    imageUrl: ticketImage,
                  ),
                ),
              );
            } else if (statusFilter == 'PENDING') {
              _showPendingDetails(ticket);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03), blurRadius: 10)
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ApiConfig.normalizeImageUrl(ticketImage),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(LucideIcons.imageOff)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket['event_name'] ?? 'Nama Acara',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(ticket['event_date'] ?? 'Tanggal',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      statusBadge,
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showPendingDetails(dynamic ticket) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
                child: Icon(LucideIcons.clock, color: Colors.orange, size: 50)),
            const SizedBox(height: 16),
            const Center(
                child: Text("Detail Pembayaran",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 24),
            _buildDetailRow("Acara", ticket['event_name']),
            _buildDetailRow("Tanggal", ticket['event_date']),
            _buildDetailRow("Status", "Menunggu Verifikasi Admin"),
            _buildDetailRow("Metode Pembayaran", "QRIS / Transfer Virtual"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("Tutup",
                    style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    int totalXp = _userData?['total_xp'] ?? 0;
    int currentLevel = _userData?['level'] ?? 1;

    int xpTarget;
    if (currentLevel >= 10) {
      xpTarget = 2700;
    } else {
      List<int> thresholds = [100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700];
      xpTarget = thresholds[currentLevel - 1];
    }

    double progress = (totalXp / xpTarget).clamp(0.0, 1.0);
    Color borderColor = _getAvatarBorderColor(currentLevel);

    // Normalisasi URL avatar localhost → IP server
    String? avatarUrl = _userData?['avatar_url'];
    if (avatarUrl != null) {
      final String serverHost = ProfileController.baseUrl.replaceAll('/api', '');
      avatarUrl = avatarUrl
          .replaceAll('http://localhost:3000', serverHost)
          .replaceAll('http://10.0.2.2:3000', serverHost);
    }

    return FocusDetector(
      onFocusGained: _fetchUserData,
      child: _isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              backgroundColor: const Color(0xFFFBFBFB),
              appBar: AppBar(
                title: const Text("Profil Saya",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.white,
              ),
              body: Column(
                children: [
                  // ── Header profil ──
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  borderColor.withOpacity(0.5),
                                  borderColor
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                      color: borderColor.withOpacity(0.4),
                                      blurRadius: 8)
                                ],
                              ),
                              child: ClipOval(
                                child: _isUploadingImage
                                    ? Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Center(
                                            child:
                                                CircularProgressIndicator()))
                                    : (avatarUrl != null &&
                                            avatarUrl.isNotEmpty
                                        ? Image.network(
                                            ApiConfig.normalizeImageUrl(avatarUrl),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                        LucideIcons.user,
                                                        size: 40,
                                                        color: Colors.grey)),
                                          )
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[200],
                                            child: const Icon(LucideIcons.user,
                                                size: 40,
                                                color: Colors.grey))),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFF2C3E50),
                                    child: Icon(LucideIcons.camera,
                                        size: 14, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // Info nama + XP
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                        _userData?['full_name'] ?? 'User',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  // Tombol settings (ganti nama/email/password/logout)
                                  IconButton(
                                    icon: const Icon(LucideIcons.settings,
                                        size: 18),
                                    onPressed: _showSettingsModal,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Level $currentLevel',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: borderColor,
                                          fontSize: 12)),
                                  Text("$totalXp / $xpTarget XP",
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      borderColor),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  currentLevel >= 10
                                      ? "Level Maksimal!"
                                      : "${xpTarget - totalXp} XP lagi buat naik level",
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Tab bar ──
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF2C3E50),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF2C3E50),
                      tabs: const [
                        Tab(text: "Pending"),
                        Tab(text: "Aktif"),
                        Tab(text: "Riwayat"),
                      ],
                    ),
                  ),

                  // ── Tab content ──
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTicketList('PENDING'),
                        _buildTicketList('ACTIVE'),
                        // Riwayat: tampilkan USED, EXPIRED, dan DECLINED
                        _buildHistoryList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  /// Tab Riwayat — gabungkan USED + EXPIRED + DECLINED dalam satu list
  Widget _buildHistoryList() {
    final historyTickets = _tickets
        .where((t) =>
            t['status'] == 'USED' ||
            t['status'] == 'EXPIRED' ||
            t['status'] == 'DECLINED')
        .toList();

    if (historyTickets.isEmpty) {
      return const Center(
          child: Text("Belum ada riwayat tiket",
              style: TextStyle(color: Colors.grey)));
    }

    final String serverHost = ProfileController.baseUrl.replaceAll('/api', '');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyTickets.length,
      itemBuilder: (context, index) {
        final ticket = historyTickets[index];
        final status = ticket['status']?.toString() ?? '';

        String? rawImage = ticket['image_url']?.toString();
        String ticketImage = (rawImage != null && rawImage.isNotEmpty)
            ? rawImage
                .replaceAll('http://localhost:3000', serverHost)
                .replaceAll('http://10.0.2.2:3000', serverHost)
            : 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?q=80&w=400&auto=format&fit=crop';

        Color badgeColor;
        String badgeLabel;
        if (status == 'DECLINED') {
          badgeColor = Colors.red;
          badgeLabel = 'Ditolak Admin';
        } else {
          badgeColor = Colors.grey;
          badgeLabel = 'Kadaluarsa / Selesai';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03), blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiConfig.normalizeImageUrl(ticketImage),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(LucideIcons.imageOff)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket['event_name'] ?? 'Nama Acara',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(ticket['event_date'] ?? 'Tanggal',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    _buildBadge(badgeLabel, badgeColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
