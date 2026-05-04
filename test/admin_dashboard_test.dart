import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyeni_app/views/admin/admin_dashboard_screen.dart';
import 'package:nyeni_app/models/admin_summary.dart';

void main() {
  group('AdminDashboardScreen Tests', () {
    testWidgets('Should display all summary cards', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      // Verify summary cards are displayed
      expect(find.text('Ringkasan'), findsOneWidget);
      expect(find.text('Verifikasi'), findsOneWidget);
      expect(find.text('Tiket'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
    });

    testWidgets('Should display all menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      // Verify menu section
      expect(find.text('Menu Admin'), findsOneWidget);
      expect(find.text('Verifikasi Pembayaran'), findsOneWidget);
      expect(find.text('Kelola Event'), findsOneWidget);
      expect(find.text('Scan QR Tiket'), findsOneWidget);
      expect(find.text('Laporan Revenue'), findsOneWidget);
    });

    testWidgets('Should display bottom navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      // Verify bottom nav items
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.text('EVENTS'), findsOneWidget);
      expect(find.text('SCANNER'), findsOneWidget);
      expect(find.text('FINANCE'), findsOneWidget);
    });

    testWidgets('Should have correct app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.text('Sahara Admin'), findsOneWidget);
    });
  });

  group('AdminSummary Model Tests', () {
    test('Should create AdminSummary from JSON', () {
      final json = {
        'pending_verifications': 5,
        'active_tickets': 58,
        'total_events': 7,
        'total_revenue': 63000.0,
      };

      final summary = AdminSummary.fromJson(json);

      expect(summary.pendingVerifications, 5);
      expect(summary.activeTickets, 58);
      expect(summary.totalEvents, 7);
      expect(summary.totalRevenue, 63000.0);
    });

    test('Should format revenue correctly', () {
      // Test thousands
      final summary1 = AdminSummary(
        pendingVerifications: 0,
        activeTickets: 0,
        totalEvents: 0,
        totalRevenue: 63000,
      );
      expect(summary1.formattedRevenue, 'Rp 63rb');

      // Test millions
      final summary2 = AdminSummary(
        pendingVerifications: 0,
        activeTickets: 0,
        totalEvents: 0,
        totalRevenue: 1500000,
      );
      expect(summary2.formattedRevenue, 'Rp 1.5jt');

      // Test less than thousand
      final summary3 = AdminSummary(
        pendingVerifications: 0,
        activeTickets: 0,
        totalEvents: 0,
        totalRevenue: 500,
      );
      expect(summary3.formattedRevenue, 'Rp 500');
    });

    test('Should convert to JSON', () {
      final summary = AdminSummary(
        pendingVerifications: 5,
        activeTickets: 58,
        totalEvents: 7,
        totalRevenue: 63000.0,
      );

      final json = summary.toJson();

      expect(json['pending_verifications'], 5);
      expect(json['active_tickets'], 58);
      expect(json['total_events'], 7);
      expect(json['total_revenue'], 63000.0);
    });

    test('Should create empty summary', () {
      final summary = AdminSummary.empty();

      expect(summary.pendingVerifications, 0);
      expect(summary.activeTickets, 0);
      expect(summary.totalEvents, 0);
      expect(summary.totalRevenue, 0);
    });
  });
}
