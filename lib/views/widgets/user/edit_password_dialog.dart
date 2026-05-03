import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dialog untuk edit password user
class EditPasswordDialog extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(String newPassword) onSave;

  const EditPasswordDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<EditPasswordDialog> createState() => _EditPasswordDialogState();
}

class _EditPasswordDialogState extends State<EditPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final result = await widget.onSave(_passwordCtrl.text.trim());
    
    if (mounted) {
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(LucideIcons.lock, color: Color(0xFF2C3E50)),
          SizedBox(width: 8),
          Text('Ganti Password', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Password tidak boleh kosong';
                if (v.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Konfirmasi password tidak boleh kosong';
                if (v != _passwordCtrl.text) return 'Password tidak cocok';
                return null;
              },
              enabled: !_isSaving,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
