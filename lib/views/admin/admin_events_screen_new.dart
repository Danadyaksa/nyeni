import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';
import '../widgets/admin/admin_event_card.dart';
import '../widgets/admin/event_form_sheet.dart';

const Color _primary = Color(0xFF2C3E50);

/// Admin Events Screen - Kelola semua event
class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _adminController = AdminController();
  List<dynamic> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final data = await _adminController.getAllEventsAdmin();
    if (mounted) setState(() { _events = data; _isLoading = false; });
  }

  void _openForm({Map<String, dynamic>? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFormSheet(
        event: event,
        onSaved: (data) async {
          Map<String, dynamic> result;
          if (event != null) {
            result = await _adminController.updateEvent(
              id: event['id'] as int,
              name: data['title'],
              category: data['category'] ?? 'Pameran',
              description: data['description'] ?? '',
              date: data['event_date'],
              location: data['location'],
              latitude: data['latitude'],
              longitude: data['longitude'],
              price: data['price'],
              imageUrl: data['image_url'],
              isActive: (data['is_active'] == 1 || data['is_active'] == true),
              eventStartDate: data['event_start_date'],
              eventEndDate: data['event_end_date'],
              openTime: data['open_time'],
              closeTime: data['close_time'],
              regularStart: data['regular_start'],
              regularEnd: data['regular_end'],
              earlyBirdPrice: data['early_bird_price'],
              earlyBirdStart: data['early_bird_start'],
              earlyBirdEnd: data['early_bird_end'],
            );
          } else {
            result = await _adminController.createEvent(
              name: data['title'],
              category: data['category'] ?? 'Pameran',
              description: data['description'] ?? '',
              date: data['event_date'],
              location: data['location'],
              latitude: data['latitude'],
              longitude: data['longitude'],
              price: data['price'],
              imageUrl: data['image_url'],
            );
          }
          if (result.containsKey('error')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal: ${result['error']}'), backgroundColor: Colors.red),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(event != null ? 'Event berhasil diperbarui' : 'Event berhasil ditambahkan'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadEvents();
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteEvent(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Event', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await _adminController.deleteEvent(id);
      if (mounted) {
        final success = result['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Event dihapus' : (result['error'] ?? 'Gagal menghapus event')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadEvents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Kelola Event',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _primary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: _loadEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Tambah Event', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _events.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  color: _primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _events.length,
                    itemBuilder: (_, i) => AdminEventCard(
                      event: _events[i],
                      onEdit: () => _openForm(event: _events[i]),
                      onDelete: () => _deleteEvent(
                        _events[i]['id'] as int,
                        _events[i]['title']?.toString() ?? '',
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarX, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Belum ada event', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tap tombol + untuk menambahkan event baru', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}
