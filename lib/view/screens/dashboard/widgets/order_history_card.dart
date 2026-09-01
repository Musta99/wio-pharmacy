import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/utils/format.dart';
import 'sheet_scaffold.dart';
import 'invoice_sheet.dart';

class OrderHistorySheet extends StatelessWidget {
  const OrderHistorySheet({super.key, required this.orders});
  final List<PharmaOrder> orders;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text('Transaction Logs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Historical audit of all pharmacy sales.',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: orders.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text('No transaction history found.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black38)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final order = orders[i];
                      final isCompleted = order.status == OrderStatus.completed;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isCompleted ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(order.status.label,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                ),
                                Text('ID: ${order.id.substring(order.id.length - 8)}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black38)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(order.patientName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${order.items.length} ITEMS • ${order.paymentMethod}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black45)),
                                Text(formatBdt(order.total),
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF17A673))),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateTime.parse(order.createdAt).toLocal().toString().split(' ').first,
                                  style: const TextStyle(fontSize: 9, color: Colors.black38),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => InvoiceSheet(order: order),
                                    );
                                  },
                                  child: const Text('VIEW INVOICE',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}