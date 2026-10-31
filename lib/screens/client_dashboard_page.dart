
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import 'client_history_page.dart';
import 'client_profile_page.dart';
import 'client_scan_qr_page.dart';
import 'client_parking_detail_page.dart';

class ClientDashboardPage extends StatefulWidget {
  const ClientDashboardPage({super.key});

  @override
  State<ClientDashboardPage> createState() =>
      _ClientDashboardPageState();
}

class _ClientDashboardPageState
    extends State<ClientDashboardPage> {
  int _selectedIndex = 0;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchLocation(
    String locationCode,
  ) {
    return _db
        .collection('parking_locations')
        .doc(locationCode)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Beranda',
      'Riwayat Parkir',
      'Scan QR Parkir',
      'Profil Saya',
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/images/parkspot_logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              _selectedIndex == 0
                  ? 'ParkSpot'
                  : titles[_selectedIndex],
              style: const TextStyle(
                color: AppTheme.darkBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: _showParkingNotifications,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHome(),
            const ClientHistoryPage(),
            const ClientScanQRPage(),
            const ClientProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE3EDFF),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // MEMBACA ANGKA DARI FIRESTORE
  int _readNumber(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toInt();
    return 0;
  }

  Widget _buildParkingStream({
    required String locationCode,
    required String fallbackName,
  }) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _watchLocation(locationCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _messageCard(
            'Gagal memuat $fallbackName. Periksa koneksi internet dan Firestore Rules.',
            isError: true,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _messageCard(
            'Data $fallbackName belum ditemukan di Firestore.',
            isError: true,
          );
        }

        final data = snapshot.data!.data()!;
        final name = data['name'] as String? ?? fallbackName;
        final capacity = _readNumber(data, 'capacity');
        final occupied = _readNumber(data, 'occupied');

        if (capacity <= 0 || occupied < 0) {
          return _messageCard(
            'Data kapasitas $fallbackName tidak valid.',
            isError: true,
          );
        }

        final safeOccupied = occupied.clamp(0, capacity);

        return _ParkingCard(
          location: name,
          capacity: capacity,
          occupied: safeOccupied,
        );
      },
    );
  }

  Widget _messageCard(String message, {bool isError = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? Colors.red : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // NOTIFIKASI BERDASARKAN DATA FIRESTORE
  void _showParkingNotifications() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(width: 10),
              Expanded(child: Text('Informasi Parkir')),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNotificationStream(
                    'ICT',
                    'Parkiran ICT',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationStream(
                    'PU',
                    'Parkiran PU',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationStream(
    String locationCode,
    String fallbackName,
  ) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _watchLocation(locationCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Gagal memuat $fallbackName.');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('$fallbackName belum tersedia.');
        }

        final data = snapshot.data!.data()!;
        final name = data['name'] as String? ?? fallbackName;
        final capacity = _readNumber(data, 'capacity');
        final occupied = _readNumber(data, 'occupied');

        if (capacity <= 0 || occupied < 0) {
          return Text('Data $name tidak valid.');
        }

        final safeOccupied = occupied.clamp(0, capacity);
        final available = capacity - safeOccupied;
        final ratio = safeOccupied / capacity;

        final status = available == 0
            ? 'PENUH'
            : ratio >= 0.8
                ? 'HAMPIR PENUH'
                : 'MASIH TERSEDIA';

        final color = available == 0
            ? AppTheme.slotOccupied
            : ratio >= 0.8
                ? AppTheme.warning
                : AppTheme.slotAvailable;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$available slot tersedia dari $capacity slot.',
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // BERANDA CLIENT
  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat Datang! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Cek ketersediaan parkir sebelum berangkat.',
            style: TextStyle(
              color: Colors.blueGrey,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Ketersediaan Parkir',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 14),

          _buildParkingStream(
            locationCode: 'ICT',
            fallbackName: 'Parkiran ICT',
          ),

          const SizedBox(height: 14),

          _buildParkingStream(
            locationCode: 'PU',
            fallbackName: 'Parkiran PU',
          ),

          const SizedBox(height: 22),

          // KARTU SCAN QR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1976D2),
                  Color(0xFF1565C0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 38,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scan QR Parkir',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Catat kendaraan masuk dan keluar '
                  'dengan memindai QR di area parkir.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                    child: const Text('Mulai Scan'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const Center(
            child: Text(
              'ParkSpot • Smart Parking for Campus',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// KARTU KETERSEDIAAN PARKIR
class _ParkingCard extends StatelessWidget {
  final String location;
  final int capacity;
  final int occupied;

  const _ParkingCard({
    required this.location,
    required this.capacity,
    required this.occupied,
  });

  @override
  Widget build(BuildContext context) {
    final safeCapacity = capacity > 0 ? capacity : 1;
    final safeOccupied = occupied.clamp(0, safeCapacity);
    final available = safeCapacity - safeOccupied;
    final ratio = safeOccupied / safeCapacity;

    final full = available == 0;
    final almostFull = !full &&
        (ratio >= 0.9 || available <= 5);

    final statusColor = full
        ? AppTheme.slotOccupied
        : almostFull
            ? AppTheme.warning
            : AppTheme.slotAvailable;

    final statusText = full
        ? 'Penuh'
        : almostFull
            ? 'Hampir Penuh'
            : 'Tersedia';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParkingDetailPage(
                location: location,
                capacity: safeCapacity,
                occupied: safeOccupied,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppTheme.primaryBlue,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(
                            color: AppTheme.darkBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kapasitas $safeCapacity slot',
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _SlotInfo(
                      label: 'Tersedia',
                      value: available,
                      color: AppTheme.slotAvailable,
                    ),
                  ),
                  Expanded(
                    child: _SlotInfo(
                      label: 'Terisi',
                      value: safeOccupied,
                      color: AppTheme.slotOccupied,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE4ECF8),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    full || almostFull
                        ? statusColor
                        : AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(ratio * 100).round()}% kapasitas terisi',
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotInfo extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SlotInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$value slot',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
