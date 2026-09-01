import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/pharmacy_staff.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/sheet_scaffold.dart';

class AddStaffSheet extends StatefulWidget {
  const AddStaffSheet({super.key, required this.onSubmit});
  final Future<bool> Function({
    required String name,
    required String email,
    required String password,
    required PharmacyStaffRole subRole,
  })
  onSubmit;

  @override
  State<AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<AddStaffSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  PharmacyStaffRole _role = PharmacyStaffRole.pharmacist;
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await widget.onSubmit(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      subRole: _role,
    );
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF17A673);
    return SheetScaffold(
      maxHeightFactor: 0.75,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Staff Member',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Give them a restricted login for this pharmacy.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Temp Password',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PharmacyStaffRole>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items:
                  PharmacyStaffRole.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r.label,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
              onChanged:
                  (v) =>
                      setState(() => _role = v ?? PharmacyStaffRole.pharmacist),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                    _submitting
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Add Staff Member',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
