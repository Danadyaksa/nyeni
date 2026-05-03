import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  final _adminController = AdminController();

  Map<String, dynamic> _revenueData = {};
  bool _isLoading = true;

  // Filter bulan yang dipilih (null = tampilkan semua / ringkasan)
  String? _selectedMonth; // format 'YYYY-MM'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _adminController.getRevenue();
    if (mounted) {
      setState(() {
        _revenueData = data;
        _isLoading = false;
      });
    }
  }

  // ─── Data helpers ─────────────────────────────────────────────────────────

  List<dynamic> get _monthly => (_revenueData['monthly'] as List?) ?? [];

  /// Transaksi yang difilter berdasarkan bulan yang dipilih
  List<dynamic> get _filteredTransactions {
    final all = (_revenueData['recent_transactions'] as List?) ?? [];
    if (_selectedMonth == null) return all;
    return all.where((tx) {
      final raw = tx['created_at']?.toString() ?? '';
      try {
        final dt = DateTime.parse(raw).toLocal();
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        return key == _selectedMonth;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Data bulan yang dipilih (untuk summary card)
  Map<String, dynamic>? get _selectedMonthData {
    if (_selectedMonth == null) return null;
    try {
      return (_monthly.firstWhere(
        (m) => m['month']?.toString() == _selectedMonth,
        orElse: () => null,
      ) as Map<String, dynamic>?);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Laporan Revenue',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2C3E50),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
              onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2C3E50)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2C3E50),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Total / bulan terpilih card ──
                    _buildSummaryCard(),
                    const SizedBox(height: 20),

                    // ── Stats row ──
                    _buildStatsRow(),
                    const SizedBox(height: 28),

                    // ── Pendapatan per bulan ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pendapatan per Bulan',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        if (_selectedMonth != null)
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _selectedMonth = null),
                            icon: const Icon(LucideIcons.x,
                                size: 14, color: Colors.grey),
                            label: const Text('Reset',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMonthlySection(),
                    const SizedBox(height: 28),

                    // ── Revenue per event ──
                    const Text('Revenue per Event',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildPerEventSection(),
                    const SizedBox(height: 28),

                    // ── Riwayat transaksi ──
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedMonth != null
                                ? 'Transaksi — ${_selectedMonthData?['month_label'] ?? _selectedMonth}'
                                : 'Riwayat Transaksi Terbaru',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_filteredTransactions.isNotEmpty)
                          Text(
                            '${_filteredTransactions.length} transaksi',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRecentTransactions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Summary Card ─────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final monthData = _selectedMonthData;
    final isFiltered = monthData != null;

    final revenue = isFiltered
        ? int.tryParse(monthData['revenue']?.toString() ?? '0') ?? 0
        : int.tryParse(_revenueData['total_revenue']?.toString() ?? '0') ?? 0;
    final sold = isFiltered
        ? int.tryParse(monthData['ticket_count']?.toString() ?? '0') ?? 0
        : int.tryParse(_revenueData['total_sold']?.toString() ?? '0') ?? 0;
    final txCount = isFiltered
        ? int.tryParse(monthData['transaction_count']?.toString() ?? '0') ?? 0
        : null;

    return Container(
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
          Row(children: [
            const Icon(LucideIcons.trendingUp,
                color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              isFiltered
                  ? 'Revenue ${monthData['month_label']}'
                  : 'Total Revenue (Biaya Layanan)',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            _fmtCurrency(revenue),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Text('$sold tiket terjual',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            if (txCount != null) ...[
              const Text(' · ',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text('$txCount transaksi',
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ]),
        ],
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _miniStat(LucideIcons.clock, 'Pending',
            '${_revenueData['pending_count'] ?? 0}', Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _miniStat(LucideIcons.checkCircle2, 'Aktif',
            '${_revenueData['active_count'] ?? 0}', Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _miniStat(LucideIcons.archive, 'Expired',
            '${_revenueData['expired_count'] ?? 0}', Colors.grey)),
      ],
    );
  }

  Widget _miniStat(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    );
  }

  // ─── Monthly Section ──────────────────────────────────────────────────────

  Widget _buildMonthlySection() {
    if (_monthly.isEmpty) {
      return _emptyCard('Belum ada data bulanan.');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          ..._monthly.map((m) {
            final rev = int.tryParse(m['revenue']?.toString() ?? '0') ?? 0;
            final txCount = int.tryParse(m['transaction_count']?.toString() ?? '0') ?? 0;
            final ticketCount = int.tryParse(m['ticket_count']?.toString() ?? '0') ?? 0;
            final monthKey = m['month']?.toString() ?? '';
            final isSelected = _selectedMonth == monthKey;

            return GestureDetector(
              onTap: () => setState(() {
                _selectedMonth = isSelected ? null : monthKey;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.withOpacity(0.05) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange.withOpacity(0.15)
                            : const Color(0xFF2C3E50).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.calendarDays,
                        size: 16,
                        color: isSelected ? Colors.orange : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['month_label']?.toString() ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? Colors.orange : Colors.black87,
                            ),
                          ),
                          Text(
                            '$txCount transaksi · $ticketCount tiket',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _fmtCurrency(rev),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.orange : const Color(0xFF2C3E50),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isSelected ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─── Per Event Section ────────────────────────────────────────────────────

  Widget _buildPerEventSection() {
    final perEvent = (_revenueData['per_event'] as List?) ?? [];
    if (perEvent.isEmpty) {
      return _emptyCard('Belum ada data revenue per event');
    }

    final totalRevenue =
        int.tryParse(_revenueData['total_revenue']?.toString() ?? '1') ??
            1;

    return Column(
      children: perEvent.map((item) {
        final eventName = item['event_name']?.toString() ?? '-';
        final ticketCount =
            int.tryParse(item['ticket_count']?.toString() ?? '0') ?? 0;
        final txCount =
            int.tryParse(item['transaction_count']?.toString() ?? '0') ??
                0;
        final revenue =
            int.tryParse(item['revenue']?.toString() ?? '0') ?? 0;
        final percent = totalRevenue > 0
            ? (revenue / totalRevenue).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 8)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(eventName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(_fmtCurrency(revenue),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.creditCard,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('$txCount pembayaran',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.ticket,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('$ticketCount tiket',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                  const Spacer(),
                  Text('${(percent * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2C3E50)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Recent Transactions ──────────────────────────────────────────────────

  Widget _buildRecentTransactions() {
    final txList = _filteredTransactions;
    if (txList.isEmpty) {
      return _emptyCard(_selectedMonth != null
          ? 'Tidak ada transaksi di bulan ini'
          : 'Belum ada transaksi');
    }

    return Column(
      children: txList.map((tx) => _buildTxRow(tx)).toList(),
    );
  }

  Widget _buildTxRow(dynamic tx) {
    final serviceFee =
        int.tryParse(tx['service_fee']?.toString() ?? '0') ?? 0;
    final totalAmount =
        int.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0;
    final uniqueCode =
        int.tryParse(tx['unique_code']?.toString() ?? '0') ?? 0;
    final ticketCount =
        int.tryParse(tx['ticket_count']?.toString() ?? '1') ?? 1;
    final ticketPrice =
        int.tryParse(tx['ticket_price']?.toString() ?? '0') ?? 0;
    final createdAt = tx['created_at'] != null
        ? _fmtDate(tx['created_at'].toString())
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.receipt,
                color: Colors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['event_name']?.toString() ?? '-',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(tx['user_name']?.toString() ?? '-',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                Row(
                  children: [
                    const Icon(LucideIcons.ticket,
                        size: 10, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text('$ticketCount tiket',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 10)),
                    if (ticketPrice > 0) ...[
                      const SizedBox(width: 6),
                      Text('@ ${_fmtCurrency(ticketPrice)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 10)),
                    ],
                    if (uniqueCode > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                          '+${uniqueCode.toString().padLeft(3, '0')}',
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 10)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                serviceFee > 0 ? _fmtCurrency(serviceFee) : 'Rp 2.500',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontSize: 13),
              ),
              Text('fee layanan',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 9)),
              if (totalAmount > 0)
                Text('Total: ${_fmtCurrency(totalAmount)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 10)),
              Text(createdAt,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Center(
          child: Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey))),
    );
  }

  String _fmtCurrency(dynamic amount) {
    final int val = int.tryParse(amount.toString()) ?? 0;
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
