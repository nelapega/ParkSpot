import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/stnk_storage_service.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final AuthService _authService = AuthService();
  final StnkStorageService _stnkService = StnkStorageService();

  Future<Map<String, dynamic>>? _profileFuture;

  bool _showStnk = false;
  bool _loadingStnk = false;
  String? _stnkUrl;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  // Mengambil data profil dari Firestore.
  Future<Map<String, dynamic>> _loadProfile() async {
    final initialUser = FirebaseAuth.instance.currentUser;

    if (initialUser == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    try {
      await initialUser.reload();
    } catch (_) {
      // Tetap coba mengambil profil jika reload gagal.
    }

    final user = FirebaseAuth.instance.currentUser ?? initialUser;

    final documentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final snapshot = await documentRef.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Data profil tidak ditemukan.');
    }

    final data = snapshot.data()!;

    // Sinkronkan email Firestore setelah email baru
    // berhasil diverifikasi dan diperbarui oleh Firebase.
    if (user.email != null &&
        user.email!.trim().toLowerCase() !=
            (data['email'] ?? '').toString().trim().toLowerCase()) {
      await documentRef.update({
        'email': user.email,
        'pendingEmail': FieldValue.delete(),
        'emailUpdatedAt': FieldValue.serverTimestamp(),
      });

      data['email'] = user.email;
      data.remove('pendingEmail');
    }

    return data;
  }

  void _refreshProfile() {
    setState(() {
      _showStnk = false;
      _stnkUrl = null;
      _loadingStnk = false;
      _profileFuture = _loadProfile();
    });
  }

  // Menampilkan atau menyembunyikan foto STNK.
  Future<void> _toggleStnk(String? path) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto STNK belum tersedia.')),
      );
      return;
    }

    if (_showStnk) {
      setState(() {
        _showStnk = false;
        _stnkUrl = null;
      });
      return;
    }

    setState(() => _loadingStnk = true);

    try {
      final url = await _stnkService.getStnkSignedUrl(path);

      if (!mounted) return;

      setState(() {
        _stnkUrl = url;
        _showStnk = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menampilkan STNK: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingStnk = false);
      }
    }
  }

  // Membuka halaman edit profil.
  Future<void> _openEditPage(Map<String, dynamic> profile) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientProfileEditPage(profile: profile),
      ),
    );

    if (!mounted) return;

    if (message != null) {
      _refreshProfile();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Logout.
  Future<void> _logout() async {
    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal keluar akun: $e')));
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar Akun'),
          content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout();
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return _buildError('Data profil tidak tersedia.');
        }

        final profile = snapshot.data!;

        final name = profile['name']?.toString() ?? '-';
        final email = profile['email']?.toString() ?? '-';
        final category = profile['category']?.toString() ?? '-';
        final plate = profile['vehiclePlate']?.toString() ?? '-';
        final stnkPath = profile['stnkPhotoPath']?.toString();

        return RefreshIndicator(
          onRefresh: () async => _refreshProfile(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profil Saya',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshProfile,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.primaryBlue,
                    ),
                    tooltip: 'Refresh profil',
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                'Informasi akun dan kendaraan kamu.',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),

              const SizedBox(height: 22),

              // Kartu identitas.
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              _sectionTitle('Informasi Akun'),

              const SizedBox(height: 12),

              _infoCard(Icons.person_outline, 'Nama Lengkap', name),

              _infoCard(Icons.email_outlined, 'Email', email),

              _infoCard(Icons.school_outlined, 'Kategori Pengguna', category),

              const SizedBox(height: 18),

              _sectionTitle('Informasi Kendaraan'),

              const SizedBox(height: 12),

              _infoCard(
                Icons.directions_car_outlined,
                'Nomor Kendaraan',
                plate,
              ),

              // Foto STNK hanya muncul saat tombol ditekan.
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.file_present_outlined,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Dokumen STNK',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _loadingStnk
                              ? null
                              : () => _toggleStnk(stnkPath),
                          icon: _loadingStnk
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _showStnk
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                          label: Text(
                            _loadingStnk
                                ? 'Memuat foto...'
                                : _showStnk
                                ? 'Sembunyikan Foto STNK'
                                : 'Lihat Foto STNK',
                          ),
                        ),
                      ),

                      if (_showStnk && _stnkUrl != null) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _stnkUrl!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;

                              return const SizedBox(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stack) {
                              return Container(
                                height: 160,
                                alignment: Alignment.center,
                                color: const Color(0xFFF1F5FA),
                                child: const Text(
                                  'Foto STNK gagal ditampilkan.',
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tombol edit.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openEditPage(profile),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profil'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Logout.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
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
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 45, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat profil.',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refreshProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkBlue,
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
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

// ======================================================
// HALAMAN EDIT PROFIL CLIENT
// ======================================================

class ClientProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ClientProfileEditPage({super.key, required this.profile});

  @override
  State<ClientProfileEditPage> createState() => _ClientProfileEditPageState();
}

class _ClientProfileEditPageState extends State<ClientProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _plateController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final StnkStorageService _stnkService = StnkStorageService();

  XFile? _newStnkImage;
  Uint8List? _newStnkBytes;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.profile['name']?.toString() ?? '';

    _emailController.text = widget.profile['email']?.toString() ?? '';

    _plateController.text = widget.profile['vehiclePlate']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  // Memilih foto STNK baru.
  Future<void> _pickNewStnk() async {
    if (_isSaving) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) return;

      final fileName = image.name.toLowerCase();

      if (!fileName.endsWith('.jpg') &&
          !fileName.endsWith('.jpeg') &&
          !fileName.endsWith('.png')) {
        throw Exception('Foto harus JPG atau PNG.');
      }

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('File foto kosong.');
      }

      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Ukuran foto maksimal 5 MB.');
      }

      if (!mounted) return;

      setState(() {
        _newStnkImage = image;
        _newStnkBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // Menyimpan perubahan profil.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silakan login kembali.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = user.uid;

      final firestore = FirebaseFirestore.instance;
      final documentRef = firestore.collection('users').doc(uid);

      // Upload foto baru jika pengguna memilihnya.
      String? newPhotoPath;

      if (_newStnkImage != null) {
        newPhotoPath = await _stnkService.uploadStnk(
          _newStnkImage!,
          userId: uid,
        );
      }

      // Simpan perubahan nama dan nomor plat.
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'vehiclePlate': _plateController.text.trim().toUpperCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newPhotoPath != null) {
        updates['stnkPhotoPath'] = newPhotoPath;
        updates['stnkUploadedAt'] = FieldValue.serverTimestamp();
      }

      await documentRef.update(updates);

      // Permintaan perubahan email dilakukan melalui
      // tautan verifikasi Firebase.
      final newEmail = _emailController.text.trim();
      final currentEmail = user.email?.trim() ?? '';

      var message = 'Profil berhasil diperbarui!';

      if (newEmail.toLowerCase() != currentEmail.toLowerCase()) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);

          await documentRef.update({
            'pendingEmail': newEmail,
            'emailUpdateRequestedAt': FieldValue.serverTimestamp(),
          });

          message =
              'Data profil berhasil diperbarui. '
              'Tautan verifikasi email telah dikirim ke $newEmail. '
              'Email akan berubah setelah verifikasi selesai.';
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            message =
                'Nama, kendaraan, dan foto berhasil disimpan. '
                'Untuk mengubah email, silakan login ulang dahulu.';
          } else if (e.code == 'email-already-in-use') {
            message =
                'Data profil berhasil disimpan, tetapi email baru '
                'sudah digunakan akun lain.';
          } else {
            message =
                'Data profil berhasil disimpan, tetapi verifikasi '
                'email gagal: ${e.message ?? e.code}';
          }
        } catch (e) {
          message =
              'Data profil berhasil disimpan, tetapi email belum '
              'dapat diperbarui. Silakan coba lagi.';
        }
      }

      if (!mounted) return;

      Navigator.pop(context, message);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: ${e.message ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan perubahan: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Edit Profil'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Ubah Informasi Profil',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkBlue,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Perbarui informasi akun dan kendaraan kamu.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),

              const SizedBox(height: 25),

              _editLabel('Nama Lengkap'),

              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _editLabel('Email'),

              TextFormField(
                controller: _emailController,
                enabled: !_isSaving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Masukkan email aktif',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';

                  if (email.isEmpty) {
                    return 'Email wajib diisi.';
                  }

                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Format email tidak valid.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              const Text(
                'Perubahan email membutuhkan verifikasi melalui tautan yang dikirim Firebase.',
                style: TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),

              const SizedBox(height: 20),

              _editLabel('Kategori Pengguna'),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.profile['category']?.toString() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Tidak dapat diubah',
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _editLabel('Nomor Plat Kendaraan'),

              TextFormField(
                controller: _plateController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Contoh: BE 1234 XYZ',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor plat wajib diisi.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              _editLabel('Ganti Foto STNK'),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blueGrey.shade200),
                ),
                child: Column(
                  children: [
                    if (_newStnkBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _newStnkBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                      const Icon(
                        Icons.file_present_outlined,
                        size: 55,
                        color: Colors.blueGrey,
                      ),

                    const SizedBox(height: 12),

                    Text(
                      _newStnkImage?.name ?? 'Belum ada foto STNK baru',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickNewStnk,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _newStnkImage == null
                            ? 'Pilih Foto STNK Baru'
                            : 'Ganti Pilihan Foto',
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'JPG atau PNG, maksimal 5 MB.',
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Foto lama tetap digunakan jika kamu tidak memilih foto baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'ParkSpot • Smart Parking for Campus',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.darkBlue,
        ),
      ),
    );
  }
}
