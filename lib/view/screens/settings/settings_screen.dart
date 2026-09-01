import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/pharmacy_staff.dart';
import 'package:wio_pharmacy/viewmodel/settings/settings_view_model.dart';
import 'widgets/add_staff_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _viewModel = SettingsViewModel();

  static const navy = Color(0xFF0E1B33);
  static const coral = Color(0xFFFF5A45);
  static const mint = Color(0xFF17A673);

  @override
  void initState() {
    super.initState();
    _viewModel.loadStaff();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _openAddStaffSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddStaffSheet(
            onSubmit:
                ({
                  required name,
                  required email,
                  required password,
                  required subRole,
                }) => _viewModel.createStaff(
                  name: name,
                  email: email,
                  password: password,
                  subRole: subRole,
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
          'Module Settings',
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _staffCard(vm),
              const SizedBox(height: 16),
              _notificationsCard(vm),
              const SizedBox(height: 16),
              _invoicingCard(vm),
              const SizedBox(height: 16),
              _strictProtocolsCard(vm),
              const SizedBox(height: 16),
              _coldChainCard(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: vm.saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SAVE SETTINGS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardShell({
    required String title,
    required IconData icon,
    required Widget child,
    Color? tint,
  }) {
    final color = tint ?? mint;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _staffCard(SettingsViewModel vm) {
    return _cardShell(
      title: 'Staff Accounts',
      icon: Icons.groups_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Give pharmacists, cashiers, inventory managers, and auditors their own restricted login.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAddStaffSheet,
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text(
                'Add Staff Member',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          if (vm.isLoadingStaff)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vm.staff.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "No staff accounts yet — you're the only login for this pharmacy.",
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            )
          else
            ...vm.staff.map((member) => _staffRow(vm, member)),
        ],
      ),
    );
  }

  Widget _staffRow(SettingsViewModel vm, PharmacyStaff member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      member.email,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: member.active ? mint : Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  member.active ? 'Active' : 'Suspended',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PharmacyStaffRole>(
                  value: member.subRole,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      PharmacyStaffRole.values
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) vm.changeRole(member, v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: member.active,
                onChanged: (_) => vm.toggleActive(member),
                activeColor: mint,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notificationsCard(SettingsViewModel vm) {
    return _cardShell(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          _switchTile(
            'New Order SMS Alerts',
            'Ping on-duty pharmacist for every Rx request.',
            vm.newOrderSmsAlerts,
            vm.setNewOrderSmsAlerts,
          ),
          const SizedBox(height: 10),
          _switchTile(
            'Low Stock Notifications',
            'Trigger alerts when drug levels hit reorder points.',
            vm.lowStockNotifications,
            vm.setLowStockNotifications,
          ),
        ],
      ),
    );
  }

  Widget _invoicingCard(SettingsViewModel vm) {
    return _cardShell(
      title: 'Invoicing',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: vm.vatController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'VAT Percentage (%)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: vm.markupBufferController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Markup Buffer (%)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vm.returnPolicyController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Return Policy Footer',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _strictProtocolsCard(SettingsViewModel vm) {
    return _cardShell(
      title: 'Strict Protocols',
      icon: Icons.gpp_maybe_outlined,
      tint: coral,
      child: Column(
        children: [
          _switchTile(
            'Block Expiry Sales',
            null,
            vm.blockExpirySales,
            vm.setBlockExpirySales,
            dense: true,
          ),
          const Divider(),
          _switchTile(
            'Strict FIFO Flow',
            null,
            vm.strictFifoFlow,
            vm.setStrictFifoFlow,
            dense: true,
          ),
          const Divider(),
          _switchTile(
            'Audit Mode (Logged)',
            null,
            vm.auditMode,
            vm.setAuditMode,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _coldChainCard() {
    return _cardShell(
      title: 'Cold Chain',
      icon: Icons.ac_unit_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _ColdChainStat(label: 'MIN TEMP', value: '2°C'),
              _ColdChainStat(label: 'MAX TEMP', value: '8°C', alignEnd: true),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Configure Logger API',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool dense = false,
  }) {
    if (dense) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: coral),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9, color: Colors.black45),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: mint),
        ],
      ),
    );
  }
}

class _ColdChainStat extends StatelessWidget {
  const _ColdChainStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });
  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: Colors.black38,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
