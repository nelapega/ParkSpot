
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mengambil data parkiran ICT dan PU secara realtime.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchParkingLocations() {
    return _db.collection('parking_locations').snapshots();
  }

  // Mengambil data satu lokasi parkir.
  Future<Map<String, dynamic>?> getParkingLocation(
    String locationCode,
  ) async {
    final document = await _db
        .collection('parking_locations')
        .doc(locationCode)
        .get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }
}
