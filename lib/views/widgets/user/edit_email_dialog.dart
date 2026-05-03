import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dialog untuk edit email user
class EditEmailDialog extends StatefulWidget {
  final String currentEmail;
  final Future<Map<String, dynamic>> Function(String newEmail) onSave;

  const EditEmailDialog({
    super.key,
    required this.currentEmail,
    required this.onSave,
  });

  @override
  State<EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends State<EditEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final result = await widget.onSave(_emailCtrl.text.trim());
    
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
          Icon(LucideIcons.mail, color: Color(0xFF2C3E50)),
          SizedBox(width: 8),
          Text('Edit Email', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.mail),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
            if (!v.contains('@')) return 'Email tidak valid';
            return null;
          },
          enabled: !_isSaving,
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
