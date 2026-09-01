import 'package:flutter/material.dart';
import 'package:wio_pharmacy/utils/format.dart';
import 'sheet_scaffold.dart';

class QuoteSheet extends StatefulWidget {
  const QuoteSheet({super.key, required this.onSend});
  final void Function(double subtotal) onSend;

  @override
  State<QuoteSheet> createState() => _QuoteSheetState();
}

class _QuoteSheetState extends State<QuoteSheet> {
  final _ctrl = TextEditingController();
  double get _subtotal => double.tryParse(_ctrl.text) ?? 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      maxHeightFactor: 0.6,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: StatefulBuilder(
          builder:
              (context, setSheetState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send Price Quote',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter items cost after Rx review.',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ITEMS SUBTOTAL (BDT)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setSheetState(() {}),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF17A673),
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Est. VAT (5%)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatBdt(_subtotal * 0.05),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Final Quote',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              formatBdt(_subtotal * 1.05),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF17A673),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _subtotal > 0
                              ? () {
                                widget.onSend(_subtotal);
                                Navigator.pop(context);
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'POST QUOTE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
