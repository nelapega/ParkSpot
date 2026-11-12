import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';

class AdminMonitoringPage extends StatelessWidget {
  const AdminMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('parking_locations')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

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
                    'Gagal memuat data parkiran.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Periksa koneksi internet dan aturan akses Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // StreamBuilder akan mencoba membaca ulang
                      // ketika widget dibangun kembali.
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final documents = {
          for (final document in snapshot.data!.docs)
            document.id: document.data(),
        };

        final ictData = _readParkingData(
          documents['ICT'],
          location: 'Parkiran ICT',
        );

        final puData = _readParkingData(
          documents['PU'],
          location: 'Parkiran PU',
        );

        final hasCompleteData =
            ictData != null &&
            puData != null &&
            ictData.capacity > 0 &&
            puData.capacity > 0;

        final totalCapacity = hasCompleteData
            ? ictData.capacity + puData.capacity
            : 0;

        final totalOccupied = hasCompleteData
            ? ictData.occupied + puData.occupied
            : 0;

        final totalAvailable = totalCapacity - totalOccupied;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // JUDUL HALAMAN
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoring Parkir',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppTheme.darkBlue,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pantau kondisi slot parkir ICT dan PU.',
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

              const SizedBox(height: 24),

              // RINGKASAN TOTAL
              _buildTotalSummary(
                hasCompleteData: hasCompleteData,
                totalCapacity: totalCapacity,
                totalOccupied: totalOccupied,
                totalAvailable: totalAvailable,
              ),

              const SizedBox(height: 26),

              // DETAIL ICT
              _sectionTitle('Parkiran ICT'),
              const SizedBox(height: 12),
              _ParkingDetailCard(
                data: ictData,
                fallbackLocation: 'Parkiran ICT',
              ),

              const SizedBox(height: 22),

              // DETAIL PU
              _sectionTitle('Parkiran PU'),
              const SizedBox(height: 12),
              _ParkingDetailCard(data: puData, fallbackLocation: 'Parkiran PU'),

              const SizedBox(height: 22),

              // KETERANGAN STATUS SLOT
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

              // INFORMASI
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
                        'Data monitoring diperbarui secara otomatis '
                        'mengikuti perubahan pada database Firebase. '
                        'Pastikan data ICT dan PU sudah tersedia.',
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
      },
    );
  }

  // RINGKASAN TOTAL PARKIR
  static Widget _buildTotalSummary({
    required bool hasCompleteData,
    required int totalCapacity,
    required int totalOccupied,
    required int totalAvailable,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
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
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            hasCompleteData ? '$totalCapacity Slot' : 'Belum tersedia',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          if (hasCompleteData)
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
            )
          else
            const Text(
              'Data kapasitas ICT dan PU belum lengkap.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
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

// MEMBACA DATA PARKIR DARI FIRESTORE
_ParkingData? _readParkingData(
  Map<String, dynamic>? data, {
  required String location,
}) {
  if (data == null ||
      !data.containsKey('capacity') ||
      !data.containsKey('occupied')) {
    return null;
  }

  final capacity = _toInt(data['capacity']);
  final rawOccupied = _toInt(data['occupied']);

  final occupied = capacity > 0 ? rawOccupied.clamp(0, capacity).toInt() : 0;

  return _ParkingData(
    name: data['name']?.toString() ?? location,
    capacity: capacity,
    occupied: occupied,
  );
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

// MODEL DATA PARKIR
class _ParkingData {
  final String name;
  final int capacity;
  final int occupied;

  const _ParkingData({
    required this.name,
    required this.capacity,
    required this.occupied,
  });
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
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
  final _ParkingData? data;
  final String fallbackLocation;

  const _ParkingDetailCard({
    required this.data,
    required this.fallbackLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Data $fallbackLocation belum ditemukan atau '
                  'belum memiliki field capacity dan occupied.',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final location = data!.name;
    final capacity = data!.capacity;
    final occupied = data!.occupied;

    if (capacity <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Kapasitas $location belum valid. Periksa kembali '
            'nilai capacity di Firestore.',
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ),
      );
    }

    final available = capacity - occupied;
    final percentage = occupied / capacity;

    final isFull = occupied >= capacity;
    final isAlmostFull = percentage >= 0.9;

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

            // JUMLAH SLOT
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
                Container(width: 1, height: 55, color: const Color(0xFFE4EAF2)),
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
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12),
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
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),

            const SizedBox(height: 14),

            // STATUS LOKASI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
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
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
