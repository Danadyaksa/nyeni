import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen>
    with SingleTickerProviderStateMixin {
  final _adminController = AdminController();
  late TabController _tabController;

  List<dynamic> _allTickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      // Langsung ambil response tanpa convert ke Ticket model
      // karena backend return field tambahan (first_ticket_id, ticket_count, user_name)
      final response = await http.get(
        Uri.parse("${AdminController.baseUrl}/admin/tickets"),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> tickets = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allTickets = tickets;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _allTickets = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading tickets: $e');
      if (mounted) {
        setState(() {
          _allTickets = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAccept(String ticketId, String eventName, int ticketCount) async {
    // Validasi ticketId tidak boleh kosong
    if (ticketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: ID tiket tidak valid'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      title: 'Konfirmasi Pembayaran',
      message: 'Setujui pembayaran untuk "$eventName"?\n$ticketCount tiket akan langsung aktif.',
      confirmText: 'Ya, Setujui',
      confirmColor: Colors.green,
    );
    if (!confirm) return;

    final result = await _adminController.acceptTicket(ticketId);
    if (mounted) {
      final success = !result.containsKey('error');
      final message = success 
          ? '✅ $ticketCount tiket berhasil diaktifkan!' 
          : '❌ Gagal mengaktifkan tiket: ${result['error'] ?? 'Unknown error'}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      if (success) _loadTickets();
    }
  }

  Future<void> _handleDecline(String ticketId, String eventName, int ticketCount) async {
    final confirm = await _showConfirmDialog(
      title: 'Tolak Pembayaran',
      message: 'Tolak pembayaran untuk "$eventName"?\n$ticketCount tiket akan ditandai DECLINED.',
      confirmText: 'Ya, Tolak',
      confirmColor: Colors.red,
    );
    if (!confirm) return;

    final result = await _adminController.declineTicket(ticketId);
    if (mounted) {
      final success = !result.containsKey('error');
      final message = success 
          ? '🚫 $ticketCount tiket berhasil ditolak' 
          : '❌ Gagal menolak tiket: ${result['error'] ?? 'Unknown error'}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      if (success) _loadTickets();
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  List<dynamic> _filterByStatus(String status) =>
      _allTickets.where((t) => t['status'] == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Verifikasi Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2C3E50),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: _loadTickets,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  const SizedBox(width: 4),
                  if (_filterByStatus('PENDING').isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_filterByStatus('PENDING').length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: 'Aktif'),
            const Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList('PENDING'),
                _buildTicketList('ACTIVE'),
                _buildTicketList('DECLINED'),
              ],
            ),
    );
  }

  Widget _buildTicketList(String status) {
    final tickets = _filterByStatus(status);

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'PENDING' ? LucideIcons.clock : LucideIcons.checkCircle2,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              status == 'PENDING'
                  ? 'Tidak ada tiket yang menunggu verifikasi'
                  : 'Tidak ada tiket $status',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: const Color(0xFF2C3E50),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return _buildTicketCard(ticket, status);
        },
      ),
    );
  }

  Widget _buildTicketCard(dynamic ticket, String status) {
    final createdAt = ticket['created_at'] != null
        ? _formatDate(ticket['created_at'].toString())
        : '-';
    // Gunakan first_ticket_id untuk accept/decline (server akan update semua tiket dalam transaksi)
    final String ticketId = (ticket['first_ticket_id'] ?? ticket['id'])?.toString() ?? '';
    final int ticketCount = int.tryParse(ticket['ticket_count']?.toString() ?? '1') ?? 1;

    // Validasi ticketId
    if (ticketId.isEmpty) {
      print('⚠️ Warning: ticketId is empty for ticket: $ticket');
    }

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
        statusLabel = 'Menunggu Verifikasi';
        break;
      case 'ACTIVE':
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle2;
        statusLabel = 'Aktif';
        break;
      case 'DECLINED':
        statusColor = Colors.red;
        statusIcon = LucideIcons.xCircle;
        statusLabel = 'Ditolak';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = LucideIcons.helpCircle;
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: status == 'PENDING'
            ? Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: event name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket['event_name'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          // Badge jumlah tiket
                          if (ticketCount > 1) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C3E50).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.ticket, size: 11, color: Color(0xFF2C3E50)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$ticketCount tiket dalam 1 transaksi',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusLabel,
                              style: TextStyle(
                                  color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildInfoRow(LucideIcons.user, 'Pembeli', ticket['user_name'] ?? ticket['user_id'] ?? '-'),
                const SizedBox(height: 6),
                _buildInfoRow(LucideIcons.calendar, 'Tanggal Event', ticket['event_date'] ?? '-'),
                const SizedBox(height: 6),
                _buildInfoRow(LucideIcons.clock3, 'Dipesan', createdAt),
                const SizedBox(height: 6),
                _buildInfoRow(LucideIcons.hash, 'ID Transaksi', ticketId.length >= 8 ? ticketId.substring(0, 8) : ticketId),

                if (status == 'PENDING') ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _buildNominalBox(ticket, ticketCount),
                ],
              ],
            ),
          ),

          // Action buttons (only for PENDING)
          if (status == 'PENDING') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDecline(ticketId, ticket['event_name'] ?? '', ticketCount),
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAccept(ticketId, ticket['event_name'] ?? '', ticketCount),
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: Text(ticketCount > 1 ? 'Setujui ($ticketCount tiket)' : 'Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNominalBox(dynamic ticket, int ticketCount) {
    final ticketPrice = int.tryParse(ticket['ticket_price']?.toString() ?? '0') ?? 0;
    final serviceFee = int.tryParse(ticket['service_fee']?.toString() ?? '0') ?? 0;
    final uniqueCode = int.tryParse(ticket['unique_code']?.toString() ?? '0') ?? 0;
    final totalAmount = int.tryParse(ticket['total_amount']?.toString() ?? '0') ?? 0;

    // Tiket ke-2 dst: service_fee = 0, total_amount = 0
    // Cukup tampilkan harga tiket saja
    final bool isMainTicket = totalAmount > 0 || serviceFee > 0;

    if (!isMainTicket) {
      // Tiket tambahan — tampilkan harga tiket saja
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.ticket, size: 13, color: Colors.grey),
                SizedBox(width: 6),
                Text('Harga Tiket', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            Text(
              'Rp ${_formatCurrency(ticketPrice)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
          ],
        ),
      );
    }

    // Tiket utama (pertama) — tampilkan rincian lengkap
    final displayTotal = totalAmount > 0 ? totalAmount : (ticketPrice + serviceFee + uniqueCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.banknote, size: 13, color: Colors.blue),
              const SizedBox(width: 6),
              const Text('Rincian Pembayaran', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Spacer(),
              if (ticketCount > 1)
                Text('$ticketCount tiket', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          if (ticketCount > 1)
            _buildNominalRow('Harga per Tiket', ticketPrice),
          if (ticketCount > 1)
            _buildNominalRow('Subtotal ($ticketCount × Rp ${_formatCurrency(ticketPrice)})', ticketPrice * ticketCount),
          if (ticketCount == 1)
            _buildNominalRow('Harga Tiket', ticketPrice),
          _buildNominalRow('Biaya Layanan', serviceFee),
          if (uniqueCode > 0)
            _buildNominalRow('Kode Unik', uniqueCode, isCode: true),
          const Divider(height: 12, color: Colors.blue),
          _buildNominalRow('Total Transfer', displayTotal, isBold: true),
        ],
      ),
    );
  }

  Widget _buildNominalRow(String label, int val, {bool isBold = false, bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: isBold ? Colors.black87 : Colors.grey[700], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            isCode ? '+${val.toString().padLeft(3, '0')}' : 'Rp ${_formatCurrency(val)}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCode ? Colors.orange : (isBold ? const Color(0xFF2C3E50) : Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int val) =>
      val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String raw) {
    try {
      // Parse sebagai UTC lalu konversi ke WIB (+7)
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
