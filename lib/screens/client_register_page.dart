
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ClientRegisterPage extends StatefulWidget {
  const ClientRegisterPage({super.key});

  @override
  State<ClientRegisterPage> createState() =>
      _ClientRegisterPageState();
}

class _ClientRegisterPageState extends State<ClientRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  String _role = 'Mahasiswa';
  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    User? createdUser;

    try {
      final credential = await _authService.register(
        email: _emailController.text,
        password: _passwordController.text,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('Akun gagal dibuat.');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
        'uid': createdUser.uid,
        'name': _nameController.text.trim(),
        'vehiclePlate':
            _plateController.text.trim().toUpperCase(),
        'category': _role,
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Silakan login.'),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email ini sudah terdaftar.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
          break;
        case 'network-request-failed':
          message = 'Periksa koneksi internet kamu.';
          break;
        default:
          message = 'Pendaftaran gagal. Silakan coba lagi.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      // Jika profil gagal disimpan setelah akun Auth dibuat,
      // hapus akun Auth tersebut agar tidak meninggalkan
      // akun yang pendaftarannya belum lengkap.
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Penghapusan dapat gagal jika sesi sudah tidak valid.
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pendaftaran belum berhasil disimpan. '
            'Periksa koneksi dan aturan Firestore.',
          ),
        ),
      );
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
        title: const Text('Registrasi Client'),
        backgroundColor: AppTheme.background,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/parkspot_logo.png',
                      width: 82,
                      height: 82,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Buat Akun ParkSpot',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkBlue,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daftarkan data dirimu untuk menggunakan '
                    'layanan parkir kampus dengan lebih mudah.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Colors.blueGrey,
                          height: 1.6,
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
                              'Informasi Pengguna',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkBlue,
                                  ),
                            ),
                            const SizedBox(height: 22),
                            _buildLabel('Nama Lengkap'),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization:
                                  TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan nama lengkap',
                                prefixIcon:
                                    Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Nama wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Nomor Plat Kendaraan'),
                            TextFormField(
                              controller: _plateController,
                              textCapitalization:
                                  TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: BE 1234 XYZ',
                                prefixIcon: Icon(
                                  Icons.directions_car_outlined,
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Nomor plat wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Daftar Sebagai'),
                            DropdownButtonFormField<String>(
                              initialValue: _role,
                              decoration: const InputDecoration(
                                prefixIcon:
                                    Icon(Icons.badge_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Mahasiswa',
                                  child: Text('Mahasiswa'),
                                ),
                                DropdownMenuItem(
                                  value: 'Dosen',
                                  child: Text('Dosen'),
                                ),
                              ],
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _role = value);
                                      }
                                    },
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Email'),
                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan email aktif',
                                prefixIcon:
                                    Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Email wajib diisi';
                                }

                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                                  return 'Format email tidak valid';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Password'),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                hintText: 'Minimal 6 karakter',
                                prefixIcon:
                                    const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
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
                                  return 'Password wajib diisi';
                                }

                                if (value.length < 6) {
                                  return 'Minimal 6 karakter';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    _isLoading ? null : _register,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_add_alt_1,
                                      ),
                                label: Text(
                                  _isLoading
                                      ? 'Mendaftarkan...'
                                      : 'Daftar Sekarang',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Pastikan data kendaraan sudah benar.',
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
                  Center(
                    child: Text(
                      'ParkSpot • Smart Parking for Campus',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.blueGrey),
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.darkBlue,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
