import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/biometric_controller.dart';

/// Reusable settings dialog for profile screen
class SettingsDialog {
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic>? userData,
    required VoidCallback onChangeName,
    required VoidCallback onChangeEmail,
    required VoidCallback onChangePassword,
    required Function(bool) onBiometricToggle,
  }) async {
    final biometricController = BiometricController();
    final biometricAvailable = await biometricController.isBiometricAvailable();
    final userId = userData?['id']?.toString();
    final biometricEnabled = userId != null
        ? await biometricController.isBiometricEnabled(userId)
        : false;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pengaturan Akun",
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A302A),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(LucideIcons.user, color: Color(0xFF9A3412)),
                  title: Text(
                    "Ganti Nama",
                    style: GoogleFonts.manrope(color: const Color(0xFF3A302A)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onChangeName();
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.mail, color: Color(0xFF9A3412)),
                  title: Text(
                    "Ganti Email",
                    style: GoogleFonts.manrope(color: const Color(0xFF3A302A)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onChangeEmail();
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.lock, color: Color(0xFF9A3412)),
                  title: Text(
                    "Ganti Password",
                    style: GoogleFonts.manrope(color: const Color(0xFF3A302A)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onChangePassword();
                  },
                ),

                // Biometric Toggle (if device supports)
                if (biometricAvailable && userId != null) ...[
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(
                      LucideIcons.fingerprint,
                      color: Color(0xFF9A3412),
                    ),
                    title: Text(
                      "Login Biometric",
                      style: GoogleFonts.manrope(color: const Color(0xFF3A302A)),
                    ),
                    subtitle: Text(
                      "Gunakan sidik jari atau face ID",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF78706A),
                      ),
                    ),
                    value: biometricEnabled,
                    activeColor: const Color(0xFF9A3412),
                    onChanged: (bool value) {
                      Navigator.pop(context);
                      onBiometricToggle(value);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
