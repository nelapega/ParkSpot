
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ParkingDetailPage extends StatelessWidget {
  final String location;
  final int capacity;
  final int occupied;

  const ParkingDetailPage({
    super.key,
    required this.location,
    required this.capacity,
    required this.occupied,
  });

  @override
  Widget build(BuildContext context) {
    final available = capacity - occupied;
    final ratio = capacity > 0 ? occupied / capacity : 0.0;
    final isAlmostFull = ratio >= 0.9 || available <= 5;

    final statusColor = isAlmostFull
        ? AppTheme.warning
        : AppTheme.slotAvailable;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkBlue,
        title: const Text(
          'Detail Parkiran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.local_parking_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Informasi Ketersediaan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              location,
              style: const TextStyle(
                color: AppTheme.darkBlue,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAlmostFull ? 'Hampir Penuh' : 'Masih Tersedia',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Ringkasan Slot Parkir',
              style: TextStyle(
                color: AppTheme.darkBlue,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _DetailStatCard(
                    title: 'Total Slot',
                    value: capacity,
                    icon: Icons.local_parking_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailStatCard(
                    title: 'Slot Terisi',
                    value: occupied,
                    icon: Icons.directions_car_rounded,
                    color: AppTheme.slotOccupied,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _DetailStatCard(
              title: 'Slot Tersedia',
              value: available,
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.slotAvailable,
            ),

            const SizedBox(height: 26),

            const Text(
              'Persentase Keterisian',
              style: TextStyle(
                color: AppTheme.darkBlue,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kapasitas terpakai',
                          style: TextStyle(
                            color: Colors.blueGrey,
                          ),
                        ),
                        Text(
                          '${(ratio * 100).round()}%',
                          style: const TextStyle(
                            color: AppTheme.darkBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor:
                            const Color(0xFFE4ECF8),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$occupied dari $capacity slot sedang terisi.',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Informasi ini masih menggunakan data contoh '
              'dan belum diperbarui secara langsung dari database.',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _DetailStatCard({
    required this.title,
    required this.value,
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
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 12),
            Text(
              '$value slot',
              style: TextStyle(
                color: color,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}