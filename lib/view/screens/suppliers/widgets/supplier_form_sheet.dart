import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/supplier.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/sheet_scaffold.dart';

class SupplierFormSheet extends StatefulWidget {
  const SupplierFormSheet({
    super.key,
    this.editingSupplier,
    required this.onSubmit,
  });
  final Supplier? editingSupplier;
  final Future<bool> Function(Supplier draft) onSubmit;

  @override
  State<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<SupplierFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(
    text: widget.editingSupplier?.name,
  );
  late final _categoryCtrl = TextEditingController(
    text: widget.editingSupplier?.category,
  );
  late final _contactCtrl = TextEditingController(
    text: widget.editingSupplier?.contact,
  );
  late final _emailCtrl = TextEditingController(
    text: widget.editingSupplier?.email,
  );
  late final _websiteCtrl = TextEditingController(
    text: widget.editingSupplier?.website,
  );
  late String _status = widget.editingSupplier?.status ?? 'Active';
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _categoryCtrl,
      _contactCtrl,
      _emailCtrl,
      _websiteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = Supplier(
      id: widget.editingSupplier?.id ?? '',
      name: _nameCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      website:
          _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      status: _status,
    );
    final ok = await widget.onSubmit(draft);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingSupplier != null;
    return SheetScaffold(
      maxHeightFactor: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Vendor Profile' : 'Register New Vendor',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Verify credentials for pharmaceutical distribution partners.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Company Name',
                            _nameCtrl,
                            required: true,
                            hint: 'e.g. Acme Pharma',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Category',
                            _categoryCtrl,
                            required: true,
                            hint: 'e.g. General, Vaccines',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Primary Contact',
                            _contactCtrl,
                            required: true,
                            hint: '+880 XXXX-XXXXXX',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Corporate Email',
                            _emailCtrl,
                            required: true,
                            hint: 'logistics@company.com',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Website',
                            _websiteCtrl,
                            hint: 'https://...',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Active',
                                child: Text(
                                  'Active',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Inactive',
                                child: Text(
                                  'Inactive',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                            onChanged:
                                (v) => setState(() => _status = v ?? 'Active'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    _saving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          isEditing ? 'SAVE UPDATES' : 'POST TO REGISTRY',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        validator:
            required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
      ),
    );
  }
}
