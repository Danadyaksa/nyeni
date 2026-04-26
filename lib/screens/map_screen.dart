import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Pameran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(-7.7956, 110.3695), // Titik tengah: Yogyakarta
          initialZoom: 13.0,
        ),
        children: [
          // 1. Layer Peta OpenStreetMap
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.nyeniapp',
          ),
          // 2. Layer Marker (Pin Lokasi)
          MarkerLayer(
            markers: [
              Marker(
                point: const LatLng(-7.8005, 110.3533), // Jogja National Museum (JNM)
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ARTJOG 2026 di Jogja National Museum')),
                    );
                  },
                  child: const Icon(LucideIcons.mapPin, color: Colors.red, size: 40),
                ),
              ),
              Marker(
                point: const LatLng(-7.7900, 110.3750), // Kridosono
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Indie Music Fest di Kridosono')),
                    );
                  },
                  child: const Icon(LucideIcons.mapPin, color: Colors.blue, size: 40),
                ),
              ),
            ],
          ),
        ],
      ),
      // Tombol Center Lokasi
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Fungsi balik ke lokasi user (GPS)
        },
        backgroundColor: const Color(0xFF2C3E50),
        child: const Icon(LucideIcons.navigation, color: Colors.white),
      ),
    );
  }
}