import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Reusable change name dialog
class ChangeNameDialog {
  static Future<String?> show(
    BuildContext context, {
    required String currentName,
  }) async {
    final nameController = TextEditingController(text: currentName);
    String? result;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.user, color: Color(0xFF9A3412), size: 20),
            const SizedBox(width: 8),
            Text(
              "Edit Nama",
              style: GoogleFonts.ebGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A302A),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: nameController,
          style: GoogleFonts.manrope(),
          decoration: InputDecoration(
            hintText: "Masukkan nama baru",
            hintStyle: GoogleFonts.manrope(color: const Color(0xFF78706A)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9A3412), width: 2),
            ),
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
              if (nameController.text.trim().isEmpty) return;
              result = nameController.text.trim();
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
