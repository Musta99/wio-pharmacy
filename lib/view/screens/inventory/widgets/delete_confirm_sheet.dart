import 'package:flutter/material.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/sheet_scaffold.dart';

class DeleteConfirmSheet extends StatefulWidget {
  const DeleteConfirmSheet({
    super.key,
    required this.drugName,
    required this.onConfirm,
  });
  final String drugName;
  final Future<bool> Function() onConfirm;

  @override
  State<DeleteConfirmSheet> createState() => _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends State<DeleteConfirmSheet> {
  final _ctrl = TextEditingController();
  bool _deleting = false;

  bool get _canConfirm => _ctrl.text.trim().toLowerCase() == 'delete';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _deleting = true);
    final ok = await widget.onConfirm();
    if (mounted) {
      setState(() => _deleting = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      maxHeightFactor: 0.5,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: StatefulBuilder(
          builder:
              (context, setSheetState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verify Retraction',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Removing this drug from the registry will disable online availability. Type ',
                        ),
                        const TextSpan(
                          text: 'delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(text: ' to confirm.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctrl,
                    onChanged: (_) => setSheetState(() {}),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      hintText: 'delete',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _deleting ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'BACK',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (_canConfirm && !_deleting) ? _confirm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              _deleting
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'CONFIRM',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
