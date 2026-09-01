import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/utils/format.dart';
import 'package:wio_pharmacy/utils/invoice_pdf.dart';
import 'package:wio_pharmacy/viewmodel/navigation_view_model.dart';
import 'package:wio_pharmacy/viewmodel/sales/sales_view_model.dart';
import 'widgets/payout_sheet.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _viewModel = SalesViewModel();
  NavigationViewModel? _navVM;
  int _lastLoadedIndex = -1;
  static const _tabIndex =
      3; // matches SalesScreen's position in MainContainerScreen._screens

  static const navy = Color(0xFF0E1B33);
  static const mint = Color(0xFF17A673);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navVM?.removeListener(_onNavChanged);
    _navVM = context.read<NavigationViewModel>();
    _navVM!.addListener(_onNavChanged);
    _onNavChanged();
  }

  void _onNavChanged() {
    if (_navVM!.selectedIndex == _tabIndex && _lastLoadedIndex != _tabIndex) {
      _lastLoadedIndex = _tabIndex;
      _viewModel.load();
    } else if (_navVM!.selectedIndex != _tabIndex) {
      _lastLoadedIndex = -1;
    }
  }

  @override
  void dispose() {
    _navVM?.removeListener(_onNavChanged);
    _viewModel.dispose();
    super.dispose();
  }

  // void _openPayoutSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder:
  //         (_) => ListenableBuilder(
  //           listenable: _viewModel,
  //           builder:
  //               (context, _) => PayoutSheet(
  //                 wallet: _viewModel.wallet,
  //                 submitting: _viewModel.submittingPayout,
  //                 onSubmit: _viewModel.requestPayout,
  //               ),
  //         ),
  //   );
  // }

  void _openPayoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ListenableBuilder(
            listenable: _viewModel,
            builder:
                (context, _) => PayoutSheet(
                  wallet: _viewModel.wallet,
                  submitting: _viewModel.submittingPayout,
                  pendingPayout: _viewModel.pendingPayout,
                  onSubmit: _viewModel.requestPayout,
                ),
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
          'Sales Ledger',
          style: TextStyle(color: navy, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          if (vm.isLoading && vm.wallet == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: vm.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _walletCard(vm),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Total Revenue',
                        formatBdt(vm.totalRevenue),
                        mint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        'Transactions',
                        '${vm.completedSales.length}',
                        navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _statCard(
                  'Avg. Ticket Size',
                  formatBdt(vm.avgTicketSize),
                  navy,
                  fullWidth: true,
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Icon(Icons.shopping_cart_outlined, size: 18, color: navy),
                    SizedBox(width: 8),
                    Text(
                      'Recent Sales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (vm.completedSales.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No sales records found for this period.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  )
                else
                  ...vm.completedSales.map((order) => _saleRow(order, vm)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _walletCard(SalesViewModel vm) {
    final wallet = vm.wallet;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: mint,
              ),
              SizedBox(width: 8),
              Text(
                'Wallet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Text(
            'Your withdrawable earnings from completed orders.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _walletStat(
                  'Current Balance',
                  formatBdt(wallet?.currentBalance ?? 0),
                ),
              ),
              Expanded(
                child: _walletStat(
                  'Withdrawable',
                  formatBdt(wallet?.withdrawableBalance ?? 0),
                  highlight: true,
                ),
              ),
              Expanded(
                child: _walletStat(
                  'Withdrawn',
                  formatBdt(wallet?.totalWithdrawn ?? 0),
                ),
              ),
            ],
          ),
          if (vm.isOwner) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (wallet == null ||
                            wallet.withdrawableBalance <= 0 ||
                            !vm.canRequestPayout)
                        ? null
                        : _openPayoutSheet,

                style: ElevatedButton.styleFrom(
                  backgroundColor: mint,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Request Payout',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _walletStat(String label, String value, {bool highlight = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.black45),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: highlight ? mint : Colors.black87,
            ),
          ),
        ],
      );

  Widget _statCard(
    String label,
    String value,
    Color color, {
    bool fullWidth = false,
  }) => Container(
    width: fullWidth ? double.infinity : null,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _saleRow(PharmaOrder order, SalesViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.patientName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#${order.id.substring(order.id.length - 5)}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black38,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateTime.parse(order.createdAt).toLocal().toString().split(' ').first} · ${order.items.length} item(s)',
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            formatBdt(order.total),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: mint,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => printSalesInvoice(order, vm.profile),
            icon: const Icon(Icons.print, size: 13),
            label: const Text(
              'Invoice',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
