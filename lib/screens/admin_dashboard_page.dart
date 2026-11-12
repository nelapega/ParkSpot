import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import 'admin_monitoring_page.dart';
import 'admin_history_page.dart';
import 'admin_settings_page.dart';
import 'admin_vehicles_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<String> _titles = const [
    'Dashboard Admin',
    'Monitoring Parkir',
    'Riwayat Parkir',
    'Data Kendaraan',
    'Pengaturan',
  ];

  // =====================================
  // LOGOUT ADMIN
  // =====================================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar Admin'),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun Admin?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal keluar: $e')));
    }
  }

  // =====================================
  // NAVIGASI UTAMA
  // =====================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Keluar Admin',
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),

      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboard(),
            const AdminMonitoringPage(),
            const AdminHistoryPage(),
            const AdminVehiclesPage(),
            const AdminSettingsPage(),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        height: 75,
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_parking_outlined),
            selectedIcon: Icon(Icons.local_parking_rounded),
            label: 'Monitoring',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Kendaraan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  // =====================================
  // 1. DASHBOARD ADMIN REAL-TIME
  // =====================================

  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('parking_locations')
          .snapshots(),
      builder: (context, locationSnapshot) {
        if (locationSnapshot.connectionState == ConnectionState.waiting) {
          return _loadingView();
        }

        if (locationSnapshot.hasError) {
          return _errorView(
            'Gagal mengambil data lokasi parkir.',
            locationSnapshot.error,
          );
        }

        // Ambil data lokasi berdasarkan ID dokumen.
        final locations = {
          for (final doc in locationSnapshot.data?.docs ?? [])
            doc.id: doc.data(),
        };

        final ictData = locations['ICT'];
        final puData = locations['PU'];

        final ictCapacity = _readInt(ictData?['capacity']);

        final ictOccupied = _readInt(ictData?['occupied']);

        final puCapacity = _readInt(puData?['capacity']);

        final puOccupied = _readInt(puData?['occupied']);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('parking_transactions')
              .snapshots(),
          builder: (context, transactionSnapshot) {
            if (transactionSnapshot.connectionState ==
                ConnectionState.waiting) {
              return _loadingView();
            }

            if (transactionSnapshot.hasError) {
              return _errorView(
                'Gagal mengambil data transaksi parkir.',
                transactionSnapshot.error,
              );
            }

            final now = DateTime.now();

            final todayStart = DateTime(now.year, now.month, now.day);

            final tomorrowStart = todayStart.add(const Duration(days: 1));

            int vehiclesEnteredToday = 0;
            int activeTransactions = 0;

            final transactions = transactionSnapshot.data?.docs ?? [];

            for (final doc in transactions) {
              final data = doc.data();

              final entryTime = data['entryTime'];
              final exitTime = data['exitTime'];

              final status = (data['status'] ?? '').toString().toLowerCase();

              // Menghitung kendaraan masuk hari ini.
              if (entryTime is Timestamp) {
                final entryDate = entryTime.toDate();

                if (!entryDate.isBefore(todayStart) &&
                    entryDate.isBefore(tomorrowStart)) {
                  vehiclesEnteredToday++;
                }
              }

              // Menghitung kendaraan yang masih parkir.
              if (status == 'active' && exitTime == null) {
                activeTransactions++;
              }
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('app_settings')
                  .doc('parking')
                  .snapshots(),
              builder: (context, settingsSnapshot) {
                if (settingsSnapshot.hasError) {
                  return _errorView(
                    'Gagal membaca pengaturan aplikasi.',
                    settingsSnapshot.error,
                  );
                }

                final settings = settingsSnapshot.data?.data() ?? {};

                final notificationsEnabled =
                    settings['notificationsEnabled'] as bool? ?? true;

                final fullParkingLimit =
                    settings['fullParkingLimit'] as String? ?? '10%';

                return _buildDashboardContent(
                  ictCapacity: ictCapacity,
                  ictOccupied: ictOccupied,
                  puCapacity: puCapacity,
                  puOccupied: puOccupied,
                  ictExists: ictData != null,
                  puExists: puData != null,
                  vehiclesEnteredToday: vehiclesEnteredToday,
                  activeTransactions: activeTransactions,
                  notificationsEnabled: notificationsEnabled,
                  fullParkingLimit: fullParkingLimit,
                );
              },
            );
          },
        );
      },
    );
  }

  // =====================================
  // ISI DASHBOARD
  // =====================================

  Widget _buildDashboardContent({
    required int ictCapacity,
    required int ictOccupied,
    required int puCapacity,
    required int puOccupied,
    required bool ictExists,
    required bool puExists,
    required int vehiclesEnteredToday,
    required int activeTransactions,
    required bool notificationsEnabled,
    required String fullParkingLimit,
  }) {
    final ictAvailable = _available(ictCapacity, ictOccupied);

    final puAvailable = _available(puCapacity, puOccupied);

    final totalCapacity = ictCapacity + puCapacity;

    final totalOccupied = ictOccupied + puOccupied;

    final totalAvailable = ictAvailable + puAvailable;

    // MENENTUKAN BATAS NOTIFIKASI
    final bool reachesParkingLimit;

    if (ictCapacity <= 0) {
      reachesParkingLimit = false;
    } else if (fullParkingLimit == '5 slot') {
      reachesParkingLimit = ictAvailable <= 5;
    } else if (fullParkingLimit == '5%') {
      reachesParkingLimit = ictOccupied / ictCapacity >= 0.95;
    } else {
      reachesParkingLimit = ictOccupied / ictCapacity >= 0.90;
    }

    final isIctAlmostFull = notificationsEnabled && reachesParkingLimit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 3 : 3;

        const spacing = 10.0;

        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return RefreshIndicator(
          onRefresh: () async {
            // Data diperbarui otomatis melalui snapshots().
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BANNER SAMBUTAN
                _buildWelcomeCard(),

                const SizedBox(height: 20),

                // PERINGATAN PARKIRAN ICT HAMPIR PENUH
                if (isIctAlmostFull) ...[
                  _buildAlmostFullAlert(
                    occupied: ictOccupied,
                    capacity: ictCapacity,
                  ),
                  const SizedBox(height: 24),
                ],

                _sectionHeader(
                  'Ringkasan Parkiran',
                  subtitle: 'Data diperbarui otomatis',
                ),

                const SizedBox(height: 14),

                // KARTU STATISTIK
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _SummaryCard(
                        title: 'Total Slot',
                        value: '$totalCapacity',
                        icon: Icons.local_parking_rounded,
                        color: AppTheme.primaryBlue,
                        background: const Color(0xFFE8F1FF),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _SummaryCard(
                        title: 'Terisi',
                        value: '$totalOccupied',
                        icon: Icons.directions_car_rounded,
                        color: const Color(0xFFDB6B32),
                        background: const Color(0xFFFFF0E7),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _SummaryCard(
                        title: 'Tersedia',
                        value: '$totalAvailable',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF21966D),
                        background: const Color(0xFFE6F7EF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _sectionHeader('Kondisi Per Lokasi', subtitle: 'ICT dan PU'),

                const SizedBox(height: 14),

                _ParkingLocationCard(
                  name: 'Parkiran ICT',
                  subtitle: 'Area parkir gedung ICT',
                  capacity: ictCapacity,
                  occupied: ictOccupied,
                  exists: ictExists,
                  icon: Icons.apartment_rounded,
                ),

                const SizedBox(height: 14),

                _ParkingLocationCard(
                  name: 'Parkiran PU',
                  subtitle: 'Area parkir gedung PU',
                  capacity: puCapacity,
                  occupied: puOccupied,
                  exists: puExists,
                  icon: Icons.business_rounded,
                ),

                const SizedBox(height: 28),

                _sectionHeader(
                  'Aktivitas Hari Ini',
                  subtitle: 'Berdasarkan transaksi tersimpan',
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _ActivitySummaryCard(
                        title: 'Kendaraan Masuk',
                        value: '$vehiclesEnteredToday',
                        subtitle: 'Hari ini',
                        icon: Icons.login_rounded,
                        color: AppTheme.primaryBlue,
                        background: const Color(0xFFE8F1FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActivitySummaryCard(
                        title: 'Transaksi Aktif',
                        value: '$activeTransactions',
                        subtitle: 'Masih parkir',
                        icon: Icons.local_parking_rounded,
                        color: const Color(0xFF21966D),
                        background: const Color(0xFFE6F7EF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // INFORMASI SISTEM
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7E6FC)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Informasi kapasitas parkir berasal dari '
                          'Firestore. Angka aktivitas dihitung dari '
                          'data transaksi yang tersimpan.',
                          style: TextStyle(
                            color: AppTheme.darkBlue,
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================
  // BANNER SAMBUTAN
  // =====================================

  Widget _buildAlmostFullAlert({required int occupied, required int capacity}) {
    final available = (capacity - occupied).clamp(0, capacity).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDCA8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3B5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFB66A00),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Parkiran ICT Hampir Penuh!',
                  style: TextStyle(
                    color: Color(0xFF805000),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Kapasitas parkir telah terisi '
            '${(occupied / capacity * 100).round()}%. '
            'Tersisa $available slot parkir.',
            style: const TextStyle(
              color: Color(0xFF805000),
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              icon: const Icon(Icons.visibility_outlined, size: 17),
              label: const Text('Lihat Monitoring'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB66A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final email = FirebaseAuth.instance.currentUser?.email;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF104B96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang, Admin!',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email ?? 'Petugas keamanan kampus',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Panel Administrasi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.local_parking_rounded,
            color: Colors.white24,
            size: 68,
          ),
        ],
      ),
    );
  }

  // =====================================
  // HEADER SECTION
  // =====================================

  Widget _sectionHeader(String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.darkBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7EF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 7, color: Color(0xFF21966D)),
              SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Color(0xFF21966D),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================
  // LOADING DAN ERROR
  // =====================================

  Widget _loadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Memuat data dashboard...',
            style: TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _errorView(String message, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 45,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Kesalahan tidak diketahui.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================
  // MEMBACA ANGKA DARI FIRESTORE
  // =====================================

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _available(int capacity, int occupied) {
    return (capacity - occupied).clamp(0, capacity).toInt();
  }
}

// =====================================
// KARTU RINGKASAN
// =====================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 13),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// KARTU PARKIRAN ICT DAN PU
// =====================================

class _ParkingLocationCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final int capacity;
  final int occupied;
  final bool exists;
  final IconData icon;

  const _ParkingLocationCard({
    required this.name,
    required this.subtitle,
    required this.capacity,
    required this.occupied,
    required this.exists,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final available = capacity > 0
        ? (capacity - occupied).clamp(0, capacity).toInt()
        : 0;

    final ratio = capacity > 0 ? (occupied / capacity).clamp(0.0, 1.0) : 0.0;

    final almostFull = capacity > 0 && (ratio >= 0.9 || available <= 5);

    final hasData = exists && capacity > 0;

    final statusColor = !hasData
        ? Colors.blueGrey
        : almostFull
        ? Colors.deepOrange
        : const Color(0xFF21966D);

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppTheme.primaryBlue, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.darkBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    !hasData
                        ? 'Belum ada data'
                        : almostFull
                        ? 'Hampir penuh'
                        : 'Normal',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 21),

            Row(
              children: [
                Expanded(
                  child: _SlotNumber(
                    label: 'Terisi',
                    value: occupied,
                    color: const Color(0xFFDB6B32),
                  ),
                ),
                Expanded(
                  child: _SlotNumber(
                    label: 'Tersedia',
                    value: available,
                    color: const Color(0xFF21966D),
                  ),
                ),
                Expanded(
                  child: _SlotNumber(
                    label: 'Kapasitas',
                    value: capacity,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 9,
                backgroundColor: const Color(0xFFEAF0F8),
                valueColor: AlwaysStoppedAnimation<Color>(
                  almostFull ? Colors.deepOrange : AppTheme.primaryBlue,
                ),
              ),
            ),

            const SizedBox(height: 9),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tingkat keterisian',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
                Text(
                  '${(ratio * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// ANGKA SLOT PARKIR
// =====================================

class _SlotNumber extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SlotNumber({
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
          style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          'slot',
          style: TextStyle(color: Colors.blueGrey, fontSize: 10),
        ),
      ],
    );
  }
}

// =====================================
// KARTU AKTIVITAS
// =====================================

class _ActivitySummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _ActivitySummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.darkBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
