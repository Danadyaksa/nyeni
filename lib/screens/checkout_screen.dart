import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import 'main_navigation.dart';

class CheckoutScreen extends StatefulWidget {
  final Event event;
  final int count;
  const CheckoutScreen({super.key, required this.event, required this.count});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedPayment = 'QRIS'; // Default pilihan
  bool _isProcessing = false;

  // Mengambil data user yang sedang login dari Supabase, dengan fallback nama 'Aksa'
  String get _userName => _supabase.auth.currentUser?.userMetadata?['full_name'] ?? "Aksa";
  String get _userEmail => _supabase.auth.currentUser?.email ?? "aksa@email.com";

  // TAHAP 1: Munculkan Dialog Instruksi Bayar (QRIS / BCA)
  void _showPaymentInstructionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Instruksi Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Logika Tampilan Berdasarkan Metode
            if (_selectedPayment == 'QRIS') ...[
              const Text('Scan QRIS di bawah ini menggunakan M-Banking atau E-Wallet kamu.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                // TODO: Nanti gambarnya bisa diganti pakai Image.asset('assets/qris_asli.png') kalau gambarnya udah ada
                child: const Column(
                  children: [
                    Icon(LucideIcons.qrCode, size: 150, color: Color(0xFF2C3E50)),
                    SizedBox(height: 8),
                    Text("QRIS NYENI INDONESIA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ] else ...[
              const Text('Transfer tepat sesuai nominal ke rekening BCA berikut:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const Text("880123456789", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2, color: Color(0xFF2C3E50))),
              ),
              const SizedBox(height: 8),
              const Text('a.n. PT Nyeni Indonesia', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],

            const SizedBox(height: 24),
            
            // Tombol "Saya Sudah Bayar"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog instruksi
                  _submitPaymentProof();  // Lanjut proses kirim status 'pending'
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Saya Sudah Bayar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }

  // TAHAP 2: Proses Data ke Database & Munculkan Status "Menunggu Admin"
  void _submitPaymentProof() async {
    setState(() => _isProcessing = true);
    
    // Simulasi proses upload bukti/update database status menjadi 'Pending'
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isProcessing = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.clock, color: Colors.orange, size: 70), // Ikon Jam
              const SizedBox(height: 16),
              const Text('Menunggu Verifikasi', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Pembayaran kamu sedang dicek oleh Admin. Tiket akan otomatis aktif setelah admin menyetujuinya.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Balik ke home
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigation()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int priceInt = int.parse(widget.event.price.replaceAll(RegExp(r'[^0-9]'), ''));
    int subtotal = priceInt * widget.count;
    int total = subtotal + 2500;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text("Konfirmasi Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INFO EVENT
            _buildCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(widget.event.image, width: 70, height: 70, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("${widget.count} Tiket • ${widget.event.date}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                  _buildPriceRow("Biaya Layanan", 2500),
                  const Divider(height: 32),
                  _buildPriceRow("Total Bayar", total, isBold: true),
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
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  );

  Widget _buildCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );

  Widget _buildInfoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20, color: Colors.grey),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          color: isSelected ? const Color(0xFF2C3E50).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2C3E50) : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
            if (isSelected) const Icon(LucideIcons.checkCircle2, color: Color(0xFF2C3E50), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int val, {bool isBold = false, bool isQty = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey)),
        Text(
          isQty ? "x$val" : "Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 17 : 14, color: isBold ? const Color(0xFF2C3E50) : Colors.black),
        ),
      ],
    ),
  );

  Widget _buildBottomBar(int total) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
    child: Row(
      children: [
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Total Tagihan", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text("Rp ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}", 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          ]),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _showPaymentInstructionDialog, // <-- Berubah memanggil instruksi bayar
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E50),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isProcessing 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Bayar Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ],
    ),
  );
}