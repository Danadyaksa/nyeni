import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/event_model.dart';

class CheckoutScreen extends StatelessWidget {
  final Event event;
  final int count;
  const CheckoutScreen({super.key, required this.event, required this.count});

  @override
  Widget build(BuildContext context) {
    int priceInt = int.parse(event.price.replaceAll(RegExp(r'[^0-9]'), ''));
    int subtotal = priceInt * count;
    int serviceFee = 2500;
    int total = subtotal + serviceFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Ringkasan Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Card
            _buildSectionCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(event.image, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(event.category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(LucideIcons.star, color: Colors.amber, size: 14),
                            Text(" 4.8", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(" • Yogyakarta", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            _buildSectionTitle("Detail Pesanan"),
            _buildSectionCard(
              child: Column(
                children: [
                  _buildDetailRow("Tanggal", event.date),
                  const Divider(),
                  _buildDetailRow("Jumlah Tiket", "$count Tiket"),
                ],
              ),
            ),

            _buildSectionTitle("Informasi Pemesan"),
            _buildSectionCard(
              child: Column(
                children: [
                  _buildInfoRow(LucideIcons.user, "Nama", "Mohammad Atilla Danadyaksa"),
                  const Divider(),
                  _buildInfoRow(LucideIcons.mail, "Email", "atilla.aksa@email.com"),
                ],
              ),
            ),

            _buildSectionTitle("Detail Pembayaran"),
            _buildSectionCard(
              child: Column(
                children: [
                  _buildPriceRow("Subtotal Tiket", subtotal),
                  _buildPriceRow("Biaya Layanan", serviceFee),
                  const Divider(),
                  _buildPriceRow("Total Pembayaran", total, isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomPay(total, context),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: child,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const Spacer(),
        const Icon(LucideIcons.edit3, size: 16, color: Colors.blue),
      ],
    );
  }

  Widget _buildPriceRow(String label, int value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text("Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTotal ? 16 : 14, color: isTotal ? const Color(0xFF2C3E50) : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildBottomPay(int total, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Harga", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text("Rp $total", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Pesan Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}