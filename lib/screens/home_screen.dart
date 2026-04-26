import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/event_card.dart';
import '../models/event_model.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // Data Dummy untuk Testing UI
  final List<Event> dummyEvents = [
    Event(
      title: 'ARTJOG 2026: Motif',
      organizer: 'Jogja National Museum',
      date: '25 Mei - 25 Juli 2026',
      price: 'Rp 75.000',
      category: 'Pameran Seni Rupa',
      image: 'https://images.unsplash.com/photo-1549490349-8643362247b5?q=80&w=600',
    ),
    Event(
      title: 'Indie Music Fest',
      organizer: 'Kridosono Stadium',
      date: '10 Juni 2026',
      price: 'Rp 120.000',
      category: 'Musik Indie',
      image: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?q=80&w=600',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Buka Dialog Chat Bot BAGAS
        },
        backgroundColor: const Color(0xFF2C3E50),
        child: const Icon(LucideIcons.messageSquare, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            expandedHeight: 120,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, Aksa!', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text('Mau Nyeni hari ini?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.bell),
                      onPressed: () {},
                      style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
                    )
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari pameran seni...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // List Event
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dummyEvents.length,
                    // HAPUS parameter childAspectRatio. Gunakan default delegate.
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 kolom
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      // Kita biarkan tinggi grid otomatis menyesuaikan isinya
                    ),
                    itemBuilder: (context, index) {
                      return EventCard(event: dummyEvents[index]);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}