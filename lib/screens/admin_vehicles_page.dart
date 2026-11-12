import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../services/stnk_storage_service.dart';

class AdminVehiclesPage extends StatefulWidget {
  const AdminVehiclesPage({super.key});

  @override
  State<AdminVehiclesPage> createState() => _AdminVehiclesPageState();
}

class _AdminVehiclesPageState extends State<AdminVehiclesPage> {
  final TextEditingController _searchController = TextEditingController();

  final StnkStorageService _stnkService = StnkStorageService();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mengambil dan menampilkan foto STNK melalui Edge Function.
  Future<void> _showStnk(String path) async {
    try {
      final signedUrl = await _stnkService.getStnkSignedUrl(path);

      if (!mounted) return;

      final screenSize = MediaQuery.of(context).size;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Foto STNK Pengguna',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(
                    width: screenSize.width * 0.8,
                    height: screenSize.height * 0.65,
                    child: InteractiveViewer(
                      child: Image.network(
                        signedUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stack) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 45,
                                  color: Colors.blueGrey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Foto STNK gagal ditampilkan.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Dokumen kendaraan bersifat privat.',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka STNK: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header dan pencarian.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Kendaraan Pengguna',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kelola informasi kendaraan dan dokumen STNK.',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama atau nomor plat...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.blueGrey.shade100),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.blueGrey.shade100),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Daftar pengguna dari Firestore.
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 42,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Gagal memuat data pengguna.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final documents = snapshot.data?.docs.toList() ?? [];

              // Mengurutkan berdasarkan nama.
              documents.sort((a, b) {
                final nameA = (a.data()['name'] ?? '').toString();
                final nameB = (b.data()['name'] ?? '').toString();

                return nameA.compareTo(nameB);
              });

              // Filter pencarian.
              final filteredDocuments = documents.where((document) {
                final data = document.data();

                final name = (data['name'] ?? '').toString().toLowerCase();
                final plate = (data['vehiclePlate'] ?? '')
                    .toString()
                    .toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();

                return name.contains(_searchQuery) ||
                    plate.contains(_searchQuery) ||
                    email.contains(_searchQuery);
              }).toList();

              if (documents.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada data kendaraan pengguna.',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                );
              }

              if (filteredDocuments.isEmpty) {
                return const Center(
                  child: Text(
                    'Pengguna tidak ditemukan.',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: filteredDocuments.length,
                itemBuilder: (context, index) {
                  final document = filteredDocuments[index];
                  final data = document.data();

                  final name = data['name']?.toString() ?? '-';
                  final email = data['email']?.toString() ?? '-';
                  final category = data['category']?.toString() ?? '-';
                  final plate = data['vehiclePlate']?.toString() ?? '-';

                  final stnkPath = data['stnkPhotoPath']?.toString();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
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
                                child: const Icon(
                                  Icons.person_outline,
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
                                      name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.darkBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 25),

                          _detailRow(Icons.email_outlined, 'Email', email),

                          const SizedBox(height: 12),

                          _detailRow(
                            Icons.directions_car_outlined,
                            'Nomor Plat',
                            plate,
                          ),

                          const SizedBox(height: 16),

                          if (stnkPath != null && stnkPath.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showStnk(stnkPath),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Lihat STNK'),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4E5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Foto STNK belum diunggah.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF805000),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
