import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import 'admin_payment_screen.dart';
import 'admin_events_screen.dart';
import 'admin_scanner_screen.dart';
import 'admin_revenue_screen.dart';
import '../user/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminController = AdminController();

  int _pendingCount = 0;
  int _activeCount = 0;
  int _totalEvents = 0;
  int _totalRevenue = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      // Load revenue data yang sudah include semua statistik tiket
      final revenueData = await _adminController.getRevenue();
      
      // Load total events
      final events = await _adminController.getAllEventsAdmin();

      setState(() {
        // Ambil dari revenueData yang menghitung semua tiket individual
        _pendingCount = revenueData['pending_count'] ?? 0;
        _activeCount = revenueData['active_count'] ?? 0;
        _totalEvents = events.length;
        _totalRevenue = revenueData['total_revenue'] ?? 0;
      });
    } catch (e) {
      debugPrint("Error load stats: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthController().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C3E50),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.white),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50)))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: const Color(0xFF2C3E50),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header greeting
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C3E50), Color(0xFF3D5166)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Selamat Datang, Admin!',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Kelola semua aktivitas Nyeni di sini.',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('Ringkasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          icon: LucideIcons.clock,
                          label: 'Menunggu Verifikasi',
                          value: '$_pendingCount',
                          color: Colors.orange,
                          urgent: _pendingCount > 0,
                        ),
                        _buildStatCard(
                          icon: LucideIcons.ticket,
                          label: 'Tiket Aktif',
                          value: '$_activeCount',
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          icon: LucideIcons.calendarDays,
                          label: 'Total Event',
                          value: '$_totalEvents',
                          color: const Color(0xFF2C3E50),
                        ),
                        _buildStatCard(
                          icon: LucideIcons.trendingUp,
                          label: 'Total Revenue',
                          value: _formatCurrency(_totalRevenue),
                          color: Colors.teal,
                          smallText: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Text('Menu Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Menu items
                    _buildMenuCard(
                      icon: LucideIcons.clipboardCheck,
                      title: 'Verifikasi Pembayaran',
                      subtitle: '$_pendingCount tiket menunggu konfirmasi',
                      color: Colors.orange,
                      badge: _pendingCount > 0 ? '$_pendingCount' : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminPaymentScreen()),
                      ).then((_) => _loadStats()),
                    ),

                    _buildMenuCard(
                      icon: LucideIcons.calendarPlus,
                      title: 'Kelola Event',
                      subtitle: 'Tambah, edit, dan hapus pertunjukan & pameran',
                      color: const Color(0xFF2C3E50),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminEventsScreen()),
                      ).then((_) => _loadStats()),
                    ),

                    _buildMenuCard(
                      icon: LucideIcons.scanLine,
                      title: 'Scan QR Tiket',
                      subtitle: 'Scan QR code untuk validasi tiket masuk',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminScannerScreen()),
                      ),
                    ),

                    _buildMenuCard(
                      icon: LucideIcons.barChart3,
                      title: 'Laporan Revenue',
                      subtitle: 'Lihat pendapatan dari setiap penjualan tiket',
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminRevenueScreen()),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool urgent = false,
    bool smallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: urgent ? Border.all(color: Colors.orange, width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (urgent)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: smallText ? 14 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            else
              const Icon(LucideIcons.chevronRight, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp $amount';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin mau keluar dari panel admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
