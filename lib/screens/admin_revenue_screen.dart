import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/admin_service.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  final _adminService = AdminService();

  Map<String, dynamic> _revenueData = {};
  List<dynamic> _allTickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _adminService.getRevenue(),
      _adminService.getAllTickets(),
    ]);
    if (mounted) {
      setState(() {
        _revenueData = results[0] as Map<String, dynamic>;
        _allTickets = results[1] as List<dynamic>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Laporan Revenue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2C3E50),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(LucideIcons.refreshCw, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2C3E50),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total revenue card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C3E50), Color(0xFF3D5166)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.trendingUp, color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrencyFull(_revenueData['total_revenue'] ?? 0),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dari ${_revenueData['total_sold'] ?? 0} tiket terjual',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat(
                          icon: LucideIcons.clock,
                          label: 'Pending',
                          value: '${_revenueData['pending_count'] ?? 0}',
                          color: Colors.orange,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMiniStat(
                          icon: LucideIcons.checkCircle2,
                          label: 'Aktif',
                          value: '${_revenueData['active_count'] ?? 0}',
                          color: Colors.green,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMiniStat(
                          icon: LucideIcons.archive,
                          label: 'Expired',
                          value: '${_revenueData['expired_count'] ?? 0}',
                          color: Colors.grey,
                        )),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Text('Revenue per Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Revenue per event dari server
                    if (_revenueData['per_event'] != null && (_revenueData['per_event'] as List).isNotEmpty) ...[
                      ...(_revenueData['per_event'] as List).map((item) => _buildEventRevenueCard(
                        eventName: item['event_name']?.toString() ?? '-',
                        ticketCount: int.tryParse(item['ticket_count']?.toString() ?? '0') ?? 0,
                        revenue: int.tryParse(item['revenue']?.toString() ?? '0') ?? 0,
                        totalRevenue: int.tryParse(_revenueData['total_revenue']?.toString() ?? '1') ?? 1,
                      )),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('Belum ada data revenue', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    const Text('Riwayat Transaksi Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Recent transactions — pakai data dari server langsung
                    ...(_revenueData['recent_transactions'] != null
                        ? (_revenueData['recent_transactions'] as List).map((ticket) => _buildTransactionRow(ticket))
                        : _allTickets
                            .where((t) => t['status'] == 'ACTIVE' || t['status'] == 'EXPIRED')
                            .take(20)
                            .map((ticket) => _buildTransactionRow(ticket))),

                    if ((_revenueData['recent_transactions'] == null || (_revenueData['recent_transactions'] as List).isEmpty) &&
                        _allTickets.where((t) => t['status'] == 'ACTIVE' || t['status'] == 'EXPIRED').isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey))),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEventRevenueCard({
    required String eventName,
    required int ticketCount,
    required int revenue,
    required int totalRevenue,
  }) {
    final double percent = totalRevenue > 0 ? (revenue / totalRevenue).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(eventName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                _formatCurrencyFull(revenue),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.ticket, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text('$ticketCount tiket terjual', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              Text('${(percent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2C3E50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(dynamic ticket) {
    final serviceFee = int.tryParse(ticket['service_fee']?.toString() ?? '2500') ?? 2500;
    final totalAmount = int.tryParse(ticket['total_amount']?.toString() ?? '0') ?? 0;
    final uniqueCode = int.tryParse(ticket['unique_code']?.toString() ?? '0') ?? 0;
    final createdAt = ticket['created_at'] != null ? _formatDate(ticket['created_at'].toString()) : '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.ticket, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket['event_name']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(ticket['user_name']?.toString() ?? ticket['user_id']?.toString() ?? '-',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                if (uniqueCode > 0)
                  Text('Kode: +${uniqueCode.toString().padLeft(3, '0')}',
                      style: const TextStyle(color: Colors.orange, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrencyFull(serviceFee),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 13),
              ),
              Text('fee layanan', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
              if (totalAmount > 0)
                Text('Total: ${_formatCurrencyFull(totalAmount)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10)),
              Text(createdAt, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrencyFull(dynamic amount) {
    final int val = int.tryParse(amount.toString()) ?? 0;
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
