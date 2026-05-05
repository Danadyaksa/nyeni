import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'auth_service.dart';

/// Model notifikasi yang disimpan di Hive
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;
  final String type; // 'payment', 'reminder', 'promo'

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'type': type,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        isRead: json['isRead'] ?? false,
        type: json['type'] ?? 'promo',
      );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const String _hiveBoxName = 'notifications';
  static const String _hiveKey = 'notif_list';

  // ─── INIT ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Minta permission Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Buka Hive box untuk notifikasi
    if (!Hive.isBoxOpen(_hiveBoxName)) {
      await Hive.openBox(_hiveBoxName);
    }
  }

  // ─── PUSH NOTIF KE NOTIF BAR ──────────────────────────────────────────────

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'nyeni_general',
    String channelName = 'Nyeni Notifikasi',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  // ─── SIMPAN KE HIVE ───────────────────────────────────────────────────────

  Future<void> _saveToHive(AppNotification notif) async {
    final box = Hive.box(_hiveBoxName);
    final List<dynamic> raw = box.get(_hiveKey, defaultValue: []);
    final List<Map<String, dynamic>> list =
        raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Hindari duplikat berdasarkan id
    list.removeWhere((n) => n['id'] == notif.id);
    list.insert(0, notif.toJson()); // terbaru di atas

    // Simpan max 50 notifikasi
    if (list.length > 50) list.removeRange(50, list.length);

    await box.put(_hiveKey, list);
  }

  // ─── AMBIL SEMUA NOTIFIKASI ───────────────────────────────────────────────

  List<AppNotification> getAll() {
    if (!Hive.isBoxOpen(_hiveBoxName)) return [];
    final box = Hive.box(_hiveBoxName);
    final List<dynamic> raw = box.get(_hiveKey, defaultValue: []);
    return raw
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  int getUnreadCount() => getAll().where((n) => !n.isRead).length;

  Future<void> markAllRead() async {
    final box = Hive.box(_hiveBoxName);
    final List<dynamic> raw = box.get(_hiveKey, defaultValue: []);
    final updated = raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      m['isRead'] = true;
      return m;
    }).toList();
    await box.put(_hiveKey, updated);
  }

  Future<void> markRead(String id) async {
    final box = Hive.box(_hiveBoxName);
    final List<dynamic> raw = box.get(_hiveKey, defaultValue: []);
    final updated = raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['id'] == id) m['isRead'] = true;
      return m;
    }).toList();
    await box.put(_hiveKey, updated);
  }

  Future<void> clearAll() async {
    final box = Hive.box(_hiveBoxName);
    await box.put(_hiveKey, []);
  }

  // ─── NOTIFIKASI PEMBAYARAN DITERIMA ──────────────────────────────────────

  Future<void> notifyPaymentAccepted({
    required String eventName,
    required int ticketCount,
  }) async {
    final title = '✅ Pembayaran Diterima!';
    final body = ticketCount > 1
        ? 'Yeay! $ticketCount tiket "$eventName" kamu sudah aktif. Cek di tab Profil ya!'
        : 'Yeay! Tiket "$eventName" kamu sudah aktif. Cek di tab Profil ya!';

    final notif = AppNotification(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      type: 'payment',
    );

    await _showNotification(
      id: 1001,
      title: title,
      body: body,
      channelId: 'nyeni_payment',
      channelName: 'Pembayaran Tiket',
    );
    await _saveToHive(notif);
  }

  // ─── NOTIFIKASI PEMBAYARAN DITOLAK ────────────────────────────────────────

  Future<void> notifyPaymentDeclined({
    required String eventName,
    required int ticketCount,
  }) async {
    final title = '❌ Pembayaran Ditolak';
    final body = ticketCount > 1
        ? 'Maaf, pembayaran untuk $ticketCount tiket "$eventName" ditolak oleh admin. Silakan hubungi admin untuk info lebih lanjut.'
        : 'Maaf, pembayaran untuk tiket "$eventName" ditolak oleh admin. Silakan hubungi admin untuk info lebih lanjut.';

    final notif = AppNotification(
      id: 'payment_declined_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      type: 'payment',
    );

    await _showNotification(
      id: 1002,
      title: title,
      body: body,
      channelId: 'nyeni_payment',
      channelName: 'Pembayaran Tiket',
    );
    await _saveToHive(notif);
  }

  // ─── NOTIFIKASI REMINDER TIKET AKTIF (H-7 sampai H-1 sebelum event MULAI) ───

  Future<void> checkAndSendTicketReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_data');
    if (userString == null) return;

    final userData = jsonDecode(userString);
    final userId = userData['id']?.toString();
    if (userId == null) return;

    try {
      final tickets = await AuthService().getMyTickets(userId);
      final now = DateTime.now();

      for (final ticket in tickets) {
        if (ticket['status'] != 'ACTIVE') continue;

        final eventName = ticket['event_name']?.toString() ?? '';
        final eventDateStr = ticket['event_date']?.toString() ?? '';

        // Parse tanggal event (bisa single date atau range)
        DateTime? eventStartDate = _parseEventStartDate(eventDateStr);
        if (eventStartDate == null) continue;

        final daysUntilStart = eventStartDate.difference(now).inDays;

        // Kirim reminder H-7 sampai H-1 sebelum event MULAI
        if (daysUntilStart >= 1 && daysUntilStart <= 7) {
          final notifId = 'reminder_${ticket['id']}_$daysUntilStart';

          // Cek apakah notif ini sudah pernah dikirim hari ini
          final sentKey = 'sent_$notifId';
          final lastSent = prefs.getString(sentKey);
          final todayStr = '${now.year}-${now.month}-${now.day}';
          if (lastSent == todayStr) continue;

          final title = '🎭 Jangan Lupa Hadir!';
          final body = daysUntilStart == 1
              ? 'Besok "$eventName" akan dimulai! Jangan sampai kelewatan ya!'
              : '"$eventName" akan dimulai $daysUntilStart hari lagi. Siap-siap ya!';

          final notif = AppNotification(
            id: notifId,
            title: title,
            body: body,
            createdAt: DateTime.now(),
            type: 'reminder',
          );

          await _showNotification(
            id: 2000 + daysUntilStart,
            title: title,
            body: body,
            channelId: 'nyeni_reminder',
            channelName: 'Pengingat Tiket',
          );
          await _saveToHive(notif);
          await prefs.setString(sentKey, todayStr);
        }
      }
    } catch (e) {
      debugPrint('Error check ticket reminders: $e');
    }
  }

  // ─── CEK SEMUA NOTIFIKASI (dipanggil saat app dibuka / foreground) ────────

  Future<void> runDailyChecks() async {
    await checkAndSendTicketReminders();
  }

  // ─── HELPER: parse tanggal MULAI event dari berbagai format ──────────────

  DateTime? _parseEventStartDate(String raw) {
    // Format ISO: "2026-06-22"
    try {
      return DateTime.parse(raw);
    } catch (_) {}

    // Format "22 Jun 2026"
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'jun': 6,
      'jul': 7, 'agu': 8, 'sep': 9, 'okt': 10, 'nov': 11, 'des': 12,
    };
    final parts = raw.toLowerCase().split(RegExp(r'[\s\-]+'));
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]);
      final month = months[parts[1].substring(0, 3)];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // Format range "25 Mei - 25 Juli 2026" → ambil tanggal AWAL (bukan akhir)
    if (raw.contains('-')) {
      final startPart = raw.split('-').first.trim();
      // Kalau start part tidak punya tahun, ambil dari end part
      if (!startPart.contains('2')) {
        final endPart = raw.split('-').last.trim();
        final yearMatch = RegExp(r'20\d{2}').firstMatch(endPart);
        if (yearMatch != null) {
          final year = yearMatch.group(0);
          return _parseEventStartDate('$startPart $year');
        }
      }
      return _parseEventStartDate(startPart);
    }

    return null;
  }
}
