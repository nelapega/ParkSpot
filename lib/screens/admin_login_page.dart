import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  // UID Admin yang telah didaftarkan di Supabase Secrets.
  static const String _authorizedAdminUid = '6UXQTgiskmNdYvK8efGYtmS78Ou2';

  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Proses login Admin menggunakan Firebase Authentication.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Akun tidak ditemukan.');
      }

      // Memeriksa UID Admin.
      if (user.uid != _authorizedAdminUid) {
        await _authService.logout();

        throw Exception('Akun ini tidak memiliki akses Admin ParkSpot.');
      }

      if (!mounted) return;

      // Login berhasil, buka Dashboard Admin.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          message = 'Email atau password salah.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
          break;
        case 'network-request-failed':
          message = 'Periksa koneksi internet kamu.';
          break;
        default:
          message = 'Login gagal. Silakan periksa kembali akun kamu.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  // Logo ParkSpot.
                  Image.asset(
                    'assets/images/parkspot_logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Login Admin',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Masuk untuk memantau kondisi '
                    'parkiran kampus.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppTheme.darkBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),

                            const SizedBox(height: 22),

                            const Text(
                              'Email Admin',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan email admin',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Email wajib diisi.';
                                }

                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                                  return 'Format email tidak valid.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Password',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                hintText: 'Masukkan password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _hidePassword = !_hidePassword;
                                          });
                                        },
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password wajib diisi.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 26),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _login,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: Text(
                                  _isLoading ? 'Memeriksa akun...' : 'Masuk',
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Center(
                              child: Text(
                                'Akses khusus admin dan petugas '
                                'keamanan kampus.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.blueGrey),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
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
