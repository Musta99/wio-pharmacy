import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/utils/format.dart';
import 'package:wio_pharmacy/view/screens/inventory/widgets/delete_confirm_sheet.dart';
import 'package:wio_pharmacy/view/screens/inventory/widgets/drug_form_sheet.dart';
import 'package:wio_pharmacy/view/screens/inventory/widgets/stock_in_sheet.dart';
import 'package:wio_pharmacy/viewmodel/inventory/inventory_view_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _viewModel = InventoryViewModel();
  final _searchCtrl = TextEditingController();

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
    _searchCtrl.dispose();
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
          'Automated Registry',
          style: TextStyle(color: navy, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          return RefreshIndicator(
            onRefresh: vm.load,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          onChanged: vm.setSearch,
                          decoration: InputDecoration(
                            hintText: 'Search Brand or Generic...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    () => _openSheet(
                                      StockInSheet(
                                        inventory: vm.all,
                                        onSubmit:
                                            (id, batch) =>
                                                vm.stockIn(id, batch),
                                      ),
                                    ),
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'STOCK-IN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                                      DrugFormSheet(
                                        onSubmit: (draft) => vm.saveDrug(draft),
                                      ),
                                    ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                ),
                                label: const Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mint,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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
                if (vm.isLoading && vm.all.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (vm.filtered.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No medicines found in the registry.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final drug = vm.filtered[i];
                        return _DrugCard(
                          drug: drug,
                          onEdit:
                              () => _openSheet(
                                DrugFormSheet(
                                  editingDrug: drug,
                                  onSubmit:
                                      (draft) => vm.saveDrug(
                                        draft,
                                        editingId: drug.id,
                                      ),
                                ),
                              ),
                          onStockIn:
                              () => _openSheet(
                                StockInSheet(
                                  inventory: vm.all,
                                  preselectedId: drug.id,
                                  onSubmit:
                                      (id, batch) => vm.stockIn(id, batch),
                                ),
                              ),
                          onDelete:
                              () => _openSheet(
                                DeleteConfirmSheet(
                                  drugName: drug.brandName,
                                  onConfirm: () => vm.deleteDrug(drug.id),
                                ),
                              ),
                        );
                      }, childCount: vm.filtered.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DrugCard extends StatelessWidget {
  const _DrugCard({
    required this.drug,
    required this.onEdit,
    required this.onStockIn,
    required this.onDelete,
  });

  final Drug drug;
  final VoidCallback onEdit;
  final VoidCallback onStockIn;
  final VoidCallback onDelete;

  static const mint = Color(0xFF17A673);

  @override
  Widget build(BuildContext context) {
    final lowStock = drug.stock.current < drug.stock.min;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 74,
            width: double.infinity,
            decoration: BoxDecoration(
              color: mint.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        drug.brandName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            drug.category == 'Rx' ? Colors.red : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        drug.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  drug.genericName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat(
                          'FORM',
                          '${drug.form} • ${drug.strength}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat(
                          'SHELF',
                          '${drug.storage.zone}-${drug.storage.shelf}',
                        ),
                      ),
                      Expanded(
                        child: _miniStat(
                          'TEMP',
                          drug.storage.condition,
                          color: mint,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MRP',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.black38,
                              ),
                            ),
                            Text(
                              formatBdt(drug.pricing.mrp),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: mint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'STOCK',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.black38,
                            ),
                          ),
                          Text(
                            '${drug.stock.current}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: lowStock ? Colors.red : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'SKU: ${drug.sku}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 18),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'stock') onStockIn();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            'Edit Registry Data',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'stock',
                          child: Text(
                            'Log Purchase Batch',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Retract from Registry',
                            style: TextStyle(fontSize: 12, color: Colors.red),
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

  Widget _miniStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
