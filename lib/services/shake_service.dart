import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Deteksi shake dari accelerometer.
/// Callback [onShake] dipanggil saat shake terdeteksi,
/// dengan cooldown supaya tidak spam.
class ShakeService {
  static const double _threshold = 22.0;   // m/s² — naikkan threshold biar tidak terlalu sensitif
  static const int _cooldownMs = 3000;      // jeda 3 detik antar shake

  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime(2000);

  void start(void Function() onShake) {
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      // Kurangi gravitasi (~9.8) untuk dapat akselerasi murni
      final accel = (magnitude - 9.8).abs();

      if (accel > _threshold) {
        final now = DateTime.now();
        if (now.difference(_lastShake).inMilliseconds > _cooldownMs) {
          _lastShake = now;
          onShake();
        }
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}
