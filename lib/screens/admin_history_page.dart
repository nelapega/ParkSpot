import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('parking_transactions')
          .orderBy('entryTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        // ERROR
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 45),
                  const SizedBox(height: 12),
                  const Text(
                    'Gagal memuat riwayat parkir.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Periksa koneksi internet dan izin akses Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }

        // MENGAMBIL DATA FIRESTORE
        final history = snapshot.data!.docs
            .map((document) => _ParkingHistory.fromMap(document.data()))
            .toList();

        // FILTER TRANSAKSI
        final filteredHistory = _selectedFilter == 'Semua'
            ? history
            : history.where((item) => item.status == _selectedFilter).toList();

        // MENGHITUNG RINGKASAN
        final activeCount = history
            .where((item) => item.status == 'Aktif')
            .length;

        final completedCount = history
            .where((item) => item.status == 'Selesai')
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // JUDUL
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Parkir',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppTheme.darkBlue,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pantau catatan kendaraan masuk dan keluar.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.blueGrey),
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
                      color: const Color(0xFFE5F7ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        SizedBox(width: 5),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFF16834A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // RINGKASAN TRANSAKSI
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Riwayat',
                      count: history.length,
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

              // DAFTAR TRANSAKSI
              Text(
                'Daftar Transaksi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              // FILTER
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('Semua'),
                  _buildFilterChip('Aktif'),
                  _buildFilterChip('Selesai'),
                ],
              ),

              const SizedBox(height: 18),

              // DATA RIWAYAT
              if (filteredHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.blueGrey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          history.isEmpty
                              ? 'Belum ada transaksi parkir.'
                              : 'Belum ada transaksi untuk status ini.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      ],
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

              // CATATAN
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Riwayat parkir diambil langsung dari '
                        'database Firebase dan diperbarui '
                        'secara otomatis ketika transaksi berubah.',
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
      },
    );
  }

  // FILTER TRANSAKSI
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
        color: isSelected ? AppTheme.primaryBlue : Colors.blueGrey,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBlue : const Color(0xFFDCE6F5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ==========================================
// MODEL RIWAYAT PARKIR
// ==========================================

class _ParkingHistory {
  final String plate;
  final String location;
  final String entryDate;
  final String entryTime;
  final String exitTime;
  final String status;

  const _ParkingHistory({
    required this.plate,
    required this.location,
    required this.entryDate,
    required this.entryTime,
    required this.exitTime,
    required this.status,
  });

  factory _ParkingHistory.fromMap(Map<String, dynamic> data) {
    final locationCode = (data['locationCode'] ?? '').toString().toUpperCase();

    final rawStatus = (data['status'] ?? '').toString().toLowerCase();

    return _ParkingHistory(
      plate: data['vehiclePlate']?.toString() ?? 'Plat tidak tersedia',

      location: locationCode == 'ICT'
          ? 'Parkiran ICT'
          : locationCode == 'PU'
          ? 'Parkiran PU'
          : 'Lokasi tidak diketahui',

      entryDate: _formatDate(data['entryTime']),

      entryTime: _formatTime(data['entryTime']),

      exitTime: _formatTime(data['exitTime']),

      status: rawStatus == 'active'
          ? 'Aktif'
          : rawStatus == 'completed'
          ? 'Selesai'
          : rawStatus == 'auto_reset'
          ? 'Ditutup Otomatis'
          : 'Lainnya',
    );
  }
}

// ==========================================
// FORMAT TANGGAL DAN WAKTU
// ==========================================

String _formatDate(dynamic value) {
  final date = _toDateTime(value);

  if (date == null) return '-';

  return '${_twoDigits(date.day)}/'
      '${_twoDigits(date.month)}/${date.year}';
}

String _formatTime(dynamic value) {
  final date = _toDateTime(value);

  if (date == null) return '-';

  return '${_twoDigits(date.hour)}:'
      '${_twoDigits(date.minute)}';
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toLocal();
  }

  if (value is DateTime) {
    return value.toLocal();
  }

  return null;
}

String _twoDigits(int number) {
  return number.toString().padLeft(2, '0');
}

// ==========================================
// KARTU RINGKASAN
// ==========================================

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
              style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// KARTU DETAIL TRANSAKSI
// ==========================================

class _HistoryCard extends StatelessWidget {
  final _ParkingHistory item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isActive = item.status == 'Aktif';
    final isAutoReset = item.status == 'Ditutup Otomatis';

    final statusColor = isActive
        ? AppTheme.slotAvailable
        : isAutoReset
        ? AppTheme.primaryBlue
        : AppTheme.warning;

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
                        '${item.location} • ${item.entryDate}',
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

// ==========================================
// INFORMASI WAKTU
// ==========================================

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
            Icon(icon, color: Colors.blueGrey, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
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
