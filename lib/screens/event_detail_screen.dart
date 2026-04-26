import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import 'checkout_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _ticketCount = 1;

  // Fungsi buka Google Maps (Sudah Diperbaiki Total)
  Future<void> _openMaps() async {
    final String query = Uri.encodeComponent("${widget.event.organizer} Yogyakarta");
    // Format URL universal untuk membuka aplikasi Maps di Android/iOS
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka Google Maps. Pastikan aplikasi terinstall.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logika Kalkulasi Harga
    int priceInt = int.parse(widget.event.price.replaceAll(RegExp(r'[^0-9]'), ''));
    int totalHarga = priceInt * _ticketCount;
    String formattedTotal = "Rp ${totalHarga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(), // Biar scroll lebih luwes
        slivers: [
          // 1. HEADER GAMBAR
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.7)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(widget.event.image, fit: BoxFit.cover),
            ),
          ),

          // 2. KONTEN UTAMA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul & Rating
                  Text(widget.event.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      const Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 6),
                      Text("(120 Review Pengunjung)", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                  
                  const Divider(height: 40),

                  // A. LOKASI (Paling Atas sesuai permintaan)
                  const Text("Lokasi Pameran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.mapPin, color: Color(0xFF2C3E50), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.event.organizer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Text("Jl. Amri Yahya No.1, Wirobrajan, Kota Yogyakarta", style: TextStyle(color: Colors.grey, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(LucideIcons.navigation, size: 18),
                    label: const Text("Buka Petunjuk Arah", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2C3E50),
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // B. DESKRIPSI
                  const Text("Deskripsi Pameran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    "Nikmati pengalaman 'Nyeni' yang tak terlupakan di pameran ini. Menampilkan berbagai instalasi kontemporer, lukisan abstrak, dan karya interaktif dari seniman pilihan. Cocok untuk kamu yang ingin mencari inspirasi atau sekadar menikmati keindahan visual di sudut kota Yogyakarta.",
                    style: TextStyle(color: Colors.black87, height: 1.6, fontSize: 15),
                  ),

                  const SizedBox(height: 32),

                  // C. REVIEW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Review Pengguna", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {}, child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF2C3E50)))),
                    ],
                  ),
                  _buildReviewCard("Ikaaa", "Instalasinya keren banget buat foto-foto, vibesnya dapet!"),
                  _buildReviewCard("Danang", "Kuratornya ramah, penjelasannya detail banget."),

                  // PENTING: Ruang kosong agar tidak "terkunci" oleh bottom action
                  const SizedBox(height: 150), 
                ],
              ),
            ),
          ),
        ],
      ),
      
      // BOTTOM ACTION BAR
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Jumlah Tiket", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _ticketCount > 1 ? _ticketCount-- : null),
                      icon: const Icon(LucideIcons.minusCircle, color: Color(0xFF2C3E50)),
                    ),
                    Text("$_ticketCount", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => setState(() => _ticketCount++),
                      icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF2C3E50)),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total Pembayaran", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(formattedTotal, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(event: widget.event, count: _ticketCount)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Pesan Tiket", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String user, String msg) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 12, backgroundColor: Color(0xFF2C3E50), child: Icon(LucideIcons.user, size: 12, color: Colors.white)),
              const SizedBox(width: 8),
              Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }
}