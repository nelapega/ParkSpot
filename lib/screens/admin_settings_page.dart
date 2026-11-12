import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_saver/file_saver.dart';
import 'admin_capacity_settings.dart';

import '../theme/app_theme.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoResetEnabled = true;

  String _fullParkingLimit = '10%';

  bool _settingsLoading = true;
  String? _settingsError;

  final DocumentReference<Map<String, dynamic>> _settingsRef = FirebaseFirestore
      .instance
      .collection('app_settings')
      .doc('parking');

  // ==========================================
  // DAFTAR QR CODE PARKSPOT
  // ==========================================

  final List<_QrCodeItem> _qrCodes = const [
    _QrCodeItem(
      title: 'ICT Masuk',
      location: 'Parkiran ICT',
      data: 'PARKSPOT|ICT|MASUK',
      fileName: 'QR_ParkSpot_ICT_Masuk',
    ),
    _QrCodeItem(
      title: 'ICT Keluar',
      location: 'Parkiran ICT',
      data: 'PARKSPOT|ICT|KELUAR',
      fileName: 'QR_ParkSpot_ICT_Keluar',
    ),
    _QrCodeItem(
      title: 'PU Masuk',
      location: 'Parkiran PU',
      data: 'PARKSPOT|PU|MASUK',
      fileName: 'QR_ParkSpot_PU_Masuk',
    ),
    _QrCodeItem(
      title: 'PU Keluar',
      location: 'Parkiran PU',
      data: 'PARKSPOT|PU|KELUAR',
      fileName: 'QR_ParkSpot_PU_Keluar',
    ),
  ];

  // ==========================================
  // MEMUAT PENGATURAN FIREBASE
  // ==========================================

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final snapshot = await _settingsRef.get();

      if (!snapshot.exists) {
        await _settingsRef.set({
          'notificationsEnabled': true,
          'autoResetEnabled': true,
          'fullParkingLimit': '10%',
        });
      }

      final refreshedSnapshot = snapshot.exists
          ? snapshot
          : await _settingsRef.get();

      final data = refreshedSnapshot.data() ?? {};

      if (!mounted) return;

      setState(() {
        _notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;

        _autoResetEnabled = data['autoResetEnabled'] as bool? ?? true;

        _fullParkingLimit = data['fullParkingLimit'] as String? ?? '10%';

        _settingsError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _settingsError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _settingsLoading = false;
        });
      }
    }
  }

  // ==========================================
  // MENYIMPAN PENGATURAN FIREBASE
  // ==========================================

  Future<void> _saveSetting(String field, Object value) async {
    try {
      await _settingsRef.update({field: value});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan berhasil disimpan.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pengaturan: $error'),
          backgroundColor: Colors.red,
        ),
      );

      await _loadSettings();
    }
  }

  // ==========================================
  // TAMPILAN HALAMAN
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (_settingsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    if (_settingsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat pengaturan Admin.',
                style: TextStyle(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _settingsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _settingsLoading = true;
                    _settingsError = null;
                  });
                  _loadSettings();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JUDUL
          Text(
            'Pengaturan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.darkBlue,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Atur preferensi dan sistem parkir ParkSpot.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
          ),

          const SizedBox(height: 24),

          // =====================================
          // AKUN ADMIN
          // =====================================
          _sectionTitle('Akun Admin'),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppTheme.primaryBlue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin ParkSpot',
                          style: TextStyle(
                            color: AppTheme.darkBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Petugas keamanan kampus',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppTheme.slotAvailable,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // =====================================
          // NOTIFIKASI
          // =====================================
          _sectionTitle('Notifikasi'),
          const SizedBox(height: 12),

          Card(
            child: SwitchListTile(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });

                _saveSetting('notificationsEnabled', value);
              },
              secondary: const Icon(
                Icons.notifications_active_outlined,
                color: AppTheme.primaryBlue,
                size: 27,
              ),
              title: const Text(
                'Notifikasi Parkiran',
                style: TextStyle(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Peringatan saat parkiran hampir penuh.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
              activeThumbColor: AppTheme.primaryBlue,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.warning,
                        size: 25,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Batas Hampir Penuh',
                          style: TextStyle(
                            color: AppTheme.darkBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Tampilkan peringatan ketika slot tersedia '
                    'tinggal sedikit.',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: _fullParkingLimit,
                    decoration: const InputDecoration(
                      labelText: 'Ambang batas',
                      prefixIcon: Icon(Icons.tune_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '5 slot',
                        child: Text('Tersisa 5 slot'),
                      ),
                      DropdownMenuItem(
                        value: '10%',
                        child: Text('Keterisian 90%'),
                      ),
                      DropdownMenuItem(
                        value: '5%',
                        child: Text('Keterisian 95%'),
                      ),
                    ],
                    onChanged: _notificationsEnabled
                        ? (value) {
                            if (value != null) {
                              setState(() {
                                _fullParkingLimit = value;
                              });

                              _saveSetting('fullParkingLimit', value);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // =====================================
          // KELOLA KAPASITAS PARKIR
          // =====================================

          const AdminCapacitySettings(),

          const SizedBox(height: 26),

          // =====================================
          // KELOLA QR CODE
          // =====================================
          _sectionTitle('Kelola QR Code'),
          const SizedBox(height: 8),

          const Text(
            'Kelola QR untuk kendaraan masuk dan keluar '
            'di area parkir ICT dan PU.',
            style: TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.5),
          ),

          const SizedBox(height: 14),

          ..._qrCodes.map(_buildQrCodeCard),

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
                    'QR Code bersifat statis. Unduh dan cetak '
                    'QR sesuai lokasi, kemudian tempelkan di '
                    'area parkir ICT atau PU.',
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

          const SizedBox(height: 26),

          // =====================================
          // RESET HARIAN
          // =====================================
          _sectionTitle('Reset Harian'),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _autoResetEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoResetEnabled = value;
                    });

                    _saveSetting('autoResetEnabled', value);
                  },
                  secondary: const Icon(
                    Icons.schedule_rounded,
                    color: AppTheme.primaryBlue,
                    size: 27,
                  ),
                  title: const Text(
                    'Reset Otomatis',
                    style: TextStyle(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Tutup transaksi parkir yang tertinggal.',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                  activeThumbColor: AppTheme.primaryBlue,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                const ListTile(
                  leading: Icon(
                    Icons.access_time_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  title: Text(
                    'Waktu Reset',
                    style: TextStyle(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Setiap hari pukul 00.00',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                  trailing: Text(
                    '00.00',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFFB66A00)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reset otomatis harus dijalankan oleh proses '
                    'terjadwal di server. Kendaraan yang mungkin '
                    'tertinggal perlu diperiksa agar status slot '
                    'tetap sesuai kondisi parkir sebenarnya.',
                    style: TextStyle(
                      color: Color(0xFF805000),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // =====================================
          // TENTANG APLIKASI
          // =====================================
          _sectionTitle('Tentang Aplikasi'),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: Image.asset(
                'assets/images/parkspot_logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
              title: const Text(
                'ParkSpot',
                style: TextStyle(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text(
                'Smart Parking for Campus',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
              trailing: const Text(
                'v1.0.0',
                style: TextStyle(color: Colors.blueGrey, fontSize: 11),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'ParkSpot © 2026',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KARTU QR CODE
  // ==========================================

  Widget _buildQrCodeCard(_QrCodeItem qr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 82,
              child: QrImageView(
                data: qr.data,
                version: QrVersions.auto,
                size: 82,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qr.title,
                    style: const TextStyle(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    qr.location,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showQrPreview(qr),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Lihat'),
                      ),
                      TextButton.icon(
                        onPressed: () => _downloadQr(qr),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Unduh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PREVIEW QR CODE
  // ==========================================

  void _showQrPreview(_QrCodeItem qr) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    qr.title,
                    style: const TextStyle(
                      color: AppTheme.darkBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    qr.location,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox.square(
                    dimension: 230,
                    child: QrImageView(
                      data: qr.data,
                      version: QrVersions.auto,
                      size: 230,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SelectableText(
                    qr.data,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Tutup'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _downloadQr(qr),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Unduh PNG'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // DOWNLOAD QR CODE
  // ==========================================

  Future<void> _downloadQr(_QrCodeItem qr) async {
    try {
      final painter = QrPainter(
        data: qr.data,
        version: QrVersions.auto,
        gapless: false,
      );

      final imageData = await painter.toImageData(
        1200,
        format: ui.ImageByteFormat.png,
      );

      if (imageData == null) {
        throw Exception('Gagal membuat gambar QR Code.');
      }

      final pngBytes = imageData.buffer.asUint8List(
        imageData.offsetInBytes,
        imageData.lengthInBytes,
      );

      await FileSaver.instance.saveFile(
        name: qr.fileName,
        bytes: pngBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('${qr.title} berhasil diunduh.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Gagal mengunduh QR: $error'),
        ),
      );
    }
  }

  // ==========================================
  // JUDUL BAGIAN
  // ==========================================

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

// ==========================================
// MODEL QR CODE
// ==========================================

class _QrCodeItem {
  final String title;
  final String location;
  final String data;
  final String fileName;

  const _QrCodeItem({
    required this.title,
    required this.location,
    required this.data,
    required this.fileName,
  });
}
