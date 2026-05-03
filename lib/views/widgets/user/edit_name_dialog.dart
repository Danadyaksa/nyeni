import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dialog untuk edit nama user
class EditNameDialog extends StatefulWidget {
  final String currentName;
  final Future<bool> Function(String newName) onSave;

  const EditNameDialog({
    super.key,
    required this.currentName,
    required this.onSave,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final success = await widget.onSave(_nameCtrl.text.trim());
    
    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(LucideIcons.user, color: Color(0xFF2C3E50)),
          SizedBox(width: 8),
          Text('Edit Nama', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.user),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
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
