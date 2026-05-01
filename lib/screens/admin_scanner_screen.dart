import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/admin_service.dart';

class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen> {
  final _adminService = AdminService();
  final MobileScannerController _scannerCtrl = MobileScannerController();

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final ticketId = barcode!.rawValue!;
    setState(() { _isProcessing = true; });

    // Pause scanner sementara
    await _scannerCtrl.stop();

    final result = await _adminService.scanTicket(ticketId);

    _ScanResult scanResult;
    if (result.containsKey('error')) {
      scanResult = _ScanResult(
        isSuccess: false,
        title: 'Tiket Tidak Valid',
        message: result['error'] ?? 'Terjadi kesalahan',
        eventName: result['event_info']?.toString(),
      );
    } else {
      final eventInfo = result['event_info'];
      scanResult = _ScanResult(
        isSuccess: true,
        title: 'Scan Berhasil!',
        message: result['message'] ?? 'Tiket valid, silakan masuk.',
        eventName: eventInfo is Map ? eventInfo['name']?.toString() : null,
        eventDate: eventInfo is Map ? eventInfo['date']?.toString() : null,
      );
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      _showResultDialog(scanResult);
    }
  }

  void _showResultDialog(_ScanResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (result.isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.isSuccess ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                color: result.isSuccess ? Colors.green : Colors.red,
                size: 56,
              ),
            ),
            const SizedBox(height: 16),
            Text(result.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: result.isSuccess ? Colors.green : Colors.red,
                )),
            const SizedBox(height: 8),
            Text(result.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.5)),
            if (result.eventName != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(LucideIcons.ticket, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text(result.eventName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    ]),
                    if (result.eventDate != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(result.eventDate!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Resume scanner untuk scan berikutnya
                  _scannerCtrl.start();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Scan Berikutnya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Tiket', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? LucideIcons.flashlight : LucideIcons.flashlightOff, color: Colors.white),
            onPressed: () {
              _scannerCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: _onDetect,
          ),

          // Overlay dengan viewfinder
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Label atas
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Arahkan kamera ke QR Code tiket',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Memverifikasi tiket...', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),

          // Status bar bawah
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text('Scanner aktif — siap memindai', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OVERLAY PAINTER ─────────────────────────────────────────────────────────

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    const double boxSize = 260;
    final double left = (size.width - boxSize) / 2;
    final double top = (size.height - boxSize) / 2;
    final Rect scanRect = Rect.fromLTWH(left, top, boxSize, boxSize);

    // Gelap di luar kotak
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16))),
      ),
      paint,
    );

    // Border kotak scan
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)), borderPaint);

    // Corner accents
    final cornerPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 28;
    const double r = 16;

    // Top-left
    canvas.drawLine(Offset(left + r, top), Offset(left + r + cornerLen, top), cornerPaint);
    canvas.drawLine(Offset(left, top + r), Offset(left, top + r + cornerLen), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(left + boxSize - r - cornerLen, top), Offset(left + boxSize - r, top), cornerPaint);
    canvas.drawLine(Offset(left + boxSize, top + r), Offset(left + boxSize, top + r + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left + r, top + boxSize), Offset(left + r + cornerLen, top + boxSize), cornerPaint);
    canvas.drawLine(Offset(left, top + boxSize - r - cornerLen), Offset(left, top + boxSize - r), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(left + boxSize - r - cornerLen, top + boxSize), Offset(left + boxSize - r, top + boxSize), cornerPaint);
    canvas.drawLine(Offset(left + boxSize, top + boxSize - r - cornerLen), Offset(left + boxSize, top + boxSize - r), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── DATA CLASS ───────────────────────────────────────────────────────────────

class _ScanResult {
  final bool isSuccess;
  final String title;
  final String message;
  final String? eventName;
  final String? eventDate;

  _ScanResult({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.eventName,
    this.eventDate,
  });
}
