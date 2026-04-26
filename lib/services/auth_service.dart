import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Box _box = Hive.box('nyeni_box');

  // Fungsi Register (Daftar Akun)
  Future<String?> register({required String name, required String email, required String password}) async {
    try {
      // 1. Mendaftarkan auth ke Supabase (Otomatis terenkripsi Bcrypt)
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        // 2. Menyimpan data tambahan (Nama Lengkap, Level, XP) ke tabel 'users'
        await _supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'full_name': name,
          'total_xp': 0,
          'level': 1,
          'role': 'user',
        });
        return null; // Sukses, tidak ada error
      }
      return 'Gagal mendaftar. Silakan coba lagi.';
    } on AuthException catch (e) {
      return e.message; // Mengembalikan pesan error dari Supabase (misal: Email sudah dipakai)
    } catch (e) {
      return 'Terjadi kesalahan sistem: $e';
    }
  }

  // Fungsi Login (Masuk Akun)
  Future<String?> login({required String email, required String password}) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Simpan status bahwa user sudah login ke Hive (Local Storage)
        await _box.put('role', 'user');
        await _box.put('email', email);
        return null; // Sukses
      }
      return 'Email atau password salah.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan sistem: $e';
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
    await _box.delete('role'); // Hapus sesi
    await _box.delete('email');
  }
}