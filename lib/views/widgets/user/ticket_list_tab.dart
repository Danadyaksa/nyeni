import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/api_config.dart';
import '../../user/ticket_detail_screen.dart';

/// Tab untuk menampilkan list tiket user
class TicketListTab extends StatelessWidget {
  final List<dynamic> tickets;
  final String filterStatus; // 'all', 'active', 'pending', 'history'

  const TicketListTab({
    super.key,
    required this.tickets,
    this.filterStatus = 'all',
  });

  List<dynamic> get _filteredTickets {
    if (filterStatus == 'all') return tickets;
    if (filterStatus == 'active') {
      return tickets.where((t) => t['status'] == 'ACTIVE').toList();
    }
    if (filterStatus == 'pending') {
      return tickets.where((t) => t['status'] == 'PENDING').toList();
    }
    if (filterStatus == 'history') {
      return tickets.where((t) => 
        t['status'] == 'USED' || 
        t['status'] == 'EXPIRED' || 
        t['status'] == 'DECLINED'
      ).toList();
    }
    return tickets;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTickets;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.ticket, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final ticket = filtered[index];
        return _buildTicketCard(context, ticket);
      },
    );
  }

  String _getEmptyMessage() {
    switch (filterStatus) {
      case 'active':
        return 'Belum ada tiket aktif';
      case 'pending':
        return 'Tidak ada tiket menunggu verifikasi';
      case 'history':
        return 'Belum ada riwayat tiket';
      default:
        return 'Belum ada tiket';
    }
  }

  Widget _buildTicketCard(BuildContext context, dynamic ticket) {
    final status = ticket['status']?.toString() ?? '';
    final eventName = ticket['event_name']?.toString() ?? '-';
    final eventDate = ticket['event_date']?.toString() ?? '-';
    final imageUrl = ticket['image_url']?.toString() ?? '';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'ACTIVE':
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle2;
        statusLabel = 'Aktif';
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
        statusLabel = 'Menunggu';
        break;
      case 'USED':
        statusColor = Colors.blue;
        statusIcon = LucideIcons.checkCheck;
        statusLabel = 'Terpakai';
        break;
      case 'EXPIRED':
        statusColor = Colors.grey;
        statusIcon = LucideIcons.calendarX;
        statusLabel = 'Kadaluarsa';
        break;
      case 'DECLINED':
        statusColor = Colors.red;
        statusIcon = LucideIcons.xCircle;
        statusLabel = 'Ditolak';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = LucideIcons.helpCircle;
        statusLabel = status;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketDetailScreen(
              qrData: ticket['qr_code']?.toString() ?? ticket['id'].toString(),
              eventName: ticket['event_name']?.toString() ?? 'Event',
              imageUrl: ticket['image_url']?.toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      ApiConfig.normalizeImageUrl(imageUrl),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            eventDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: Icon(LucideIcons.image, size: 32, color: Colors.grey[400]),
    );
  }
}
