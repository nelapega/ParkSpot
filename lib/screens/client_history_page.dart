
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ClientHistoryPage extends StatelessWidget {
  const ClientHistoryPage({super.key});

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '-';

    final date = value.toDate();
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return '-';

    final date = value.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour.$minute';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Silakan login untuk melihat riwayat parkir.'),
      );
    }

    final historyStream = FirebaseFirestore.instance
        .collection('parking_transactions')
        .where('userId', isEqualTo: user.uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Riwayat belum dapat dimuat. Periksa koneksi '
                'internet dan Firestore Rules.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final documents = snapshot.data?.docs ?? [];

        documents.sort((a, b) {
          final aTime = a.data()['entryTime'];
          final bTime = b.data()['entryTime'];

          final aDate = aTime is Timestamp
              ? aTime.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          final bDate = bTime is Timestamp
              ? bTime.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Riwayat Parkir',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lihat catatan kendaraan masuk dan keluar.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Parkir',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Riwayat aktivitas kendaraan kamu.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'Aktivitas Terakhir (${documents.length})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkBlue,
              ),
            ),

            const SizedBox(height: 12),

            if (documents.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 46,
                      color: Colors.blueGrey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada riwayat parkir',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Aktivitas parkir kamu akan muncul '
                      'di sini setelah tercatat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            ...documents.map((document) {
              final item = document.data();

              final locationCode =
                  item['locationCode'] as String? ?? '-';

              final location = locationCode == 'ICT'
                  ? 'Parkiran ICT'
                  : locationCode == 'PU'
                      ? 'Parkiran PU'
                      : 'Parkiran $locationCode';

              final plate =
                  item['vehiclePlate'] as String? ?? '-';

              final entryTime = item['entryTime'];
              final exitTime = item['exitTime'];
              final rawStatus =
                  item['status'] as String? ?? 'active';

              final isActive =
                  rawStatus.toLowerCase() == 'active' ||
                  exitTime == null;

              final status = isActive ? 'Masih Parkir' : 'Selesai';

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_parking_rounded,
                              color: AppTheme.primaryBlue,
                              size: 26,
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(entryTime),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.orange.withValues(alpha: 0.12)
                                  : Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.orange.shade800
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car_outlined,
                            size: 20,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plate,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkBlue,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _HistoryTime(
                              label: 'Waktu Masuk',
                              time: _formatTime(entryTime),
                              icon: Icons.login_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          Expanded(
                            child: _HistoryTime(
                              label: 'Waktu Keluar',
                              time: _formatTime(exitTime),
                              icon: Icons.logout_rounded,
                              color: isActive
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'ParkSpot • Smart Parking for Campus',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTime extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _HistoryTime({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
