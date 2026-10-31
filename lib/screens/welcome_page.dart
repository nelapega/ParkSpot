
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'client_login_page.dart';
import 'admin_login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo dan identitas aplikasi
                  Center(
                    child: Column(
                      children: [                       
                        Image.asset(
                          'assets/images/parkspot_logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ParkSpot',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppTheme.darkBlue,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart Parking for Campus',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.blueGrey,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Judul halaman
                  Text(
                    'Parkir Lebih Mudah',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: AppTheme.darkBlue,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Cek ketersediaan parkir sebelum berangkat '
                    'ke kampus. Temukan slot parkir ICT dan PU '
                    'dengan lebih praktis.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Colors.blueGrey,
                          height: 1.7,
                        ),
                  ),

                  const SizedBox(height: 28),

                  // Pilihan Client
                  _WelcomeModeCard(
                    icon: Icons.person_rounded,
                    title: 'Client',
                    description:
                        'Mahasiswa dan dosen dapat melihat slot, '
                        'scan QR, dan melihat riwayat parkir.',
                    buttonLabel: 'Masuk sebagai Client',
                    isPrimary: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ClientLoginPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Pilihan Admin
                  _WelcomeModeCard(
                    icon: Icons.shield_rounded,
                    title: 'Admin / Satpam',
                    description:
                        'Pantau kondisi parkiran ICT dan PU '
                        'serta aktivitas kendaraan.',
                    buttonLabel: 'Masuk sebagai Admin',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminLoginPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

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
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _WelcomeModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardWhite,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE7EEF8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryBlue,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: AppTheme.darkBlue,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Colors.blueGrey,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: isPrimary
                  ? FilledButton(
                      onPressed: onPressed,
                      child: Text(buttonLabel),
                    )
                  : OutlinedButton(
                      onPressed: onPressed,
                      child: Text(buttonLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
