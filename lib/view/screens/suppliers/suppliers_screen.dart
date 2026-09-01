import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wio_pharmacy/models/shipment.dart';
import 'package:wio_pharmacy/models/supplier.dart';
import 'package:wio_pharmacy/viewmodel/navigation_view_model.dart';
import 'package:wio_pharmacy/viewmodel/suppliers/suppliers_view_model.dart';
import 'widgets/supplier_form_sheet.dart';
import 'widgets/new_shipment_sheet.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _viewModel = SuppliersViewModel();
  NavigationViewModel? _navVM;
  int _lastLoadedIndex = -1;
  static const _tabIndex =
      2; // adjust to SuppliersScreen's actual position in _screens

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

  void _openSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
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
          'Suppliers & Procurement',
          style: TextStyle(color: navy, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          if (vm.isLoading && vm.suppliers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: vm.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _openSheet(
                              NewShipmentSheet(
                                suppliers: vm.suppliers,
                                inventory: vm.inventory,
                                onSubmit:
                                    ({
                                      required supplierId,
                                      required supplierName,
                                      required invoiceNumber,
                                      required rows,
                                    }) => vm.submitShipment(
                                      supplierId: supplierId,
                                      supplierName: supplierName,
                                      invoiceNumber: invoiceNumber,
                                      rows: rows,
                                    ),
                              ),
                            ),
                        icon: const Icon(Icons.inventory_2_outlined, size: 16),
                        label: const Text(
                          'NEW SHIPMENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => _openSheet(
                              SupplierFormSheet(
                                onSubmit: (draft) => vm.saveSupplier(draft),
                              ),
                            ),
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'REGISTER SUPPLIER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mint,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (vm.suppliers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No suppliers registered.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: vm.suppliers.length,
                    itemBuilder: (context, i) {
                      final s = vm.suppliers[i];
                      return _SupplierCard(
                        supplier: s,
                        onEdit:
                            () => _openSheet(
                              SupplierFormSheet(
                                editingSupplier: s,
                                onSubmit:
                                    (draft) =>
                                        vm.saveSupplier(draft, editingId: s.id),
                              ),
                            ),
                        onDelete: () => _confirmDelete(context, vm, s),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Icon(Icons.local_shipping_outlined, size: 18, color: navy),
                    SizedBox(width: 8),
                    Text(
                      'Recent Procurement Invoices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (vm.shipments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No shipments logged yet.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  )
                else
                  ...vm.shipments.map((sh) => _shipmentRow(sh, vm)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, SuppliersViewModel vm, Supplier s) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Vendor Retraction'),
            content: Text(
              'Are you sure you want to retract "${s.name}" from the WIO network? Existing invoices will remain in audit.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BACK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  vm.deleteSupplier(s.id);
                },
                child: const Text(
                  'CONFIRM RETRACTION',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _shipmentRow(Shipment sh, SuppliersViewModel vm) {
    final isReceived = sh.status == 'Received';
    final isReceiving = vm.receivingId == sh.id;
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
                      sh.supplierName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isReceived ? Colors.green : Colors.transparent,
                        border:
                            isReceived
                                ? null
                                : Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sh.status,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: isReceived ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${sh.date} · ${sh.invoiceNumber} · ${sh.itemCount} units',
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
          if (sh.canReceive)
            OutlinedButton.icon(
              onPressed: isReceiving ? null : () => vm.receiveShipment(sh.id),
              icon:
                  isReceiving
                      ? const SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.inventory_outlined, size: 13),
              label: Text(
                isReceiving ? 'Receiving…' : 'Receive',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  static const mint = Color(0xFF17A673);

  @override
  Widget build(BuildContext context) {
    final isActive = supplier.status == 'Active';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: mint,
                  size: 18,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.black38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      supplier.status,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 16),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit Profile',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Retract Vendor',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            supplier.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          Text(
            '${supplier.category.toUpperCase()} SUPPLIER',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: mint,
            ),
          ),
          const SizedBox(height: 10),
          _row(Icons.phone, supplier.contact),
          _row(Icons.email_outlined, supplier.email),
          if (supplier.website != null)
            _row(
              Icons.language,
              supplier.website!.replaceFirst('https://', ''),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(icon, size: 11, color: mint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
