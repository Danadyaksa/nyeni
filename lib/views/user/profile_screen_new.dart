import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/biometric_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/ticket_controller.dart';
import '../../services/notification_service.dart';
import '../widgets/user/profile_header.dart';
import '../widgets/user/ticket_list_tab.dart';
import '../widgets/user/edit_name_dialog.dart';
import '../widgets/user/edit_email_dialog.dart';
import '../widgets/user/edit_password_dialog.dart';
import '../widgets/user/biometric_enable_dialog.dart';
import '../widgets/user/settings_menu_item.dart';
import 'login_screen.dart';

/// Profile Screen - Refactored version
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
  bool _isSavingBiometric = false; // Separate loading for biometric

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _checkNewlyActivatedTickets(
      List<dynamic> freshTickets, SharedPreferences prefs) async {
    try {
      final box = Hive.box('nyeni_box');
      final List<String> nowActive = freshTickets
          .where((t) => t['status'] == 'ACTIVE')
          .map((t) => t['id'].toString())
          .toList();

      final List<dynamic> rawKnown = box.get('known_active_tickets', defaultValue: []);
      final List<String> knownActive = rawKnown.map((e) => e.toString()).toList();

      final newlyActivated = nowActive
          .where((id) => !knownActive.contains(id))
          .toList();

      for (final ticketId in newlyActivated) {
        final ticket = freshTickets.firstWhere(
          (t) => t['id'].toString() == ticketId,
          orElse: () => null,
        );
        if (ticket == null) continue;

        final txId = ticket['transaction_id']?.toString();
        int count = 1;
        if (txId != null && txId.isNotEmpty) {
          count = freshTickets
              .where((t) =>
                  t['transaction_id']?.toString() == txId &&
                  t['status'] == 'ACTIVE')
              .length;
        }

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

      await box.put('known_active_tickets', nowActive);
    } catch (e) {
      debugPrint('Error check newly activated: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final success = await _profileController.uploadAvatar(
        _userData!['id'],
        File(picked.path),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchUserData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isUploadingImage = false);
      }
    } catch (e) {
      debugPrint('Error pick image: $e');
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (_) => EditNameDialog(
        currentName: _userData!['full_name'] ?? '',
        onSave: (newName) async {
          final success = await _profileController.updateName(
            _userData!['id'],
            newName,
          );
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nama berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
            await _fetchUserData();
          }
          return success;
        },
      ),
    );
  }

  void _showEditEmailDialog() {
    showDialog(
      context: context,
      builder: (_) => EditEmailDialog(
        currentEmail: _userData!['email'] ?? '',
        onSave: (newEmail) async {
          final result = await _profileController.updateEmail(
            _userData!['id'],
            newEmail,
          );
          if (!result.containsKey('error') && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
            await _fetchUserData();
          }
          return result;
        },
      ),
    );
  }

  void _showEditPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => EditPasswordDialog(
        onSave: (newPassword) async {
          final result = await _profileController.updatePassword(
            _userData!['id'],
            newPassword,
          );
          if (!result.containsKey('error') && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return result;
        },
      ),
    );
  }

  void _showBiometricEnableDialog(String userId, String email) async {
    print('🔐 Profile: Opening biometric dialog...');
    
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BiometricEnableDialog(
        userId: userId,
        email: email,
        onEnable: (userId, email, password) async {
          print('🔐 Profile: onEnable callback called');
          print('🔐 Profile: Verifying password for email: $email');
          
          try {
            final verified = await _authController.verifyPassword(email, password);
            print('🔐 Profile: Password verification result: $verified');
            return verified;
          } catch (e) {
            print('🔐 Profile: Error verifying password: $e');
            return false;
          }
        },
      ),
    );

    print('🔐 Profile: Dialog closed, password: ${password != null ? "received" : "null"}');

    // If password was verified (dialog returned password string)
    if (password != null && password.isNotEmpty && mounted) {
      print('🔐 Profile: Starting biometric save...');
      setState(() => _isSavingBiometric = true);

      try {
        // Enable biometric
        await _biometricController.setBiometricEnabled(userId, true);
        await _biometricController.saveBiometricCredentials(
          userId,
          email,
          password,
        );
        await _biometricController.setLastBiometricUserId(userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login biometric berhasil diaktifkan! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh UI
          _fetchUserData();
        }
      } catch (e) {
        print('Error enabling biometric: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengaktifkan biometric'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSavingBiometric = false);
      }
    }
  }

  void _showSettingsSheet() async {
    final userId = _userData?['id']?.toString();
    final biometricAvailable = await _biometricController.isBiometricAvailable();
    final biometricEnabled = userId != null 
        ? await _biometricController.isBiometricEnabled(userId)
        : false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pengaturan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            SettingsMenuItem(
              icon: LucideIcons.user,
              title: 'Ganti Nama',
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog();
              },
            ),
            SettingsMenuItem(
              icon: LucideIcons.mail,
              title: 'Ganti Email',
              onTap: () {
                Navigator.pop(context);
                _showEditEmailDialog();
              },
            ),
            SettingsMenuItem(
              icon: LucideIcons.lock,
              title: 'Ganti Password',
              onTap: () {
                Navigator.pop(context);
                _showEditPasswordDialog();
              },
            ),
            if (biometricAvailable && userId != null) ...[
              const Divider(),
              SwitchListTile(
                secondary: const Icon(LucideIcons.fingerprint),
                title: const Text('Login Biometric'),
                subtitle: const Text('Gunakan sidik jari atau face ID'),
                value: biometricEnabled,
                activeColor: const Color(0xFF2C3E50),
                onChanged: (value) async {
                  if (value) {
                    final email = _userData?['email']?.toString() ?? '';
                    Navigator.pop(context);
                    _showBiometricEnableDialog(userId, email);
                  } else {
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
            SettingsMenuItem(
              icon: LucideIcons.logOut,
              title: 'Keluar',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await _authController.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onFocusGained: _fetchUserData,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Profil',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2C3E50),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.settings, color: Colors.white),
              onPressed: _showSettingsSheet,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Tiket Aktif'),
              Tab(text: 'Menunggu'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2C3E50)),
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      // Profile Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ProfileHeader(
                          userData: _userData ?? {},
                          onEditImage: _pickImage,
                          isUploadingImage: _isUploadingImage,
                        ),
                      ),
                      // Tabs
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            TicketListTab(
                                tickets: _tickets, filterStatus: 'active'),
                            TicketListTab(
                                tickets: _tickets, filterStatus: 'pending'),
                            TicketListTab(
                                tickets: _tickets, filterStatus: 'history'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Biometric saving overlay
                  if (_isSavingBiometric)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Color(0xFF2C3E50)),
                                SizedBox(height: 16),
                                Text('Mengaktifkan biometric...',
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
