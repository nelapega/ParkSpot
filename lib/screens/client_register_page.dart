import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/stnk_storage_service.dart';

class ClientRegisterPage extends StatefulWidget {
  const ClientRegisterPage({super.key});

  @override
  State<ClientRegisterPage> createState() => _ClientRegisterPageState();
}

class _ClientRegisterPageState extends State<ClientRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final StnkStorageService _stnkStorageService = StnkStorageService();

  final ImagePicker _imagePicker = ImagePicker();

  String _role = 'Mahasiswa';
  bool _hidePassword = true;
  bool _isLoading = false;

  XFile? _stnkImage;
  Uint8List? _stnkImageBytes;

  static const int _maxImageSize = 5 * 1024 * 1024;

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Memilih foto STNK dari galeri.
  Future<void> _pickStnkImage() async {
    if (_isLoading) return;

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedImage == null) return;

      final fileName = pickedImage.name.toLowerCase();

      if (!fileName.endsWith('.jpg') &&
          !fileName.endsWith('.jpeg') &&
          !fileName.endsWith('.png')) {
        throw Exception('Foto harus berformat JPG, JPEG, atau PNG.');
      }

      final bytes = await pickedImage.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('File foto kosong.');
      }

      if (bytes.length > _maxImageSize) {
        throw Exception('Ukuran foto maksimal 5 MB.');
      }

      if (!mounted) return;

      setState(() {
        _stnkImage = pickedImage;
        _stnkImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // Menghapus foto STNK yang dipilih.
  void _removeStnkImage() {
    setState(() {
      _stnkImage = null;
      _stnkImageBytes = null;
    });
  }

  // Proses registrasi pengguna.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_stnkImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan upload foto STNK terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    User? createdUser;

    try {
      // 1. Membuat akun Firebase Authentication.
      final credential = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('Akun gagal dibuat.');
      }

      // 2. Upload foto STNK ke Supabase Storage.
      final stnkPhotoPath = await _stnkStorageService.uploadStnk(
        _stnkImage!,
        userId: createdUser.uid,
      );

      // 3. Menyimpan profil pengguna dan path foto ke Firestore.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
            'uid': createdUser.uid,
            'name': _nameController.text.trim(),
            'vehiclePlate': _plateController.text.trim().toUpperCase(),
            'category': _role,
            'email': _emailController.text.trim(),
            'stnkPhotoPath': stnkPhotoPath,
            'createdAt': FieldValue.serverTimestamp(),
            'stnkUploadedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil! Silakan login.')),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      // Menghapus akun Auth jika proses registrasi
      // gagal setelah akun berhasil dibuat.
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Penghapusan akun bisa gagal jika sesi tidak valid.
        }
      }

      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pendaftaran gagal: $errorMessage'),
          duration: const Duration(seconds: 5),
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
                      style: Theme.of(context).textTheme.headlineSmall
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkBlue,
                                  ),
                            ),

                            const SizedBox(height: 22),

                            // Nama lengkap.
                            _buildLabel('Nama Lengkap'),

                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan nama lengkap',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama wajib diisi';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // Nomor plat kendaraan.
                            _buildLabel('Nomor Plat Kendaraan'),

                            TextFormField(
                              controller: _plateController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: BE 1234 XYZ',
                                prefixIcon: Icon(Icons.directions_car_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nomor plat wajib diisi';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // Upload foto STNK.
                            _buildLabel('Foto STNK'),

                            _buildStnkUpload(),

                            const SizedBox(height: 18),

                            // Kategori pengguna.
                            _buildLabel('Daftar Sebagai'),

                            DropdownButtonFormField<String>(
                              initialValue: _role,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined),
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
                                        setState(() {
                                          _role = value;
                                        });
                                      }
                                    },
                            ),

                            const SizedBox(height: 18),

                            // Email.
                            _buildLabel('Email'),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan email aktif',
                                prefixIcon: Icon(Icons.email_outlined),
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

                            // Password.
                            _buildLabel('Password'),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                hintText: 'Minimal 6 karakter',
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
                                  return 'Password wajib diisi';
                                }

                                if (value.length < 6) {
                                  return 'Minimal 6 karakter';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 26),

                            // Tombol registrasi.
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _register,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.person_add_alt_1),
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

                  Center(
                    child: Text(
                      'ParkSpot • Smart Parking for Campus',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
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

  // Tampilan upload foto STNK.
  Widget _buildStnkUpload() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        children: [
          if (_stnkImageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _stnkImageBytes!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.contain,
              ),
            )
          else
            Icon(
              Icons.file_present_outlined,
              size: 65,
              color: Colors.blueGrey.shade400,
            ),

          const SizedBox(height: 12),

          Text(
            _stnkImage?.name ?? 'Belum ada foto STNK dipilih',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.blueGrey),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickStnkImage,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _stnkImage == null ? 'Pilih Foto STNK' : 'Ganti Foto STNK',
            ),
          ),

          if (_stnkImage != null)
            TextButton.icon(
              onPressed: _isLoading ? null : _removeStnkImage,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Foto'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),

          const SizedBox(height: 4),

          const Text(
            'Format JPG atau PNG, maksimal 5 MB.',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
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
