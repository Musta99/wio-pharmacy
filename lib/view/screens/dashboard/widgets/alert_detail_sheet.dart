import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:wio_pharmacy/models/drug.dart';
import 'sheet_scaffold.dart';

class AlertDetailSheet extends StatelessWidget {
  const AlertDetailSheet({super.key, required this.title, required this.items});
  final String title; // 'Cold Chain' | 'Reorder'
  final List<Drug> items;

  @override
  Widget build(BuildContext context) {
    final color = title == 'Cold Chain' ? Colors.red : Colors.amber.shade800;
    return SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      title == 'Cold Chain'
                          ? Icons.thermostat
                          : Icons.warning_amber,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${title.toUpperCase()} ALERT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Critical items requiring immediate attention. Impacted units: ${items.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.brandName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              item.genericName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ZONE ${item.storage.zone}-${item.storage.shelf}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.stock.current}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color:
                                    item.stock.current < item.stock.min
                                        ? Colors.red
                                        : Colors.black,
                              ),
                            ),
                            Text(
                              'Min: ${item.stock.min}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed:
                            () => Fluttertoast.showToast(
                              msg:
                                  'Replenish request queued for ${item.brandName}.',
                            ),
                        child: const Text(
                          'REPLENISH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'ACKNOWLEDGE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
