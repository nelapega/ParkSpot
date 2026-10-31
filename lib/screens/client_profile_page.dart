
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data contoh sementara
    const String name = 'Pengguna ParkSpot';
    const String category = 'Mahasiswa';
    const String plateNumber = 'BE 1234 AB';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Profil Saya',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Informasi akun dan kendaraan kamu.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 25),

        // KARTU PROFIL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
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
            children: [
              CircleAvatar(
                radius: 43,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person_rounded,
                  size: 52,
                  color: AppTheme.primaryBlue,
                ),
              ),
              SizedBox(height: 14),
              Text(
                name,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Pengguna ParkSpot',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          'Informasi Akun',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkBlue,
          ),
        ),
        const SizedBox(height: 12),

        _ProfileInfo(
          icon: Icons.person_outline_rounded,
          label: 'Nama Lengkap',
          value: name,
        ),
        _ProfileInfo(
          icon: Icons.school_outlined,
          label: 'Kategori Pengguna',
          value: category,
        ),
        _ProfileInfo(
          icon: Icons.directions_car_outlined,
          label: 'Nomor Kendaraan',
          value: plateNumber,
        ),

        const SizedBox(height: 20),

        // TOMBOL KELUAR
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Keluar Akun'),
                    content: const Text(
                      'Apakah kamu yakin ingin keluar dari akun?',
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
                          Navigator.pop(dialogContext);
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: const Text('Keluar'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar Akun'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 20),

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
  }
}

class _ProfileInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryBlue,
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkBlue,
            ),
          ),
        ),
      ),
    );
  }
}
