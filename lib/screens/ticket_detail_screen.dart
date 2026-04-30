import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TicketDetailScreen extends StatelessWidget {
  final String qrData; 
  final String eventName;

  const TicketDetailScreen({super.key, required this.qrData, required this.eventName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50), // Background gelap biar mewah
      appBar: AppBar(
        title: const Text("E-Tiket Nyeni", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BUNGKUSAN TIKETNYA
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)]
                ),
                child: Column(
                  children: [
                    // Gambar Header Tiket
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=600&auto=format&fit=crop', // Gambar party dummy
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      eventName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.checkCircle2, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text("Tiket Aktif", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
                      child: Divider(thickness: 2, color: Colors.black12), // Garis putus-putus ala tiket
                    ),
                    
                    const Text("Scan QR Code ini di pintu masuk", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    
                    // QR Code
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                    
                    const SizedBox(height: 16),
                    Text("ID: $qrData", style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}