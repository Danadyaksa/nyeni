import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';
import 'checkout_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? _event;
  int _ticketCount = 1;
  bool _isLoading = true;
  Map<String, dynamic>? _selectedTicket; // Nyimpen tiket yang diklik

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final data = await AuthService().getEventDetail(widget.eventId);
    setState(() {
      _event = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_event == null) return const Scaffold(body: Center(child: Text("Event kaga nemu pak!")));

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Header Besar
            Stack(
              children: [
                Image.network(_event!['image_url'], width: double.infinity, height: 350, fit: BoxFit.cover),
                Positioned(top: 40, left: 20, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.black), onPressed: () => Navigator.pop(context)))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(_event!['category'], style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  Text(_event!['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(_event!['event_date'], style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(_event!['location'], style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Tentang Acara", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_event!['description'] ?? "Kaga ada deskripsi pak.", style: const TextStyle(color: Colors.grey, height: 1.5)),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      // BUNGKUSAN BAWAH (PILIH TIKET)
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // List Pilihan Tiket
            if (_event != null && _event!['ticket_options'] != null)
              ...(_event!['ticket_options'] as List).map((ticket) {
                bool isAvailable = ticket['status'] == 'AVAILABLE';
                bool isSelected = _selectedTicket != null && _selectedTicket!['type'] == ticket['type'];

                return GestureDetector(
                  onTap: isAvailable ? () => setState(() => _selectedTicket = ticket) : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAvailable ? (isSelected ? const Color(0xFF2C3E50).withOpacity(0.05) : Colors.white) : Colors.grey.shade100,
                      border: Border.all(color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ticket['type'], style: TextStyle(fontWeight: FontWeight.bold, color: isAvailable ? Colors.black : Colors.grey)),
                            Text(ticket['status'], style: TextStyle(fontSize: 10, color: isAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text("Rp ${ticket['price']}", style: TextStyle(fontWeight: FontWeight.bold, color: isAvailable ? const Color(0xFF2C3E50) : Colors.grey)),
                      ],
                    ),
                  ),
                );
              }),
            
            const SizedBox(height: 16),
            
            // Tombol Pesan & Counter
            Row(
              children: [
                Row(
                  children: [
                    IconButton(icon: const Icon(LucideIcons.minusCircle), onPressed: () => setState(() => _ticketCount > 1 ? _ticketCount-- : null)),
                    Text("$_ticketCount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(LucideIcons.plusCircle), onPressed: () => setState(() => _ticketCount++)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedTicket == null ? null : () { // Kalo belom milih tiket, mati tombolnye
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(
                        event: Event(
                          id: widget.eventId,
                          title: "${_event!['title']} - ${_selectedTicket!['type']}", // Kasih tau tiket apa yang dibeli
                          organizer: "Panitia Nyeni",
                          date: _event!['event_date'],
                          price: "Rp ${_selectedTicket!['price']}",
                          image: _event!['image_url'],
                          category: _event!['category'],
                        ),
                        count: _ticketCount,
                      )));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(_selectedTicket == null ? "Pilih Tiket Dulu" : "Pesan Tiket", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}