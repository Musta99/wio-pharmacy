import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/sheet_scaffold.dart';

class StockInSheet extends StatefulWidget {
  const StockInSheet({
    super.key,
    required this.inventory,
    required this.onSubmit,
    this.preselectedId,
  });

  final List<Drug> inventory;
  final String? preselectedId;
  final Future<bool> Function(String drugId, DrugBatch batch) onSubmit;

  @override
  State<StockInSheet> createState() => _StockInSheetState();
}

class _StockInSheetState extends State<StockInSheet> {
  final _formKey = GlobalKey<FormState>();
  final _batchCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  String? _selectedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.preselectedId;
  }

  @override
  void dispose() {
    for (final c in [
      _batchCtrl,
      _expiryCtrl,
      _supplierCtrl,
      _invoiceCtrl,
      _qtyCtrl,
      _costCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      _expiryCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (_selectedId == null || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final batch = DrugBatch(
      batchNumber: _batchCtrl.text.trim(),
      expiryDate: _expiryCtrl.text.trim(),
      quantity: int.tryParse(_qtyCtrl.text) ?? 0,
      purchaseCost: double.tryParse(_costCtrl.text) ?? 0,
      supplier: _supplierCtrl.text.trim(),
      invoiceNumber:
          _invoiceCtrl.text.trim().isEmpty ? null : _invoiceCtrl.text.trim(),
    );

    final ok = await widget.onSubmit(_selectedId!, batch);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF17A673);
    final selectedDrug =
        widget.inventory.where((d) => d.id == _selectedId).firstOrNull;

    return SheetScaffold(
      maxHeightFactor: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock-In Entry',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Log new inventory arrival following FIFO.',
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
                    if (widget.preselectedId == null) ...[
                      const Text(
                        'SELECT MEDICINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Browse inventory...',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items:
                            widget.inventory
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(
                                      '${d.brandName} (${d.genericName})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _selectedId = v),
                      ),
                      const SizedBox(height: 14),
                    ] else if (selectedDrug != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mint.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SKU SELECTED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: mint,
                                  ),
                                ),
                                Text(
                                  selectedDrug.sku,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed:
                                  () => setState(() => _selectedId = null),
                              child: const Text(
                                'CHANGE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Batch Number',
                            _batchCtrl,
                            required: true,
                            hint: 'BN-XXX-2024',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickExpiry,
                            child: AbsorbPointer(
                              child: _field(
                                'Expiry Date',
                                _expiryCtrl,
                                required: true,
                                hint: 'YYYY-MM-DD',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Supplier',
                            _supplierCtrl,
                            required: true,
                            hint: 'Distributor Name',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Invoice #',
                            _invoiceCtrl,
                            hint: 'INV-0000',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Quantity Received',
                            _qtyCtrl,
                            required: true,
                            numeric: true,
                            isInt: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Purchase Unit Cost',
                            _costCtrl,
                            required: true,
                            numeric: true,
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
                onPressed: (_selectedId == null || _saving) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mint,
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
                        : const Text(
                          'POST TO INVENTORY',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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
    bool numeric = false,
    bool isInt = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType:
            numeric
                ? TextInputType.numberWithOptions(decimal: !isInt)
                : TextInputType.text,
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
