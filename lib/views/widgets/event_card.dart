import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/event_model.dart';
import '../../config/api_config.dart';
import '../user/event_detail_screen.dart'; // Import ini wajib agar bisa pindah halaman

class EventCard extends StatelessWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Bungkus Container dengan GestureDetector agar kartunya bisa diklik
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // GANTI BAGIAN INI MON! Panggil eventId-nya aje.
            builder: (context) => EventDetailScreen(eventId: event.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gambar (Kita kasih Expanded biar ngambil sisa tinggi)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  ApiConfig.normalizeImageUrl(event.image),
                  width: double.infinity,
                  // height dihapus agar expanded yang mengatur tingginya
                  fit: BoxFit.cover, // Wajib biar landscape terpotong proporsional
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(LucideIcons.image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            
            // 2. Blok Teks (Dibuat super compact)
            Padding(
              padding: const EdgeInsets.all(8.0), // Padding tipis
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Teks padat tanpa space tinggi
                children: [
                  // Judul Pameran ( maxLines 1, lebih tebal)
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      height: 1.2, // Padatkan jarak baris
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Harga & Kategori (Dibuat dalam satu Row kecil)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.formattedPrice,
                        style: const TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.w600, 
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        event.category?.split(' ').first ?? '', // Ambil kata pertama aja (misal 'Pameran')
                        style: TextStyle(
                          fontSize: 9, 
                          fontWeight: FontWeight.bold, 
                          color: const Color(0xFF2C3E50).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Tanggal (Hanya icon + teks padat)
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 10, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.date, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}