
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminMonitoringPage extends StatelessWidget {
  const AdminMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    const ictCapacity = 100;
    const ictOccupied = 75;
    const puCapacity = 120;
    const puOccupied = 72;

    final totalCapacity = ictCapacity + puCapacity;
    final totalOccupied = ictOccupied + puOccupied;
    final totalAvailable = totalCapacity - totalOccupied;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JUDUL HALAMAN
          Text(
            'Monitoring Parkir',
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
            'Pantau kondisi slot parkir ICT dan PU.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: Colors.blueGrey,
                ),
          ),

          const SizedBox(height: 24),

          // RINGKASAN TOTAL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
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
                const Text(
                  'Total Kapasitas Parkir',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$totalCapacity Slot',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _TotalInfo(
                        label: 'Terisi',
                        value: '$totalOccupied',
                        icon: Icons.directions_car_rounded,
                      ),
                    ),
                    Expanded(
                      child: _TotalInfo(
                        label: 'Tersedia',
                        value: '$totalAvailable',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // DETAIL ICT
          _sectionTitle('Parkiran ICT'),
          const SizedBox(height: 12),
          const _ParkingDetailCard(
            location: 'Parkiran ICT',
            capacity: ictCapacity,
            occupied: ictOccupied,
          ),

          const SizedBox(height: 22),

          // DETAIL PU
          _sectionTitle('Parkiran PU'),
          const SizedBox(height: 12),
          const _ParkingDetailCard(
            location: 'Parkiran PU',
            capacity: puCapacity,
            occupied: puOccupied,
          ),

          const SizedBox(height: 22),

          // KETERANGAN SLOT
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Keterangan Status Slot'),
                  const SizedBox(height: 16),
                  const _LegendItem(
                    color: AppTheme.slotAvailable,
                    label: 'Tersedia',
                    description: 'Slot parkir masih kosong',
                  ),
                  const SizedBox(height: 12),
                  const _LegendItem(
                    color: AppTheme.slotOccupied,
                    label: 'Terisi',
                    description: 'Slot parkir sedang digunakan',
                  ),
                  const SizedBox(height: 12),
                  const _LegendItem(
                    color: AppTheme.warning,
                    label: 'Hampir penuh',
                    description: 'Kapasitas terisi minimal 90%',
                  ),
                ],
              ),
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
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Informasi kapasitas pada halaman ini masih '
                    'berupa data contoh. Data aktual akan '
                    'ditampilkan setelah database terhubung.',
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

  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.darkBlue,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// RINGKASAN TOTAL
class _TotalInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TotalInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// KARTU DETAIL LOKASI
class _ParkingDetailCard extends StatelessWidget {
  final String location;
  final int capacity;
  final int occupied;

  const _ParkingDetailCard({
    required this.location,
    required this.capacity,
    required this.occupied,
  });

  @override
  Widget build(BuildContext context) {
    final available = capacity - occupied;
    final percentage = occupied / capacity;
    final isAlmostFull = percentage >= 0.9;
    final isFull = available <= 0;

    final statusColor = isFull
        ? AppTheme.slotOccupied
        : isAlmostFull
            ? AppTheme.warning
            : AppTheme.slotAvailable;

    final statusText = isFull
        ? 'Parkiran Penuh'
        : isAlmostFull
            ? 'Hampir Penuh'
            : 'Kondisi Normal';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NAMA LOKASI
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: AppTheme.primaryBlue,
                    size: 27,
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
                        'Kapasitas $capacity slot',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ANGKA TERISI DAN TERSEDIA
            Row(
              children: [
                Expanded(
                  child: _SlotInfo(
                    label: 'Slot Terisi',
                    value: occupied,
                    color: AppTheme.slotOccupied,
                    icon: Icons.directions_car_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 55,
                  color: const Color(0xFFE4EAF2),
                ),
                Expanded(
                  child: _SlotInfo(
                    label: 'Slot Tersedia',
                    value: available,
                    color: AppTheme.slotAvailable,
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // PERSENTASE KETERISIAN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tingkat Keterisian',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${(percentage * 100).round()}%',
                  style: const TextStyle(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: 9,
                backgroundColor: const Color(0xFFE4ECF8),
                valueColor: AlwaysStoppedAnimation<Color>(
                  statusColor,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // STATUS LOKASI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isFull
                        ? Icons.cancel_outlined
                        : isAlmostFull
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                    color: statusColor,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// INFORMASI SETIAP STATUS SLOT
class _SlotInfo extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _SlotInfo({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 5),
              Expanded(
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
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// LEGENDA
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 13,
          height: 13,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
