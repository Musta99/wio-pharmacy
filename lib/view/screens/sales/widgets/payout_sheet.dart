// import 'package:flutter/material.dart';
// import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
// import 'package:wio_pharmacy/utils/format.dart';
// import 'package:wio_pharmacy/view/screens/dashboard/widgets/sheet_scaffold.dart';

// class PayoutSheet extends StatefulWidget {
//   const PayoutSheet({
//     super.key,
//     required this.wallet,
//     required this.onSubmit,
//     required this.submitting,
//   });
//   final PharmacyWallet? wallet;
//   final Future<bool> Function(double amount) onSubmit;
//   final bool submitting;

//   @override
//   State<PayoutSheet> createState() => _PayoutSheetState();
// }

// class _PayoutSheetState extends State<PayoutSheet> {
//   final _ctrl = TextEditingController();

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     const mint = Color(0xFF17A673);
//     final withdrawable = widget.wallet?.withdrawableBalance ?? 0;
//     final threshold = widget.wallet?.config?.payoutThresholdBdt;

//     return SheetScaffold(
//       maxHeightFactor: 0.55,
//       child: Padding(
//         padding: EdgeInsets.fromLTRB(
//           20,
//           8,
//           20,
//           MediaQuery.of(context).padding.bottom + 20,
//         ),
//         child: StatefulBuilder(
//           builder:
//               (context, setSheetState) => Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Request Payout',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Withdrawable balance: ${formatBdt(withdrawable)}${threshold != null ? ' · Minimum ${formatBdt(threshold)}' : ''}',
//                     style: const TextStyle(fontSize: 12, color: Colors.black45),
//                   ),
//                   const SizedBox(height: 20),
//                   const Text(
//                     'AMOUNT (BDT)',
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w900,
//                       color: Colors.black45,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   TextField(
//                     controller: _ctrl,
//                     keyboardType: const TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                     onChanged: (_) => setSheetState(() {}),
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w900,
//                     ),
//                     decoration: const InputDecoration(
//                       hintText: '0.00',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 52,
//                     child: ElevatedButton(
//                       onPressed:
//                           widget.submitting
//                               ? null
//                               : () async {
//                                 final amount = double.tryParse(_ctrl.text) ?? 0;
//                                 final ok = await widget.onSubmit(amount);
//                                 if (ok && context.mounted)
//                                   Navigator.pop(context);
//                               },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: mint,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                       ),
//                       child:
//                           widget.submitting
//                               ? const SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                               : const Text(
//                                 'SUBMIT REQUEST',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w900,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                     ),
//                   ),
//                 ],
//               ),
//         ),
//       ),
//     );
//   }
// }

// ---------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/payout_request.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
import 'package:wio_pharmacy/utils/format.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/sheet_scaffold.dart';

class PayoutSheet extends StatefulWidget {
  const PayoutSheet({
    super.key,
    required this.wallet,
    required this.onSubmit,
    required this.submitting,
    this.pendingPayout,
  });

  final PharmacyWallet? wallet;
  final Future<bool> Function(double amount) onSubmit;
  final bool submitting;
  final PayoutRequest? pendingPayout;

  @override
  State<PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends State<PayoutSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF17A673);
    final withdrawable = widget.wallet?.withdrawableBalance ?? 0;
    final hasPending = widget.pendingPayout != null;

    return SheetScaffold(
      maxHeightFactor: 0.6,
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
                    'Request Payout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Withdrawable balance: ${formatBdt(withdrawable)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  if (hasPending) ...[
                    const SizedBox(height: 16),
                    _pendingNote(widget.pendingPayout!),
                  ] else ...[
                    const SizedBox(height: 20),
                    const Text(
                      'AMOUNT (BDT)',
                      style: TextStyle(
                        fontSize: 9,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          (widget.submitting || hasPending)
                              ? null
                              : () async {
                                final amount = double.tryParse(_ctrl.text) ?? 0;
                                final ok = await widget.onSubmit(amount);
                                if (ok && context.mounted)
                                  Navigator.pop(context);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasPending ? Colors.black26 : mint,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          widget.submitting
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                hasPending
                                    ? 'PAYOUT PENDING'
                                    : 'SUBMIT REQUEST',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
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

  Widget _pendingNote(PayoutRequest payout) {
    final date = DateTime.tryParse(payout.timestamp);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.access_time_filled, size: 16, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout of ${formatBdt(payout.amount)} awaiting review',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                  ),
                ),
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Requested ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} — your balance updates once the WIO Treasury approves it.',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
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
}
