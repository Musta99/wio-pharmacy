import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/shipment.dart';
import 'package:wio_pharmacy/models/supplier.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/sheet_scaffold.dart';

class NewShipmentSheet extends StatefulWidget {
  const NewShipmentSheet({
    super.key,
    required this.suppliers,
    required this.inventory,
    required this.onSubmit,
  });

  final List<Supplier> suppliers;
  final List<Drug> inventory;
  final Future<bool> Function({
    required String supplierId,
    required String supplierName,
    required String invoiceNumber,
    required List<ShipmentItem> rows,
  })
  onSubmit;

  @override
  State<NewShipmentSheet> createState() => _NewShipmentSheetState();
}

class _NewShipmentSheetState extends State<NewShipmentSheet> {
  Supplier? _selectedSupplier;
  final _invoiceCtrl = TextEditingController();
  List<ShipmentItem> _rows = [_emptyRow()];
  bool _submitting = false;

  static ShipmentItem _emptyRow() => ShipmentItem(
    drugId: '',
    drugName: '',
    quantity: 1,
    batchNumber: '',
    expiryDate: '',
    unitCost: 0,
  );

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry(int index) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _rows[index] = _rows[index].copyWith(
          expiryDate:
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
        );
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await widget.onSubmit(
      supplierId: _selectedSupplier?.id ?? '',
      supplierName: _selectedSupplier?.name ?? '',
      invoiceNumber: _invoiceCtrl.text,
      rows: _rows,
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
      maxHeightFactor: 0.94,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Inbound Shipment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Line items are restocked into inventory when the shipment is marked received.',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Supplier>(
                          value: _selectedSupplier,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Supplier',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items:
                              widget.suppliers
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _selectedSupplier = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _invoiceCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Invoice #',
                            hintText: 'INV-XXXXX',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LINE ITEMS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black45,
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            () =>
                                setState(() => _rows = [..._rows, _emptyRow()]),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Add Item',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...List.generate(_rows.length, (i) => _rowCard(i)),
                ],
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
                onPressed:
                    (_selectedSupplier == null || _submitting) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    _submitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'LOG SHIPMENT (IN TRANSIT)',
                          style: TextStyle(
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

  Widget _rowCard(int i) {
    final row = _rows[i];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: row.drugId.isEmpty ? null : row.drugId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Drug',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items:
                      widget.inventory
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(
                                d.brandName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    final d = widget.inventory.firstWhereOrNull(
                      (x) => x.id == v,
                    );
                    setState(
                      () =>
                          _rows[i] = row.copyWith(
                            drugId: v ?? '',
                            drugName: d?.brandName ?? '',
                          ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed:
                    _rows.length > 1
                        ? () =>
                            setState(() => _rows = List.of(_rows)..removeAt(i))
                        : null,
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('qty_$i'),
                  initialValue: row.quantity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (v) =>
                          _rows[i] = row.copyWith(
                            quantity: int.tryParse(v) ?? 1,
                          ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey('batch_$i'),
                  initialValue: row.batchNumber,
                  decoration: const InputDecoration(
                    labelText: 'Batch #',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _rows[i] = row.copyWith(batchNumber: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickExpiry(i),
                  child: AbsorbPointer(
                    child: TextFormField(
                      key: ValueKey('expiry_$i'),
                      controller: TextEditingController(text: row.expiryDate),
                      decoration: const InputDecoration(
                        labelText: 'Expiry',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey('cost_$i'),
                  initialValue: row.unitCost.toString(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cost',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (v) =>
                          _rows[i] = row.copyWith(
                            unitCost: double.tryParse(v) ?? 0,
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
