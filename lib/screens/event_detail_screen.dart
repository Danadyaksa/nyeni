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

  // Fungsi buka Google Maps (Sudah Diperbaiki)
  Future<void> _openMaps() async {
    // Kita buat pencariannya dinamis sesuai nama penyelenggara/lokasi pameran
    final String query = Uri.encodeComponent("${widget.event.organizer} Yogyakarta");
    // Gunakan format URL Search standar Google Maps
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    
    try {
      // externalApplication akan memaksa buka di aplikasi G-Maps bawaan HP (jika ada) atau browser
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka aplikasi Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.5)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(widget.event.image, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      const Text("4.8", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text("(120 Review)", style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Lokasi & Petunjuk Arah
                  const Text("Lokasi Pameran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: Color(0xFF2C3E50), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${widget.event.organizer}, Kota Yogyakarta", 
                          style: const TextStyle(color: Colors.grey)
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(LucideIcons.navigation, size: 16),
                    label: const Text("Lihat Petunjuk Arah (Google Maps)"),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF2C3E50)),
                  ),

                  const Divider(height: 40),

                  // Review Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Review Pengguna", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {}, 
                        child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF2C3E50)))
                      ),
                    ],
                  ),
                  _buildReviewItem("Ikaaa", "Pamerannya keren banget, instalasinya interaktif!"),
                  _buildReviewItem("Riska", "Vibes-nya nyeni pol, cocok buat cari inspirasi."),

                  const SizedBox(height: 120), // Ruang kosong bawah
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildReviewItem(String user, String comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    // 1. Ekstrak angka dari teks "Rp 75.000" menjadi integer 75000
    int priceInt = 0;
    try {
      priceInt = int.parse(widget.event.price.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (e) {
      priceInt = 0;
    }

    // 2. Hitung total harga
    int totalHarga = priceInt * _ticketCount;

    // 3. Format kembali ke tulisan "Rp XX.XXX"
    String formattedTotal = "Rp ${totalHarga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris 1: Kontrol Jumlah Tiket
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Jumlah Tiket", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_ticketCount > 1) {
                        setState(() => _ticketCount--);
                      }
                    }, 
                    icon: const Icon(LucideIcons.minusCircle, color: Color(0xFF2C3E50))
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      "$_ticketCount", 
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _ticketCount++), 
                    icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF2C3E50))
                  ),
                ],
              )
            ],
          ),
          const Divider(height: 24),
          
          // Baris 2: Total Harga & Tombol Beli
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Harga", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    formattedTotal, // Harga sudah otomatis berubah sesuai jumlah tiket
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        event: widget.event, 
                        count: _ticketCount, // Kirim jumlah tiket ke halaman checkout
                      )
                    )
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50), 
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Beli Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }
}