
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() =>
      _AdminSettingsPageState();
}

class _AdminSettingsPageState
    extends State<AdminSettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoResetEnabled = true;

  String _fullParkingLimit = '10%';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JUDUL HALAMAN
          Text(
            'Pengaturan',
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
            'Atur preferensi dan sistem parkir ParkSpot.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: Colors.blueGrey,
                ),
          ),

          const SizedBox(height: 24),

          // INFORMASI ADMIN
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

          // NOTIFIKASI
          _sectionTitle('Notifikasi'),

          const SizedBox(height: 12),

          Card(
            child: SwitchListTile(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
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
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                ),
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
                      prefixIcon: Icon(
                        Icons.tune_rounded,
                      ),
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
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // RESET OTOMATIS
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
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                  activeThumbColor: AppTheme.primaryBlue,
                ),

                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),

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
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
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
                Icon(
                  Icons.info_outline,
                  color: Color(0xFFB66A00),
                ),
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

          // INFORMASI APLIKASI
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
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                ),
              ),
              trailing: const Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 11,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'ParkSpot © 2026',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: Colors.blueGrey,
                  ),
            ),
          ),
        ],
      ),
    );
  }

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
