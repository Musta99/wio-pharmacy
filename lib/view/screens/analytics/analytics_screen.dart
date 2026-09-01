import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/payout_request.dart';
import 'package:wio_pharmacy/models/transaction_record.dart';
import 'package:wio_pharmacy/utils/format.dart';
import 'package:wio_pharmacy/viewmodel/analytics/analytics_view_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _viewModel = AnalyticsViewModel();

  static const navy = Color(0xFF0E1B33);
  static const coral = Color(0xFFFF5A45);
  static const mint = Color(0xFF17A673);

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Widget _pendingPayoutNote(PayoutRequest payout) {
    final date = DateTime.tryParse(payout.timestamp);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.access_time_filled, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout of ${formatBdt(payout.amount)} awaiting review',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                  ),
                ),
                if (date != null)
                  Text(
                    'Requested ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} — your balance updates once the WIO Treasury approves it.',
                    style: const TextStyle(fontSize: 9, color: Colors.white54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pharmacy Intelligence',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: vm.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: mint.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PLATFORM FEE: ${vm.config.platformFeePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: mint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _walletCard(vm),
                const SizedBox(height: 16),
                _policyCard(vm),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _statCard(
                      'Gross Sales',
                      formatBdt(vm.totalGross),
                      Icons.attach_money,
                      mint,
                    ),
                    _statCard(
                      'Store Orders',
                      '${vm.completedCount}',
                      Icons.shopping_bag_outlined,
                      mint,
                    ),
                    _statCard(
                      'Audit Ledger',
                      '${vm.recentSettlements.length}',
                      Icons.receipt_long_outlined,
                      mint,
                    ),
                    _statCard(
                      'Low Stock',
                      '${vm.lowStockCount}',
                      Icons.inventory_2_outlined,
                      coral,
                      isAlert: vm.lowStockCount > 0,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _revenueChartCard(vm),
                const SizedBox(height: 20),
                _settlementCard(vm),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _walletCard(AnalyticsViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DIGITAL VENDOR WALLET',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatBdt(vm.wallet.currentBalance),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SYNCED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _walletStat(
                        'Withdrawable',
                        formatBdt(vm.wallet.withdrawableBalance),
                        Colors.greenAccent,
                      ),
                    ),
                    Expanded(
                      child: _walletStat(
                        'Lifetime Earnings',
                        formatBdt(vm.totalNet),
                        Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _walletStat(
                        'Your Share',
                        '${(100 - vm.config.platformFeePercentage).toStringAsFixed(0)}%',
                        mint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.05),
          //     borderRadius: const BorderRadius.vertical(
          //       bottom: Radius.circular(24),
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: ElevatedButton(
          //           onPressed: vm.isWithdrawing ? null : vm.requestWithdraw,
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: mint,
          //             padding: const EdgeInsets.symmetric(vertical: 12),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(14),
          //             ),
          //           ),
          //           child:
          //               vm.isWithdrawing
          //                   ? const SizedBox(
          //                     height: 16,
          //                     width: 16,
          //                     child: CircularProgressIndicator(
          //                       strokeWidth: 2,
          //                       color: Colors.white,
          //                     ),
          //                   )
          //                   : const Text(
          //                     'REQUEST PAYOUT',
          //                     style: TextStyle(
          //                       fontSize: 11,
          //                       fontWeight: FontWeight.w900,
          //                       color: Colors.white,
          //                     ),
          //                   ),
          //         ),
          //       ),
          //       const SizedBox(width: 10),
          //       Expanded(
          //         child: OutlinedButton(
          //           onPressed:
          //               () {}, // hook up to a ledger detail sheet/screen if desired
          //           style: OutlinedButton.styleFrom(
          //             side: const BorderSide(color: Colors.white24),
          //             padding: const EdgeInsets.symmetric(vertical: 12),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(14),
          //             ),
          //           ),
          //           child: const Text(
          //             'VIEW LEDGER',
          //             style: TextStyle(
          //               fontSize: 11,
          //               fontWeight: FontWeight.w900,
          //               color: Colors.white,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.pendingPayout != null) ...[
                  _pendingPayoutNote(vm.pendingPayout!),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (vm.isWithdrawing || !vm.canRequestPayout)
                                ? null
                                : vm.requestWithdraw,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              vm.canRequestPayout ? mint : Colors.white24,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child:
                            vm.isWithdrawing
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  vm.canRequestPayout
                                      ? 'REQUEST PAYOUT'
                                      : 'PAYOUT PENDING',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'VIEW LEDGER',
                          style: TextStyle(
                            fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _walletStat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          color: Colors.white38,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    ],
  );

  Widget _policyCard(AnalyticsViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, size: 16, color: mint),
              SizedBox(width: 8),
              Text(
                'MARKETPLACE POLICY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Admin has set platform fee to '),
                TextSpan(
                  text:
                      '${vm.config.platformFeePercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: mint,
                  ),
                ),
                const TextSpan(text: '. Min. purchase for online orders is '),
                TextSpan(
                  text: formatBdt(vm.config.minPurchaseAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: mint,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MARKETPLACE NODE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.black45,
                ),
              ),
              const Text(
                'VERIFIED',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'THRESHOLD',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.black45,
                ),
              ),
              Text(
                formatBdt(vm.config.payoutThresholdBdt),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isAlert ? coral : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueChartCard(AnalyticsViewModel vm) {
    final data = vm.dailyRevenueData;
    final maxY =
        (data.map((d) => d.revenue).fold(0.0, (a, b) => a > b ? a : b)) * 1.2;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day Revenue Map',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const Text(
            'Dynamic daily sales across verified fulfillment channels.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 100 : maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (_) => FlLine(
                        color: Colors.black.withOpacity(0.05),
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[i].day,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black45,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      data.length,
                      (i) => FlSpot(i.toDouble(), data[i].revenue),
                    ),
                    isCurved: true,
                    color: mint,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: mint.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems:
                        (spots) =>
                            spots
                                .map(
                                  (s) => LineTooltipItem(
                                    formatBdt(s.y),
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                                .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settlementCard(AnalyticsViewModel vm) {
    final settlements = vm.recentSettlements;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Settlement Audit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Your verified share of recent marketplace transactions.',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          if (settlements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No recent settlements found.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black38,
                  ),
                ),
              ),
            )
          else
            ...settlements.map((r) => _settlementRow(r)),
          if (settlements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'VIEW FULL LEDGER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _settlementRow(TransactionRecord r) {
    final date = DateTime.tryParse(r.timestamp);
    final statusColor = switch (r.status) {
      SettlementStatus.settled => Colors.green,
      SettlementStatus.hold => Colors.amber.shade700,
      SettlementStatus.withdrawn => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${r.orderId.length >= 5 ? r.orderId.substring(r.orderId.length - 5) : r.orderId}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.black45,
                  ),
                ),
                if (date != null)
                  Text(
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 8, color: Colors.black26),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              formatBdt(r.totalAmount),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              '+${formatBdt(r.vendorEarning)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: mint,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              r.status.label,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
