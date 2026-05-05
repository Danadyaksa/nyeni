import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Reusable change email dialog
class ChangeEmailDialog {
  static Future<String?> show(
    BuildContext context, {
    required String currentEmail,
  }) async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: currentEmail);
    String? result;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.mail, color: Color(0xFF9A3412), size: 20),
            const SizedBox(width: 8),
            Text(
              "Ganti Email",
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email saat ini: $currentEmail',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF78706A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Masukkan email baru dengan format yang valid',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: const Color(0xFF78706A),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.manrope(),
                decoration: InputDecoration(
                  hintText: "contoh@gmail.com",
                  hintStyle: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                  prefixIcon: const Icon(
                    LucideIcons.mail,
                    size: 18,
                    color: Color(0xFF9A3412),
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
                  if (v == null || v.trim().isEmpty) {
                    return 'Email wajib diisi';
                  }
                  // Email format validation
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
                    return 'Format email tidak valid';
                  }
                  // Email must be different from current
                  if (v.trim().toLowerCase() == currentEmail.toLowerCase()) {
                    return 'Email baru tidak boleh sama dengan email lama';
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
              result = emailController.text.trim();
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
      ),
    );

    return result;
  }
}
