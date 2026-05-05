import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFFAF5EE),
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.libreBaskerville(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF9A3412),
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFFAFAF9),
        centerTitle: true,
        elevation: 0,
        shadowColor: const Color(0xFFE7E5E4).withOpacity(0.5),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF78716C), size: 20),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Color(0xFF78716C), size: 20),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9A3412)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3A302A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

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
                        color: const Color(0xFF9A3412),
                        urgent: _pendingCount > 0,
                      ),
                      _buildStatCard(
                        icon: LucideIcons.ticket,
                        label: 'Tiket Aktif',
                        value: '$_activeCount',
                        color: const Color(0xFF9A3412),
                      ),
                      _buildStatCard(
                        icon: LucideIcons.calendarDays,
                        label: 'Total Event',
                        value: '$_totalEvents',
                        color: const Color(0xFF9A3412),
                      ),
                      _buildStatCard(
                        icon: LucideIcons.trendingUp,
                        label: 'Revenue Bersih',
                        value: _formatCurrency(_totalRevenue),
                        color: const Color(0xFF9A3412),
                        smallText: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Text(
                    'Menu Admin',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3A302A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu items
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD8D0C8).withOpacity(0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3A302A).withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuCard(
                            icon: LucideIcons.clipboardCheck,
                            title: 'Verifikasi Pembayaran',
                            subtitle: '$_pendingCount tiket menunggu konfirmasi',
                            color: const Color(0xFF9A3412),
                            badge: _pendingCount > 0 ? '$_pendingCount' : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminPaymentScreen()),
                            ).then((_) => _loadStats()),
                            isFirst: true,
                          ),
                          _buildMenuCard(
                            icon: LucideIcons.calendarPlus,
                            title: 'Kelola Event',
                            subtitle: 'Tambah, edit, dan hapus pertunjukan & pameran',
                            color: const Color(0xFF9A3412),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminEventsScreen()),
                            ).then((_) => _loadStats()),
                          ),
                          _buildMenuCard(
                            icon: LucideIcons.scanLine,
                            title: 'Scan QR Tiket',
                            subtitle: 'Scan QR code untuk validasi tiket masuk',
                            color: const Color(0xFF9A3412),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminScannerScreen()),
                            ),
                          ),
                          _buildMenuCard(
                            icon: LucideIcons.barChart3,
                            title: 'Laporan Revenue',
                            subtitle: 'Lihat pendapatan dari setiap penjualan tiket',
                            color: const Color(0xFF9A3412),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminRevenueScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgent 
              ? const Color(0xFFEF4444) // Red border kalau urgent
              : const Color(0xFFD8D0C8).withOpacity(0.6),
          width: urgent ? 2 : 1, // Border lebih tebal kalau urgent
        ),
        boxShadow: [
          BoxShadow(
            color: urgent
                ? const Color(0xFFEF4444).withOpacity(0.15) // Red glow kalau urgent
                : const Color(0xFF3A302A).withOpacity(0.04),
            blurRadius: urgent ? 12 : 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: urgent 
                        ? const Color(0xFFEF4444) // Red text kalau urgent
                        : const Color(0xFF605850),
                    letterSpacing: 0.2,
                    fontWeight: urgent ? FontWeight.w600 : FontWeight.w400,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon, 
                color: urgent ? const Color(0xFFEF4444) : color, 
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.ebGaramond(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: urgent 
                  ? const Color(0xFFEF4444) // Red value kalau urgent
                  : const Color(0xFF3A302A),
              height: 1.1,
            ),
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
    bool isFirst = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: isFirst ? null : Border(
            top: BorderSide(
              color: const Color(0xFFD8D0C8).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFEAE2DA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF605850), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3A302A),
                  height: 1.4,
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Color(0xFF78716C),
              size: 16,
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Keluar',
          style: GoogleFonts.ebGaramond(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: const Color(0xFF3A302A),
          ),
        ),
        content: Text(
          'Yakin mau keluar dari panel admin?',
          style: GoogleFonts.manrope(
            color: const Color(0xFF605850),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.manrope(
                color: const Color(0xFF78716C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A3412),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
