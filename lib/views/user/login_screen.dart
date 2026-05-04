import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart';
import 'main_navigation.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/biometric_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  final _biometricController = BiometricController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricController.isBiometricAvailable();
    // Cek apakah ada user yang pernah enable biometric
    final lastUserId = await _biometricController.getLastBiometricUserId();
    final enabled = lastUserId != null ? await _biometricController.isBiometricEnabled(lastUserId) : false;
    
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (mounted) setState(() => _isLoading = false);

    if (user != null) {
      // Jika biometric available tapi user ini belum enabled, tanya user mau enable atau tidak
      if (_biometricAvailable && mounted) {
        final userBiometricEnabled = await _biometricController.isBiometricEnabled(user.id);
        if (!userBiometricEnabled) {
          _showEnableBiometricDialog(user.id, _emailController.text.trim(), _passwordController.text.trim());
        }
      }
      
      if (mounted) {
        if (user.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login gagal. Periksa email dan password Anda.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBiometricLogin() async {
    setState(() => _isLoading = true);
    final user = await _biometricController.loginWithBiometric();
    if (mounted) setState(() => _isLoading = false);

    if (user != null) {
      if (mounted) {
        if (user.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login biometric gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEnableBiometricDialog(String userId, String email, String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aktifkan Login Biometric?', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.w600)),
        content: Text(
          'Gunakan sidik jari atau face ID untuk login lebih cepat di masa depan.',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Nanti Saja', style: GoogleFonts.manrope()),
          ),
          ElevatedButton(
            onPressed: () async {
              await _biometricController.setBiometricEnabled(userId, true);
              await _biometricController.saveBiometricCredentials(userId, email, password);
              await _biometricController.setLastBiometricUserId(userId);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login biometric berhasil diaktifkan! 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A3412),
            ),
            child: Text('Aktifkan', style: GoogleFonts.manrope(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Header ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9A3412).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.palette,
                            size: 44, color: Color(0xFF9A3412)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Masuk ke Nyeni',
                        style: GoogleFonts.ebGaramond(
                            fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF3A302A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selamat datang kembali!',
                        style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Email ──
                _label('Email'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hint: 'contoh@gmail.com',
                    icon: LucideIcons.mail,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
                        .hasMatch(v.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Password ──
                _label('Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: _inputDecoration(
                    hint: 'Masukkan password kamu',
                    icon: LucideIcons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? LucideIcons.eyeOff
                            : LucideIcons.eye,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Tombol login ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9A3412),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Masuk',
                            style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                  ),
                ),
                
                // ── Tombol Biometric (jika available & enabled) ──
                if (_biometricAvailable && _biometricEnabled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      icon: const Icon(LucideIcons.fingerprint, size: 20),
                      label: Text('Masuk dengan Biometric', style: GoogleFonts.manrope()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9A3412),
                        side: const BorderSide(color: Color(0xFF9A3412)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),

                // ── Link ke register ──
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: Text(
                      'Belum punya akun? Daftar di sini',
                      style: GoogleFonts.manrope(color: const Color(0xFF9A3412)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF3A302A)),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(color: const Color(0xFF78706A).withOpacity(0.6), fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF78706A)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8D0C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8D0C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9A3412), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
