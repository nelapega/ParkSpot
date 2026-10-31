
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admin_monitoring_page.dart';
import 'admin_history_page.dart';
import 'admin_settings_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard Admin',
    'Monitoring Parkir',
    'Riwayat Parkir',
    'Pengaturan',
  ];

  // DATA CONTOH
  // Nanti data ini akan diganti dengan data database.
  static const int ictCapacity = 100;
  static const int ictOccupied = 75;

  static const int puCapacity = 120;
  static const int puOccupied = 72;

  static const int vehiclesEnteredToday = 48;
  static const int activeTransactions = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      // HEADER ATAS TANPA TOMBOL KEMBALI
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              Navigator.of(context).popUntil(
                (route) => route.isFirst,
              );
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),

      // ISI HALAMAN BERDASARKAN NAVBAR
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboard(),
            _buildMonitoring(),
            _buildHistory(),
            _buildSettings(),
          ],
        ),
      ),

      // NAVBAR DI BAWAH
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
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  // =====================================
  // 1. DASHBOARD ADMIN
  // =====================================

  Widget _buildDashboard() {
    final totalCapacity = ictCapacity + puCapacity;
    final totalOccupied = ictOccupied + puOccupied;
    final totalAvailable = totalCapacity - totalOccupied;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Halo, Admin! 👋',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkBlue,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Ringkasan kondisi parkiran kampus.',
            style: TextStyle(
              color: Colors.blueGrey,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          _sectionTitle('Ringkasan Parkiran'),

          const SizedBox(height: 12),

          // TOTAL KAPASITAS, TERISI, DAN TERSEDIA
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Slot',
                  value: '$totalCapacity',
                  icon: Icons.local_parking_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'Terisi',
                  value: '$totalOccupied',
                  icon: Icons.directions_car_rounded,
                  color: AppTheme.slotOccupied,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'Tersedia',
                  value: '$totalAvailable',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.slotAvailable,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          _sectionTitle('Kondisi Per Lokasi'),

          const SizedBox(height: 12),

          _ParkingLocationCard(
            name: 'Parkiran ICT',
            capacity: ictCapacity,
            occupied: ictOccupied,
          ),

          const SizedBox(height: 14),

          _ParkingLocationCard(
            name: 'Parkiran PU',
            capacity: puCapacity,
            occupied: puOccupied,
          ),

          const SizedBox(height: 26),

          _sectionTitle('Aktivitas Hari Ini'),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ActivitySummaryCard(
                  title: 'Kendaraan Masuk',
                  value: '$vehiclesEnteredToday',
                  subtitle: 'Hari ini',
                  icon: Icons.login_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActivitySummaryCard(
                  title: 'Transaksi Aktif',
                  value: '$activeTransactions',
                  subtitle: 'Masih parkir',
                  icon: Icons.local_parking_rounded,
                  color: AppTheme.slotAvailable,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // CATATAN DATA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Informasi kapasitas dan aktivitas parkir '
                    'akan diperbarui dari database setelah '
                    'sistem terhubung.',
                    style: TextStyle(
                      color: AppTheme.darkBlue,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =====================================
  // 2. MONITORING PARKIR
  // =====================================

  Widget _buildMonitoring() {
    return const AdminMonitoringPage();
  }

  // =====================================
  // 3. RIWAYAT PARKIR
  // =====================================

  Widget _buildHistory() {
    return const AdminHistoryPage();
  }

  // =====================================
  // 4. PENGATURAN
  // =====================================

  Widget _buildSettings() {
    return const AdminSettingsPage();
  }

  // =====================================
  // KOMPONEN PENDUKUNG
  // =====================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.darkBlue,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

}

// KARTU RINGKASAN
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 23,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// KARTU DETAIL LOKASI
class _ParkingLocationCard extends StatelessWidget {
  final String name;
  final int capacity;
  final int occupied;

  const _ParkingLocationCard({
    required this.name,
    required this.capacity,
    required this.occupied,
  });

  @override
  Widget build(BuildContext context) {
    final available = capacity - occupied;
    final ratio = occupied / capacity;
    final almostFull = ratio >= 0.9 || available <= 5;

    return Card(
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
                  ),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kapasitas $capacity slot',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                if (almostFull)
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.deepOrange,
                  )
                else
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.slotAvailable,
                  ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _SlotNumber(
                    label: 'Terisi',
                    value: occupied,
                    color: AppTheme.slotOccupied,
                  ),
                ),
                Expanded(
                  child: _SlotNumber(
                    label: 'Tersedia',
                    value: available,
                    color: AppTheme.slotAvailable,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: const Color(0xFFE4ECF8),
                valueColor: AlwaysStoppedAnimation<Color>(
                  almostFull
                      ? AppTheme.warning
                      : AppTheme.primaryBlue,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              almostFull ? 'Parkiran hampir penuh' : 'Kondisi normal',
              style: TextStyle(
                color: almostFull
                    ? Colors.deepOrange
                    : AppTheme.slotAvailable,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// KARTU AKTIVITAS
class _ActivitySummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ActivitySummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.darkBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
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
    );
  }
}
