import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AdminCapacitySettings extends StatelessWidget {
  const AdminCapacitySettings({super.key});

  final String _collectionName = 'parking_locations';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kelola Kapasitas Parkir',
          style: TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Atur jumlah maksimal kendaraan yang dapat '
          'ditampung di setiap lokasi parkir.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.5),
        ),

        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(_collectionName)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorCard('Gagal mengambil data kapasitas parkir.');
            }

            final locations = {
              for (final doc in snapshot.data?.docs ?? []) doc.id: doc.data(),
            };

            final ictData = locations['ICT'];
            final puData = locations['PU'];

            return Column(
              children: [
                _buildLocationCard(
                  context,
                  code: 'ICT',
                  name: 'Parkiran ICT',
                  data: ictData,
                  icon: Icons.apartment_rounded,
                ),

                const SizedBox(height: 12),

                _buildLocationCard(
                  context,
                  code: 'PU',
                  name: 'Parkiran PU',
                  data: puData,
                  icon: Icons.business_rounded,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

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
                  'Perubahan kapasitas hanya dapat dilakukan '
                  'oleh Admin. Kapasitas baru tidak boleh '
                  'lebih kecil daripada jumlah kendaraan '
                  'yang sedang terparkir.',
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
    );
  }

  // ==========================================
  // KARTU LOKASI PARKIR
  // ==========================================

  Widget _buildLocationCard(
    BuildContext context, {
    required String code,
    required String name,
    required Map<String, dynamic>? data,
    required IconData icon,
  }) {
    if (data == null) {
      return _buildErrorCard('Data $name tidak ditemukan.');
    }

    final capacity = _toInt(data['capacity']);
    final occupied = _toInt(data['occupied']);
    final available = (capacity - occupied).clamp(
      0,
      capacity > 0 ? capacity : 0,
    );

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID Lokasi: $code',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Ubah kapasitas',
                  onPressed: capacity > 0
                      ? () => _showEditDialog(
                          context,
                          code: code,
                          name: name,
                          currentCapacity: capacity,
                          currentOccupied: occupied,
                        )
                      : null,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _CapacityInfo(
                    label: 'Kapasitas',
                    value: capacity,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Expanded(
                  child: _CapacityInfo(
                    label: 'Terisi',
                    value: occupied,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _CapacityInfo(
                    label: 'Tersedia',
                    value: available,
                    color: const Color(0xFF21966D),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: capacity > 0
                    ? () => _showEditDialog(
                        context,
                        code: code,
                        name: name,
                        currentCapacity: capacity,
                        currentOccupied: occupied,
                      )
                    : null,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Ubah Kapasitas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOG UBAH KAPASITAS
  // ==========================================

  Future<void> _showEditDialog(
    BuildContext context, {
    required String code,
    required String name,
    required int currentCapacity,
    required int currentOccupied,
  }) async {
    final controller = TextEditingController(text: currentCapacity.toString());

    String? validationError;

    final newCapacity = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text('Ubah Kapasitas $code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kapasitas baru',
                      suffixText: 'slot',
                      prefixIcon: const Icon(Icons.local_parking_rounded),
                      errorText: validationError,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Jumlah kendaraan yang sedang terparkir: '
                    '$currentOccupied kendaraan.',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),

                FilledButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text.trim());

                    if (value == null || value <= 0) {
                      setDialogState(() {
                        validationError = 'Masukkan angka lebih dari 0.';
                      });
                      return;
                    }

                    if (value < currentOccupied) {
                      setDialogState(() {
                        validationError = 'Minimal $currentOccupied slot.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (newCapacity == null || !context.mounted) {
      return;
    }

    // ======================================
    // MENYIMPAN KE FIRESTORE
    // ======================================

    try {
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(code)
          .update({'capacity': newCapacity});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Kapasitas $name berhasil diubah menjadi '
            '$newCapacity slot.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Gagal mengubah kapasitas: $error'),
        ),
      );
    }
  }

  // ==========================================
  // KARTU ERROR
  // ==========================================

  Widget _buildErrorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MEMBACA ANGKA
  // ==========================================

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ==========================================
// INFORMASI KAPASITAS
// ==========================================

class _CapacityInfo extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CapacityInfo({
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
            fontSize: 22,
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
