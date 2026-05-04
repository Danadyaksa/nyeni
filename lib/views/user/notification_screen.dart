import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notifService = NotificationService();
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _notifications = _notifService.getAll();
    });
  }

  Future<void> _markAllRead() async {
    await _notifService.markAllRead();
    _load();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Semua',
          style: GoogleFonts.ebGaramond(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A302A),
          ),
        ),
        content: Text(
          'Yakin hapus semua notifikasi?',
          style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _notifService.clearAll();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EE),
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: GoogleFonts.libreBaskerville(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A302A),
          ),
        ),
        backgroundColor: const Color(0xFFFAFAF9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A302A)),
        actions: [
          if (_notifications.isNotEmpty) ...[
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Tandai Dibaca',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF9A3412),
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
              onPressed: _clearAll,
            ),
          ],
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return _buildNotifCard(notif);
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 64, color: const Color(0xFFD8D0C8)),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: GoogleFonts.manrope(
              color: const Color(0xFF78706A),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi pembayaran & pengingat\ntiket akan muncul di sini',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: const Color(0xFF78706A),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(AppNotification notif) {
    final iconData = _getIcon(notif.type);
    final iconColor = _getColor(notif.type);
    final timeStr = _formatTime(notif.createdAt);

    return GestureDetector(
      onTap: () async {
        await _notifService.markRead(notif.id);
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? const Color(0xFFFAFAF9) : iconColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead ? const Color(0xFFD8D0C8) : iconColor.withOpacity(0.3),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Konten
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.manrope(
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 13,
                            color: const Color(0xFF3A302A),
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF78706A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeStr,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: const Color(0xFF78706A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'payment':
        return LucideIcons.checkCircle2;
      case 'reminder':
        return LucideIcons.calendarClock;
      case 'promo':
        return LucideIcons.megaphone;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'payment':
        return Colors.green;
      case 'reminder':
        return Colors.orange;
      case 'promo':
        return Colors.purple;
      default:
        return const Color(0xFF9A3412);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
