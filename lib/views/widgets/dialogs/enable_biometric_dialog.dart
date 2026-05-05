import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Reusable enable biometric dialog
class EnableBiometricDialog {
  static Future<String?> show(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    bool isObscure = true;
    String? result;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(
                  LucideIcons.fingerprint,
                  color: Color(0xFF9A3412),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Aktifkan Login Biometric",
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masukkan password Anda untuk mengaktifkan login biometric',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF78706A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: isObscure,
                    style: GoogleFonts.manrope(),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                      prefixIcon: const Icon(
                        LucideIcons.lock,
                        size: 18,
                        color: Color(0xFF9A3412),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscure ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () =>
                            setStateDialog(() => isObscure = !isObscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF9A3412),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Batal",
                  style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  result = passwordController.text.trim();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A3412),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Aktifkan",
                  style: GoogleFonts.manrope(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    return result;
  }
}
