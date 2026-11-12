import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsLocationService {
  // ==========================================
  // MENGAMBIL POSISI GPS PENGGUNA
  // ==========================================

  Future<Position> getCurrentPosition() async {
    // PEMERIKSAAN KHUSUS ANDROID DAN IOS
    if (!kIsWeb) {
      // Memeriksa apakah GPS aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw StateError('GPS belum aktif. Silakan aktifkan lokasi perangkat.');
      }

      // Memeriksa izin lokasi
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw StateError('Izin lokasi diperlukan untuk melakukan scan QR.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Izin lokasi ditolak permanen. '
          'Silakan aktifkan melalui pengaturan aplikasi.',
        );
      }

      // Memeriksa akurasi khusus Android dan iOS
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final accuracy = await Geolocator.getLocationAccuracy();

        if (accuracy == LocationAccuracyStatus.reduced) {
          throw StateError(
            'Gunakan izin lokasi presisi agar posisi parkir '
            'dapat diperiksa dengan lebih akurat.',
          );
        }
      }
    }

    // MENGAMBIL POSISI GPS
    // Pada Web, browser akan menangani permintaan izin lokasi.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw StateError(
        'GPS membutuhkan waktu terlalu lama. '
        'Silakan coba kembali.',
      );
    }
  }

  // ==========================================
  // MENGHITUNG JARAK DARI LOKASI PARKIR
  // ==========================================

  double calculateDistance({
    required Position currentPosition,
    required double targetLatitude,
    required double targetLongitude,
  }) {
    return Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
  }

  // ==========================================
  // MEMERIKSA RADIUS LOKASI
  // ==========================================

  bool isWithinRadius({required double distance, double radiusInMeters = 50}) {
    return distance <= radiusInMeters;
  }
}
