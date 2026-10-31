
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() =>
      _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  String _selectedFilter = 'Semua';

  // DATA CONTOH
  // Nantinya akan diganti dengan data dari database.
  final List<_ParkingHistory> _history = const [
    _ParkingHistory(
      plate: 'BE 1234 XYZ',
      location: 'Parkiran ICT',
      entryTime: '08.15',
      exitTime: '-',
      status: 'Aktif',
    ),
    _ParkingHistory(
      plate: 'BE 5678 ABC',
      location: 'Parkiran PU',
      entryTime: '07.45',
      exitTime: '10.20',
      status: 'Selesai',
    ),
    _ParkingHistory(
      plate: 'BE 9012 DEF',
      location: 'Parkiran ICT',
      entryTime: '09.10',
      exitTime: '-',
      status: 'Aktif',
    ),
    _ParkingHistory(
      plate: 'BE 3456 GHI',
      location: 'Parkiran PU',
      entryTime: '06.55',
      exitTime: '09.30',
      status: 'Selesai',
    ),
    _ParkingHistory(
      plate: 'BE 7890 JKL',
      location: 'Parkiran ICT',
      entryTime: '08.30',
      exitTime: '11.15',
      status: 'Selesai',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _selectedFilter == 'Semua'
        ? _history
        : _history
            .where((item) => item.status == _selectedFilter)
            .toList();

    final activeCount =
        _history.where((item) => item.status == 'Aktif').length;

    final completedCount =
        _history.where((item) => item.status == 'Selesai').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JUDUL
          Text(
            'Riwayat Parkir',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 6),

          Text(
            'Pantau catatan kendaraan masuk dan keluar.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.blueGrey),
          ),

          const SizedBox(height: 22),

          // RINGKASAN TRANSAKSI
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Riwayat',
                  count: _history.length,
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Transaksi Aktif',
                  count: activeCount,
                  icon: Icons.local_parking_rounded,
                  color: AppTheme.slotAvailable,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _SummaryCard(
            title: 'Transaksi Selesai',
            count: completedCount,
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.darkBlue,
          ),

          const SizedBox(height: 26),

          // FILTER
          Text(
            'Daftar Transaksi',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('Semua'),
              _buildFilterChip('Aktif'),
              _buildFilterChip('Selesai'),
            ],
          ),

          const SizedBox(height: 18),

          // DAFTAR RIWAYAT
          if (filteredHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'Belum ada transaksi untuk status ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
            )
          else
            ...filteredHistory.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryCard(item: item),
              ),
            ),

          const SizedBox(height: 16),

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
                    'Data yang ditampilkan masih berupa contoh. '
                    'Riwayat sebenarnya akan diambil dari database '
                    'setelah sistem terhubung.',
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: const Color(0xFFDCEBFF),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.primaryBlue
            : Colors.blueGrey,
        fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryBlue
            : const Color(0xFFDCE6F5),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// MODEL RIWAYAT SEMENTARA
class _ParkingHistory {
  final String plate;
  final String location;
  final String entryTime;
  final String exitTime;
  final String status;

  const _ParkingHistory({
    required this.plate,
    required this.location,
    required this.entryTime,
    required this.exitTime,
    required this.status,
  });
}

// KARTU RINGKASAN
class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 25,
                fontWeight: FontWeight.w700,
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

// KARTU DETAIL TRANSAKSI
class _HistoryCard extends StatelessWidget {
  final _ParkingHistory item;

  const _HistoryCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = item.status == 'Aktif';

    final statusColor = isActive
        ? AppTheme.slotAvailable
        : AppTheme.primaryBlue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    Icons.directions_car_rounded,
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
                        item.plate,
                        style: const TextStyle(
                          color: AppTheme.darkBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.location,
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
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(height: 1),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _TimeInfo(
                    label: 'Waktu Masuk',
                    time: item.entryTime,
                    icon: Icons.login_rounded,
                  ),
                ),
                Expanded(
                  child: _TimeInfo(
                    label: 'Waktu Keluar',
                    time: item.exitTime,
                    icon: Icons.logout_rounded,
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

// INFORMASI WAKTU
class _TimeInfo extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;

  const _TimeInfo({
    required this.label,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.blueGrey,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          time,
          style: const TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
