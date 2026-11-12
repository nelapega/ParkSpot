import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParkingTransactionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ParkingTransactionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  // VALIDASI LOKASI PARKIR
  String _validateLocation(String locationCode) {
    final code = locationCode.trim().toUpperCase();

    if (code != 'ICT' && code != 'PU') {
      throw StateError('Lokasi parkir tidak valid.');
    }

    return code;
  }

  // MEMBACA ANGKA DARI FIRESTORE
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      throw StateError('Data kapasitas parkir tidak valid.');
    }

    return parsed;
  }

  // MENGAMBIL REFERENSI PENGGUNA YANG LOGIN
  DocumentReference<Map<String, dynamic>> _userReference() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Silakan login terlebih dahulu.');
    }

    return _firestore.collection('users').doc(user.uid);
  }

  // ==========================================
  // TRANSAKSI KENDARAAN MASUK
  // ==========================================

  Future<void> enterParking(String locationCode) async {
    final code = _validateLocation(locationCode);
    final userRef = _userReference();

    final transactionRef = _firestore.collection('parking_transactions').doc();

    final locationRef = _firestore.collection('parking_locations').doc(code);

    await _firestore.runTransaction((transaction) async {
      // Membaca data pengguna dan lokasi
      final userSnapshot = await transaction.get(userRef);
      final locationSnapshot = await transaction.get(locationRef);

      if (!userSnapshot.exists) {
        throw StateError('Data profil pengguna tidak ditemukan.');
      }

      if (!locationSnapshot.exists) {
        throw StateError('Data parkiran $code tidak ditemukan.');
      }

      final userData = userSnapshot.data()!;
      final locationData = locationSnapshot.data()!;

      // Memeriksa transaksi aktif sebelumnya
      final activeTransactionId = userData['activeTransactionId'];

      if (activeTransactionId != null &&
          activeTransactionId.toString().isNotEmpty) {
        throw StateError('Kamu masih memiliki transaksi parkir aktif.');
      }

      // Mengambil nomor plat kendaraan
      final vehiclePlate = userData['vehiclePlate']?.toString().trim() ?? '';

      if (vehiclePlate.isEmpty) {
        throw StateError('Nomor plat kendaraan belum tersedia.');
      }

      // Mengambil kapasitas parkir
      final capacity = _toInt(locationData['capacity']);
      final occupied = _toInt(locationData['occupied']);

      if (capacity <= 0 || occupied < 0 || occupied > capacity) {
        throw StateError('Data kapasitas parkir tidak valid.');
      }

      if (occupied >= capacity) {
        throw StateError('Parkiran $code sudah penuh.');
      }

      // Memperbarui jumlah slot
      transaction.update(locationRef, {'occupied': occupied + 1});

      // Menyimpan transaksi aktif pada profil pengguna
      transaction.update(userRef, {
        'activeTransactionId': transactionRef.id,
        'activeLocationCode': code,
      });

      // Membuat riwayat transaksi masuk
      transaction.set(transactionRef, {
        'userId': _auth.currentUser!.uid,
        'vehiclePlate': vehiclePlate,
        'locationCode': code,
        'entryTime': FieldValue.serverTimestamp(),
        'exitTime': null,
        'status': 'active',
      });
    });
  }

  // ==========================================
  // TRANSAKSI KENDARAAN KELUAR
  // ==========================================

  Future<void> exitParking(String locationCode) async {
    final code = _validateLocation(locationCode);
    final userRef = _userReference();

    await _firestore.runTransaction((transaction) async {
      // Membaca data pengguna
      final userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw StateError('Data profil pengguna tidak ditemukan.');
      }

      final userData = userSnapshot.data()!;

      // Memastikan pengguna memiliki transaksi aktif
      final activeId = userData['activeTransactionId']?.toString();

      if (activeId == null || activeId.isEmpty) {
        throw StateError('Kamu belum memiliki parkir aktif.');
      }

      final activeLocation = userData['activeLocationCode']?.toString();

      if (activeLocation != code) {
        throw StateError('QR tidak sesuai dengan lokasi parkir kendaraanmu.');
      }

      final transactionRef = _firestore
          .collection('parking_transactions')
          .doc(activeId);

      final locationRef = _firestore.collection('parking_locations').doc(code);

      // Membaca data transaksi dan lokasi
      final parkingTransactionSnapshot = await transaction.get(transactionRef);

      final locationSnapshot = await transaction.get(locationRef);

      if (!parkingTransactionSnapshot.exists) {
        throw StateError('Transaksi parkir tidak ditemukan.');
      }

      if (!locationSnapshot.exists) {
        throw StateError('Data parkiran $code tidak ditemukan.');
      }

      final parkingData = parkingTransactionSnapshot.data()!;
      final locationData = locationSnapshot.data()!;

      // Memeriksa kepemilikan dan status transaksi
      if (parkingData['userId'] != _auth.currentUser!.uid) {
        throw StateError('Transaksi ini bukan milik akunmu.');
      }

      if (parkingData['status'] != 'active') {
        throw StateError('Transaksi parkir sudah selesai.');
      }

      if (parkingData['locationCode'] != code) {
        throw StateError('Lokasi transaksi tidak sesuai.');
      }

      // Mengambil jumlah slot terisi
      final occupied = _toInt(locationData['occupied']);

      if (occupied <= 0) {
        throw StateError('Jumlah slot parkir tidak valid.');
      }

      // Mengurangi jumlah slot terisi
      transaction.update(locationRef, {'occupied': occupied - 1});

      // Menyelesaikan transaksi parkir
      transaction.update(transactionRef, {
        'exitTime': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Menghapus tanda transaksi aktif dari profil
      transaction.update(userRef, {
        'activeTransactionId': null,
        'activeLocationCode': null,
      });
    });
  }
}
