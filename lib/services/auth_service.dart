import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Box _box = Hive.box('nyeni_box');

  Future<String?> register({required String name, required String email, required String password}) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        await _supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'full_name': name,
          'total_xp': 0,
          'level': 1,
          'role': 'user',
        });
        return null;
      }
      return 'Gagal mendaftar.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<String?> login({required String email, required String password}) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await _box.put('role', 'user');
        await _box.put('email', email);
        return null;
      }
      return 'Email atau password salah.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    await _box.delete('role');
    await _box.delete('email');
  }
}