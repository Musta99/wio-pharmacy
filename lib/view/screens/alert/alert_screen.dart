import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/inventory_alert.dart';
import 'package:wio_pharmacy/viewmodel/alert/alert_view_model.dart';
import 'package:wio_pharmacy/viewmodel/navigation_view_model.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final _viewModel = AlertViewModel();
  NavigationViewModel? _navVM;
  int _lastLoadedIndex = -1;
  static const _tabIndex =
      5; // adjust to AlertScreen's actual position, if it's a tab at all

  static const navy = Color(0xFF0E1B33);
  static const coral = Color(0xFFFF5A45);
  static const mint = Color(0xFF17A673);
  static const amber = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    // If this screen is reached via push (not a bottom-nav tab), load directly.
    _viewModel.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If AlertScreen IS a bottom-nav tab, uncomment this block and remove the
    // direct load() call in initState above — same tab-reload pattern as
    // Inventory/Sales/Suppliers.
    //
    // _navVM?.removeListener(_onNavChanged);
    // _navVM = context.read<NavigationViewModel>();
    // _navVM!.addListener(_onNavChanged);
    // _onNavChanged();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: navy, size: 20),
            SizedBox(width: 8),
            Text(
              'Inventory Intelligence',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: mint.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIVE STATUS: MONITORING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: mint,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _automationEngineCard(vm),
                const SizedBox(height: 20),

                _sectionHeader(
                  'Critical Level (At/Below Min Stock)',
                  Icons.warning_amber,
                  coral,
                  vm.criticalItems.length,
                ),
                const SizedBox(height: 10),
                if (vm.criticalItems.isEmpty)
                  _emptyState('No items in critical low stock')
                else
                  ...vm.criticalItems.map(
                    (Drug item) => _criticalCard(vm, item),
                  ),

                const SizedBox(height: 24),
                _sectionHeader(
                  'Approaching Min Stock',
                  Icons.access_time,
                  amber,
                  vm.lowStockItems.length,
                ),
                const SizedBox(height: 10),
                if (vm.lowStockItems.isEmpty)
                  _emptyState('No secondary stock alerts found.')
                else
                  ...vm.lowStockItems.map((Drug item) => _watchlistCard(item)),

                const SizedBox(height: 24),
                _sectionHeader(
                  'Expired Batches',
                  Icons.block,
                  coral,
                  vm.expiredBatches.length,
                ),
                const SizedBox(height: 10),
                if (vm.expiredBatches.isEmpty)
                  _emptyState('No expired batches on hand.')
                else
                  ...vm.expiredBatches.map((ExpiryAlert b) => _expiredCard(b)),

                const SizedBox(height: 24),
                _sectionHeader(
                  'Expiring Within ${kExpiryWarningDays}d',
                  Icons.calendar_month,
                  amber,
                  vm.expiringSoonBatches.length,
                ),
                const SizedBox(height: 10),
                if (vm.expiringSoonBatches.isEmpty)
                  _emptyState('No batches expiring soon.')
                else
                  ...vm.expiringSoonBatches.map(
                    (ExpiryAlert b) => _expiringSoonCard(b),
                  ),

                const SizedBox(height: 24),
                _sectionHeader(
                  'Smart Reorder Suggestions',
                  Icons.bolt,
                  mint,
                  vm.reorderSuggestions.length,
                ),
                const SizedBox(height: 10),
                if (vm.reorderSuggestions.isEmpty)
                  _emptyState('No reorder suggestions right now.')
                else
                  ...vm.reorderSuggestions.map(
                    (ReorderSuggestion s) => _reorderCard(vm, s),
                  ),

                const SizedBox(height: 24),
                _alertSopCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count ITEMS',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.black38,
        ),
      ),
    ),
  );

  Widget _criticalCard(AlertViewModel vm, Drug item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: coral.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: coral.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: coral, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brandName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(text: '${item.genericName} • Only '),
                      TextSpan(
                        text: '${item.stock.current}',
                        style: TextStyle(
                          color: coral,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' left in stock'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => vm.triggerReorder(item.brandName),
            style: ElevatedButton.styleFrom(
              backgroundColor: coral,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text(
              'REORDER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _watchlistCard(Drug item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medication_outlined, color: amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${item.stock.current} units remaining',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: amber.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'WATCHLIST',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiredCard(ExpiryAlert b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: coral.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: coral, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${b.brandName} • Batch ${b.batchNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Expired ${b.daysUntilExpiry.abs()} day(s) ago (${b.expiryDate}) • ${b.quantity} units — must not be dispensed',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiringSoonCard(ExpiryAlert b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month_outlined, color: amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Batch ${b.batchNumber} • ${b.quantity} units • expires in ${b.daysUntilExpiry}d',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reorderCard(AlertViewModel vm, ReorderSuggestion s) {
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
                Text(
                  s.brandName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    '${s.currentStock} in stock',
                    if (s.dailyVelocity > 0)
                      '~${s.dailyVelocity.toStringAsFixed(1)}/day',
                    if (s.daysOfStockLeft != null)
                      '~${s.daysOfStockLeft}d of stock left',
                    if (s.reason == 'below-min') 'at/below Min Stock',
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed:
                () => vm.triggerReorder(
                  s.brandName,
                  suggestedQty: s.suggestedQty,
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: mint,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Text(
              'Reorder ${s.suggestedQty}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _automationEngineCard(AlertViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Automation Engine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const Text(
            'Configure how WioCare handles stock shortages.',
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          _automationSwitch(
            Icons.refresh,
            'AUTO-REORDER',
            'Restock at 15% threshold.',
            vm.autoReorder,
            vm.setAutoReorder,
          ),
          const SizedBox(height: 10),
          _automationSwitch(
            Icons.notifications_active_outlined,
            'SMS ALERTS',
            'Notify Head Pharmacist.',
            vm.smsAlerts,
            vm.setSmsAlerts,
          ),
          const SizedBox(height: 10),
          _automationSwitch(
            Icons.manage_accounts_outlined,
            'SUBSTITUTION',
            'Suggest verified generics.',
            vm.substitution,
            vm.setSubstitution,
          ),
        ],
      ),
    );
  }

  Widget _automationSwitch(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 12, color: mint),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: Colors.white38),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: mint),
        ],
      ),
    );
  }

  Widget _alertSopCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: mint, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'ALERT SOP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Alerts are calculated based on your "Min Stock" registry settings. Critical alerts (at or below Min Stock) bypass normal approval loops and trigger immediate restock flags in the procurement ledger.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}
