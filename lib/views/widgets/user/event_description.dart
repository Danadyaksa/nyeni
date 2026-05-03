import 'package:flutter/material.dart';

/// Section deskripsi event
class EventDescription extends StatelessWidget {
  final String description;

  const EventDescription({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tentang Acara",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          description.isEmpty ? 'Tidak ada deskripsi.' : description,
          style: const TextStyle(color: Colors.grey, height: 1.6),
        ),
      ],
    );
  }
}
