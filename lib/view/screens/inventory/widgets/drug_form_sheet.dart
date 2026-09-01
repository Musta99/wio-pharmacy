import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/sheet_scaffold.dart';

class DrugFormSheet extends StatefulWidget {
  const DrugFormSheet({super.key, this.editingDrug, required this.onSubmit});
  final Drug? editingDrug;
  final Future<bool> Function(Drug draft) onSubmit;

  @override
  State<DrugFormSheet> createState() => _DrugFormSheetState();
}

class _DrugFormSheetState extends State<DrugFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _brandCtrl = TextEditingController(
    text: widget.editingDrug?.brandName,
  );
  late final _genericCtrl = TextEditingController(
    text: widget.editingDrug?.genericName,
  );
  late final _skuCtrl = TextEditingController(text: widget.editingDrug?.sku);
  late final _barcodeCtrl = TextEditingController(
    text: widget.editingDrug?.barcode,
  );
  late final _strengthCtrl = TextEditingController(
    text: widget.editingDrug?.strength,
  );
  late final _zoneCtrl = TextEditingController(
    text: widget.editingDrug?.storage.zone,
  );
  late final _shelfCtrl = TextEditingController(
    text: widget.editingDrug?.storage.shelf,
  );
  late final _costCtrl = TextEditingController(
    text: widget.editingDrug?.pricing.costPrice.toString(),
  );
  late final _mrpCtrl = TextEditingController(
    text: widget.editingDrug?.pricing.mrp.toString(),
  );
  late final _markupCtrl = TextEditingController(
    text: (widget.editingDrug?.pricing.markupPercentage ?? 10).toString(),
  );
  late final _vatCtrl = TextEditingController(
    text: (widget.editingDrug?.pricing.vatPercentage ?? 5).toString(),
  );
  late final _currentStockCtrl = TextEditingController(
    text: widget.editingDrug?.stock.current.toString(),
  );
  late final _minStockCtrl = TextEditingController(
    text: widget.editingDrug?.stock.min.toString(),
  );
  late final _maxStockCtrl = TextEditingController(
    text: widget.editingDrug?.stock.max.toString(),
  );
  late final _packSizeCtrl = TextEditingController(
    text: (widget.editingDrug?.packaging.packSize ?? 100).toString(),
  );
  late final _uomCtrl = TextEditingController(
    text: widget.editingDrug?.packaging.unitOfMeasure ?? 'Tablet',
  );

  late String _form = widget.editingDrug?.form ?? kDrugForms.first;
  late String _category = widget.editingDrug?.category ?? kDrugCategories.first;
  late String _therapeutic =
      widget.editingDrug?.therapeuticCategory ?? kTherapeuticCategories.last;
  late String _condition =
      widget.editingDrug?.storage.condition ?? kStorageConditions.first;

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _brandCtrl,
      _genericCtrl,
      _skuCtrl,
      _barcodeCtrl,
      _strengthCtrl,
      _zoneCtrl,
      _shelfCtrl,
      _costCtrl,
      _mrpCtrl,
      _markupCtrl,
      _vatCtrl,
      _currentStockCtrl,
      _minStockCtrl,
      _maxStockCtrl,
      _packSizeCtrl,
      _uomCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text) ?? 0;
  int _int(TextEditingController c) => int.tryParse(c.text) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final draft = Drug(
      id: widget.editingDrug?.id ?? '',
      sku: _skuCtrl.text.trim(),
      barcode:
          _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      brandName: _brandCtrl.text.trim(),
      genericName: _genericCtrl.text.trim(),
      form: _form,
      strength: _strengthCtrl.text.trim(),
      category: _category,
      therapeuticCategory: _therapeutic,
      storage: DrugStorage(
        zone: _zoneCtrl.text.trim(),
        shelf: _shelfCtrl.text.trim(),
        condition: _condition,
      ),
      packaging: DrugPackaging(
        packSize: _int(_packSizeCtrl),
        unitOfMeasure: _uomCtrl.text.trim(),
      ),
      pricing: DrugPricing(
        costPrice: _num(_costCtrl),
        mrp: _num(_mrpCtrl),
        markupPercentage: _num(_markupCtrl),
        vatPercentage: _num(_vatCtrl),
      ),
      stock: DrugStock(
        current: _int(_currentStockCtrl),
        min: _int(_minStockCtrl),
        max: _int(_maxStockCtrl),
      ),
      batches: widget.editingDrug?.batches ?? [],
    );

    final ok = await widget.onSubmit(draft);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF17A673);
    final isEditing = widget.editingDrug != null;

    return SheetScaffold(
      maxHeightFactor: 0.94,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Medicine' : 'Drug Registration',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Maintain standards for every entry.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('1. IDENTIFIERS & CLASSIFICATION', mint),
                    _field('Brand Name', _brandCtrl, required: true),
                    _field('Generic Name', _genericCtrl, required: true),
                    _field('SKU / Code', _skuCtrl, required: true),
                    _field('Barcode', _barcodeCtrl),
                    _dropdown(
                      'Form',
                      _form,
                      kDrugForms,
                      (v) => setState(() => _form = v),
                    ),
                    _field('Strength', _strengthCtrl, hint: 'e.g. 500mg'),
                    _dropdown(
                      'Regulatory Class',
                      _category,
                      kDrugCategories,
                      (v) => setState(() => _category = v),
                    ),
                    _dropdown(
                      'Category',
                      _therapeutic,
                      kTherapeuticCategories,
                      (v) => setState(() => _therapeutic = v),
                    ),

                    _sectionLabel('2. STORAGE & LOGISTICS', mint),
                    Row(
                      children: [
                        Expanded(child: _field('Zone', _zoneCtrl, hint: 'A')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field('Shelf ID', _shelfCtrl, hint: '12'),
                        ),
                      ],
                    ),
                    _dropdown(
                      'Condition',
                      _condition,
                      kStorageConditions,
                      (v) => setState(() => _condition = v),
                    ),

                    _sectionLabel('3. PRICING MATRIX', mint),
                    Row(
                      children: [
                        Expanded(
                          child: _field('Unit Cost', _costCtrl, numeric: true),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Final MRP',
                            _mrpCtrl,
                            numeric: true,
                            required: true,
                            highlight: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field('Markup %', _markupCtrl, numeric: true),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field('VAT %', _vatCtrl, numeric: true),
                        ),
                      ],
                    ),

                    _sectionLabel('4. STOCK CONTROL', mint),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Opening',
                            _currentStockCtrl,
                            numeric: true,
                            isInt: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field(
                            'Min Alert',
                            _minStockCtrl,
                            numeric: true,
                            isInt: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field(
                            'Max Cap',
                            _maxStockCtrl,
                            numeric: true,
                            isInt: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Pack Units',
                            _packSizeCtrl,
                            numeric: true,
                            isInt: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Unit (e.g. Strip)', _uomCtrl)),
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
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mint,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child:
                        _saving
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'SAVE REGISTRY',
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
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    bool numeric = false,
    bool isInt = false,
    bool highlight = false,
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: highlight ? FontWeight.w900 : FontWeight.normal,
          color: highlight ? const Color(0xFF17A673) : Colors.black87,
        ),
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

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items:
            options
                .map(
                  (o) => DropdownMenuItem(
                    value: o,
                    child: Text(o, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
