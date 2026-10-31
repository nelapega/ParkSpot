
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mengambil pengguna yang sedang login.
  User? get currentUser => _auth.currentUser;

  // Mendaftar akun menggunakan email dan password.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Login menggunakan email dan password.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Logout dari akun yang sedang digunakan.
  Future<void> logout() async {
    await _auth.signOut();
  }
}
