class ParkingLocationPoint {
  final double latitude;
  final double longitude;

  const ParkingLocationPoint({required this.latitude, required this.longitude});
}

class ParkingLocationConfig {
  // Titik koordinat parkiran ICT
  static const ParkingLocationPoint ict = ParkingLocationPoint(
    latitude: -5.381677546936057,
    longitude: 105.25718811092752,
  );

  // Titik koordinat parkiran PU
  static const ParkingLocationPoint pu = ParkingLocationPoint(
    latitude: -5.3841614176093735,
    longitude: 105.25776911222093,
  );

  // Radius awal validasi GPS
  static const double radiusInMeters = 50;

  // Mengambil koordinat berdasarkan kode lokasi
  static ParkingLocationPoint? getLocation(String code) {
    switch (code.toUpperCase()) {
      case 'ICT':
        return ict;
      case 'PU':
        return pu;
      default:
        return null;
    }
  }
}
