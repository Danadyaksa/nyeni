import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/event_model.dart';
import '../../controllers/ticket_controller.dart';
import '../../config/api_config.dart';
import 'main_navigation.dart';

class CheckoutScreen extends StatefulWidget {
  final Event event;
  final int count;
  const CheckoutScreen({super.key, required this.event, required this.count});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'QRIS'; 
  bool _isProcessing = false;
  final _ticketController = TicketController();

  String _userName = "Aksa";
  String _userEmail = "aksa@email.com";

  // Kode unik 3 digit — di-generate sekali saat halaman dibuka
  late final int _uniqueCode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Random 1–999, padded jadi 3 digit (misal: 052)
    _uniqueCode = 1 + (DateTime.now().millisecondsSinceEpoch % 999);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      setState(() {
        _userName = userData['full_name'] ?? "Aksa";
        _userEmail = userData['email'] ?? "aksa@email.com";
      });
    }
  }

  void _showPaymentInstructionDialog() {
    int priceInt = widget.event.price;
    int subtotal = priceInt * widget.count;
    const int serviceFee = 2500;
    int totalSebelumKode = subtotal + serviceFee;
    int total = totalSebelumKode + _uniqueCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Instruksi Pembayaran',
                style: GoogleFonts.ebGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A302A),
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedPayment == 'QRIS') ...[
                Text(
                  'Scan QRIS di bawah ini menggunakan M-Banking atau E-Wallet kamu.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8D0C8), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/qrisnyeni.jpeg',
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "QRIS NYENI INDONESIA",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: const Color(0xFF3A302A),
                  ),
                ),
              ] else ...[
                Text(
                  'Transfer tepat sesuai nominal ke rekening BCA berikut:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE2DA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "880123456789",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 2,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'a.n. PT Nyeni Indonesia',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF78706A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Rincian nominal transfer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A3412).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8D0C8)),
                ),
                child: Column(
                  children: [
                    _buildDialogPriceRow('Subtotal', totalSebelumKode),
                    const SizedBox(height: 4),
                    _buildDialogPriceRow('Kode Unik', _uniqueCode, isCode: true),
                    const Divider(height: 16),
                    _buildDialogPriceRow('Total Transfer', total, isBold: true),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 13, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'Transfer TEPAT Rp ${_formatRp(total)}',
                            style: GoogleFonts.manrope(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    _submitPaymentProof();  
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A3412),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Saya Sudah Bayar',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogPriceRow(String label, int val, {bool isBold = false, bool isCode = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: isBold ? const Color(0xFF3A302A) : const Color(0xFF78706A),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          isCode ? '+${val.toString().padLeft(3, '0')}' : 'Rp ${_formatRp(val)}',
          style: GoogleFonts.manrope(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isCode ? Colors.orange : (isBold ? const Color(0xFF9A3412) : const Color(0xFF3A302A)),
          ),
        ),
      ],
    );
  }

  String _formatRp(int val) =>
      val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  // TAHAP 2: Bikin dialog PENDING baru buat nahan user
  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.clock, color: Colors.orange, size: 70), 
            const SizedBox(height: 16),
            Text(
              'Menunggu Verifikasi',
              textAlign: TextAlign.center,
              style: GoogleFonts.ebGaramond(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A302A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan sudah diterima, mohon untuk menunggu konfirmasi pembayaran dari admin. jika sudah terkonfirmasi, tiket otomatis aktif dan dapat diakses di menu profil!',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: const Color(0xFF78706A),
                height: 1.5,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Lempar balik ke Home/MainNavigation
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainNavigation()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A3412),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Kembali ke Beranda',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAHAP 3: Proses nembak API Express — buat N tiket sekaligus (1 per count)
  void _submitPaymentProof() async {
    setState(() => _isProcessing = true);

    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      final String userId = userData['id'].toString();

      int priceInt = widget.event.price;
      int subtotal = priceInt * widget.count;
      const int serviceFee = 2500; // flat per transaksi, bukan per tiket
      int total = subtotal + serviceFee + _uniqueCode;

      // Buat tiket sebanyak widget.count — masing-masing dapat QR unik sendiri
      final response = await _ticketController.buyTickets(
        userId: userId,
        eventName: widget.event.title,
        eventDate: widget.event.date,
        count: widget.count,
        uniqueCode: _uniqueCode,
        serviceFee: serviceFee,
        ticketPrice: priceInt,
        totalAmount: total,
      );

      setState(() => _isProcessing = false);

      if (response['success'] == true) {
        if (mounted) _showPendingDialog();
      } else {
        String errorMsg = response['error'] ?? "Ada masalah di server nih pak";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Yah gagal pesen tiket: $errorMsg")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int priceInt = widget.event.price;
    int subtotal = priceInt * widget.count;
    const int serviceFee = 2500;
    int totalSebelumKode = subtotal + serviceFee;
    int total = totalSebelumKode + _uniqueCode; // total transfer = subtotal + biaya layanan + kode unik

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EE),
      appBar: AppBar(
        title: Text(
          "Konfirmasi Pesanan",
          style: GoogleFonts.libreBaskerville(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF3A302A),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFAFAF9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A302A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(ApiConfig.normalizeImageUrl(widget.event.image), width: 70, height: 70, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF3A302A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.count} Tiket • ${widget.event.date}",
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF78706A),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            _buildLabel("Informasi Pemesan"),
            _buildCard(
              child: Column(
                children: [
                  _buildInfoRow(LucideIcons.user, "Nama Lengkap", _userName),
                  const Divider(height: 24),
                  _buildInfoRow(LucideIcons.mail, "Email Aktif", _userEmail),
                ],
              ),
            ),

            _buildLabel("Pilih Metode Pembayaran"),
            _buildPaymentOption("QRIS", "Bayar instan via aplikasi bank/e-wallet", LucideIcons.qrCode),
            const SizedBox(height: 12),
            _buildPaymentOption("Transfer BCA", "Manual transfer ke Virtual Account", LucideIcons.creditCard),

            _buildLabel("Detail Harga"),
            _buildCard(
              child: Column(
                children: [
                  _buildPriceRow("Harga Satuan", priceInt),
                  _buildPriceRow("Jumlah", widget.count, isQty: true),
                  _buildPriceRow("Biaya Layanan", serviceFee),
                  _buildPriceRow("Kode Unik", _uniqueCode, isCode: true),
                  const Divider(height: 32),
                  _buildPriceRow("Total Transfer", total, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(total),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 12),
    child: Text(
      text,
      style: GoogleFonts.ebGaramond(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: const Color(0xFF3A302A),
      ),
    ),
  );

  Widget _buildCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAF9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD8D0C8)),
    ),
    child: child,
  );

  Widget _buildInfoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20, color: const Color(0xFF78706A)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF78706A)),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: const Color(0xFF3A302A),
          ),
        ),
      ]),
    ],
  );

  Widget _buildPaymentOption(String title, String sub, IconData icon) {
    bool isSelected = _selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9A3412).withOpacity(0.05) : const Color(0xFFFAFAF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF9A3412) : const Color(0xFFD8D0C8),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF9A3412) : const Color(0xFF78706A),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A302A),
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF78706A),
                  ),
                ),
              ]),
            ),
            if (isSelected) const Icon(LucideIcons.checkCircle2, color: Color(0xFF9A3412), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int val, {bool isBold = false, bool isQty = false, bool isCode = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                color: isBold ? const Color(0xFF3A302A) : const Color(0xFF78706A),
              ),
            ),
            if (isCode) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'untuk identifikasi',
                  style: GoogleFonts.manrope(fontSize: 9, color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
        Text(
          isQty ? "x$val" : (isCode ? "+${val.toString().padLeft(3, '0')}" : "Rp ${_formatRp(val)}"),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 17 : 14,
            color: isCode ? Colors.orange : (isBold ? const Color(0xFF9A3412) : const Color(0xFF3A302A)),
          ),
        ),
      ],
    ),
  );

  Widget _buildBottomBar(int total) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAF9),
      border: Border.all(color: const Color(0xFFD8D0C8)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "Total Transfer",
              style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF78706A)),
            ),
            Text(
              "Rp ${_formatRp(total)}",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9A3412),
              ),
            ),
          ]),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _showPaymentInstructionDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9A3412),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isProcessing 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                "Bayar Sekarang",
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        )
      ],
    ),
  );
}