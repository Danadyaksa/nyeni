import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Reusable change password dialog
class ChangePasswordDialog {
  static Future<String?> show(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final passController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isObscurePass = true;
    bool isObscureConfirm = true;
    String? result;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(LucideIcons.lock, color: Color(0xFF9A3412), size: 20),
                const SizedBox(width: 8),
                Text(
                  "Ganti Password",
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passController,
                    obscureText: isObscurePass,
                    style: GoogleFonts.manrope(),
                    decoration: InputDecoration(
                      hintText: "Password Baru (min. 6 karakter)",
                      hintStyle: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                      prefixIcon: const Icon(
                        LucideIcons.lock,
                        size: 18,
                        color: Color(0xFF9A3412),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscurePass ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () =>
                            setStateDialog(() => isObscurePass = !isObscurePass),
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
                      if (v.length < 6) return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: isObscureConfirm,
                    style: GoogleFonts.manrope(),
                    decoration: InputDecoration(
                      hintText: "Ulangi Password Baru",
                      hintStyle: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                      prefixIcon: const Icon(
                        LucideIcons.lock,
                        size: 18,
                        color: Color(0xFF9A3412),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () => setStateDialog(
                            () => isObscureConfirm = !isObscureConfirm),
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
                      if (v == null || v.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (v != passController.text) {
                        return 'Password tidak cocok';
                      }
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
                  result = passController.text.trim();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A3412),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Simpan",
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
