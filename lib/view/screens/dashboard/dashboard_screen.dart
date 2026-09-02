import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/app_drawer.dart';
import 'package:wio_pharmacy/view/screens/dashboard/widgets/order_history_card.dart';
import 'package:wio_pharmacy/viewmodel/dashboard/dashboard_view_model.dart';
import 'widgets/dispatch_panel.dart';
import 'widgets/order_card.dart';
import 'widgets/sop_sheet.dart';
import 'widgets/alert_detail_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _viewModel = DashboardViewModel();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.start();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _openBottomSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0E1B33);
    const coral = Color(0xFFFF5A45);
    const mint = Color(0xFF17A673);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
          endDrawer: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => AppDrawer(
          pharmacyName: _viewModel.pharmacyName,
          pharmacyLogoUrl: _viewModel.pharmacyLogoUrl,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pharmacy Ops & POS',
          style: TextStyle(color: navy, fontWeight: FontWeight.w900),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: navy),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => IconButton(
              icon: const Icon(Icons.history, color: navy),
              onPressed: () => _openBottomSheet(
                OrderHistorySheet(orders: _viewModel.orderHistory),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: mint,
          unselectedLabelColor: Colors.black45,
          indicatorColor: mint,
          tabs: const [
            Tab(text: 'ONLINE QUEUE'),
            Tab(text: 'PRESCRIPTION AI'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersTab(context, coral, mint),
              const Center(child: Text('Prescription AI module goes here')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersTab(BuildContext context, Color coral, Color mint) {
    final vm = _viewModel;
    return RefreshIndicator(
      onRefresh: () async => vm.start(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSopAndAlertRow(vm, coral),
          const SizedBox(height: 20),
          _sectionHeader('Incoming Requests', '${vm.pendingOrders.length} NEW'),
          const SizedBox(height: 12),
          if (vm.isLoadingOrders && vm.pendingOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vm.pendingOrders.isEmpty)
            _emptyState(
              'System Clear: No Pending Orders',
              Icons.shopping_bag_outlined,
            )
          else
            ...vm.pendingOrders.map(
              (o) => OrderCard(
                order: o,
                onAccept: () => vm.updateStatus(o.id, OrderStatus.processing),
                onSendQuote: (subtotal) => vm.sendQuote(o.id, subtotal),
              ),
            ),
          const SizedBox(height: 24),
          DispatchPanel(jobs: vm.dispatchableDeliveries),
          const SizedBox(height: 24),
          _sectionHeader(
            'Active Logistics',
            '${vm.activeOrders.length} ACTIVE',
          ),
          const SizedBox(height: 12),
          if (vm.activeOrders.isEmpty)
            _emptyState('No Active Fulfillment', Icons.local_shipping_outlined)
          else
            ...vm.activeOrders.map(
              (o) => OrderCard(
                order: o,
                onUpdate: (status) => vm.updateStatus(o.id, status),
                onAssignRider: (d) => vm.assignRider(o.id, d),
                onVerifyRx: vm.verifyRx,
                canVerifyRx: vm.canVerifyRx,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSopAndAlertRow(DashboardViewModel vm, Color coral) {
    final morning = vm.checkFor('Morning');
    final evening = vm.checkFor('Evening');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (morning == null)
          _pillButton(
            'MORNING SOP PENDING',
            Colors.orange,
            () => _openBottomSheet(
              SopSheet(type: 'Morning', onSubmit: vm.logSopCheck),
            ),
          ),
        if (morning != null && evening == null)
          _pillButton(
            'EVENING SOP PENDING',
            Colors.blue,
            () => _openBottomSheet(
              SopSheet(type: 'Evening', onSubmit: vm.logSopCheck),
            ),
          ),
        if (vm.coldChainItems.isNotEmpty)
          _pillButton(
            'COLD CHAIN (${vm.coldChainItems.length})',
            coral,
            () => _openBottomSheet(
              AlertDetailSheet(title: 'Cold Chain', items: vm.coldChainItems),
            ),
            filled: true,
          ),
        if (vm.reorderItems.isNotEmpty)
          _pillButton(
            'REORDER (${vm.reorderItems.length})',
            Colors.amber.shade700,
            () => _openBottomSheet(
              AlertDetailSheet(title: 'Reorder', items: vm.reorderItems),
            ),
            filled: true,
          ),
      ],
    );
  }

  Widget _pillButton(
    String label,
    Color color,
    VoidCallback onTap, {
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: filled ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.black26),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
