
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _hideCode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    // Sementara untuk menguji navigasi.
    // Validasi akun admin dengan database akan dibuat nanti.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminDashboardPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Login Admin'),
        backgroundColor: AppTheme.background,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Logo ParkSpot
                  Image.asset(
                    'assets/images/parkspot_logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Login Admin',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: AppTheme.darkBlue,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Masuk untuk memantau kondisi parkiran kampus.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Colors.blueGrey,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 26),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Admin',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppTheme.darkBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 22),

                            const Text(
                              'Nama Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _nameController,
                              textCapitalization:
                                  TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan nama admin',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Nama admin wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Kode Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _codeController,
                              obscureText: _hideCode,
                              decoration: InputDecoration(
                                hintText: 'Masukkan kode admin',
                                prefixIcon:
                                    const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _hideCode = !_hideCode;
                                    });
                                  },
                                  icon: Icon(
                                    _hideCode
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Kode admin wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 26),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _login,
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Masuk'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Center(
                              child: Text(
                                'Akses khusus admin dan petugas keamanan.',
                                textAlign: TextAlign.center,
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

                  const SizedBox(height: 22),
                  Text(
                    'ParkSpot • Smart Parking for Campus',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.blueGrey),
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
