import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dialog untuk enable biometric dengan verifikasi password
class BiometricEnableDialog extends StatefulWidget {
  final String userId;
  final String email;
  final Future<bool> Function(String userId, String email, String password) onEnable;

  const BiometricEnableDialog({
    super.key,
    required this.userId,
    required this.email,
    required this.onEnable,
  });

  @override
  State<BiometricEnableDialog> createState() => _BiometricEnableDialogState();
}

class _BiometricEnableDialogState extends State<BiometricEnableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _enable() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final password = _passwordCtrl.text.trim();
    
    print('🔐 BiometricDialog: Starting verification...');
    
    try {
      final verified = await widget.onEnable(
        widget.userId,
        widget.email,
        password,
      );

      print('🔐 BiometricDialog: Verification result: $verified');

      if (mounted) {
        if (verified) {
          print('🔐 BiometricDialog: Closing dialog with password');
          Navigator.pop(context, password);
        } else {
          print('🔐 BiometricDialog: Password wrong, showing error');
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password salah'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('🔐 BiometricDialog: ERROR - $e');
      print('🔐 BiometricDialog: Stack trace - $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(LucideIcons.fingerprint, color: Color(0xFF2C3E50), size: 20),
          SizedBox(width: 8),
          Text('Aktifkan Biometric', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan password untuk verifikasi:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _isObscure,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_isObscure ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) 
                  ? 'Password tidak boleh kosong' 
                  : null,
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _enable,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Aktifkan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
