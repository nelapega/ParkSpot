import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/supabase_config.dart';

class StnkStorageService {
  static const int _maxFileSize = 5 * 1024 * 1024;
  static const String _functionName = 'stnk-storage';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Uri get _functionUrl {
    final baseUrl = SupabaseConfig.projectUrl.replaceFirst(RegExp(r'/$'), '');

    return Uri.parse('$baseUrl/functions/v1/$_functionName');
  }

  // Mengambil Firebase ID Token.
  Future<String> _getFirebaseToken() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token Firebase tidak tersedia.');
    }

    return token;
  }

  // Header autentikasi untuk Edge Function.
  Future<Map<String, String>> _headers() async {
    final token = await _getFirebaseToken();

    return {
      'apikey': SupabaseConfig.publishableKey,
      'Authorization': 'Bearer $token',
    };
  }

  // Mengubah URL lama Firestore menjadi path file.
  String _normalizeStoragePath(String pathOrUrl) {
    final value = pathOrUrl.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.parse(value);
      final projectUri = Uri.parse(SupabaseConfig.projectUrl);

      if (uri.host != projectUri.host) {
        throw Exception('URL foto bukan berasal dari project ParkSpot.');
      }

      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('stnk');

      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
        throw Exception('Path foto STNK tidak valid.');
      }

      return segments.skip(bucketIndex + 1).join('/');
    }

    return value.replaceFirst(RegExp(r'^/+'), '');
  }

  // Membaca respons JSON.
  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Respons bukan JSON.
    }

    return {};
  }

  // Upload foto STNK melalui Edge Function.
  // Hasil berupa path, bukan URL publik.
  Future<String> uploadStnk(XFile image, {String? userId}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    final uid = user.uid;

    if (userId != null && userId != uid) {
      throw Exception('UID pengguna tidak sesuai.');
    }

    final fileName = image.name.toLowerCase();

    late String extension;
    late MediaType contentType;

    if (fileName.endsWith('.png')) {
      extension = 'png';
      contentType = MediaType('image', 'png');
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      extension = 'jpg';
      contentType = MediaType('image', 'jpeg');
    } else {
      throw Exception('Format foto harus JPG atau PNG.');
    }

    final bytes = await image.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('File foto kosong.');
    }

    if (bytes.length > _maxFileSize) {
      throw Exception('Ukuran foto maksimal 5 MB.');
    }

    try {
      final request = http.MultipartRequest('POST', _functionUrl);

      request.headers.addAll(await _headers());

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'stnk.$extension',
          contentType: contentType,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true &&
          data['path'] is String) {
        final path = data['path'] as String;

        final parts = path.split('/');

        if (parts.length != 2 || parts.first != uid) {
          throw Exception('Path foto yang dikembalikan tidak valid.');
        }

        return path;
      }

      throw Exception(data['error'] ?? 'Upload foto STNK gagal.');
    } catch (e) {
      throw Exception(
        'Gagal mengunggah foto STNK: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  // Mengambil signed URL melalui Edge Function.
  // Mendukung path baru dan URL lama dari Firestore.
  Future<String> getStnkSignedUrl(
    String pathOrUrl, {
    int expiresIn = 3600,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('Silakan login terlebih dahulu.');
      }

      final storagePath = _normalizeStoragePath(pathOrUrl);
      final parts = storagePath.split('/');

      // Foto hanya boleh diakses oleh pemiliknya.
      if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
        throw Exception('Format path foto tidak valid.');
      }

      final response = await http
          .post(
            _functionUrl,
            headers: {...await _headers(), 'Content-Type': 'application/json'},
            body: jsonEncode({'path': storagePath, 'expiresIn': expiresIn}),
          )
          .timeout(const Duration(seconds: 30));

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true &&
          data['signedUrl'] is String) {
        return data['signedUrl'] as String;
      }

      throw Exception(data['error'] ?? 'Gagal mengambil foto STNK.');
    } catch (e) {
      throw Exception(
        'Gagal mendapatkan foto STNK: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}
