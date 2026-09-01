import 'package:flutter/material.dart';
import 'sheet_scaffold.dart';

class SopSheet extends StatefulWidget {
  const SopSheet({super.key, required this.type, required this.onSubmit});
  final String type;
  final void Function({
    required String type,
    required double? fridgeTemp,
    required double? roomTemp,
  })
  onSubmit;

  @override
  State<SopSheet> createState() => _SopSheetState();
}

class _SopSheetState extends State<SopSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fridgeCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();

  @override
  void dispose() {
    _fridgeCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      maxHeightFactor: 0.65,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF17A673)),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.type} Operational SOP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Regulatory checklist for daily pharmacy management.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fridgeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Fridge Temp (°C)',
                        hintText: 'e.g. 4.2',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _roomCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Room Temp (°C)',
                        hintText: 'e.g. 22.5',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _loggedRow('Expiry Report (3-6mo) Generated'),
              const SizedBox(height: 8),
              _loggedRow('Narcotics Count Reconciliation Done'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    widget.onSubmit(
                      type: widget.type,
                      fridgeTemp: double.tryParse(_fridgeCtrl.text),
                      roomTemp: double.tryParse(_roomCtrl.text),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'LOG COMPLETION',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loggedRow(String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF17A673).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'LOGGED',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Color(0xFF17A673),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
