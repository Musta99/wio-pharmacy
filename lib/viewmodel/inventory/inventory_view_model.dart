import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/services/inventory_service.dart';

class InventoryViewModel extends ChangeNotifier {
  InventoryViewModel({InventoryService? service})
    : _service = service ?? InventoryService();

  final InventoryService _service;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  List<Drug> _inventory = [];
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String _searchTerm = '';

  List<Drug> get filtered {
    if (_searchTerm.isEmpty) return _inventory;
    final q = _searchTerm.toLowerCase();
    return _inventory
        .where(
          (d) =>
              d.brandName.toLowerCase().contains(q) ||
              d.genericName.toLowerCase().contains(q) ||
              d.sku.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Drug> get all => _inventory;

  void setSearch(String value) {
    _searchTerm = value;
    _safeNotify();
  }

  Future<void> load() async {
    _isLoading = true;
    _safeNotify();
    try {
      _inventory = await _service.list();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load inventory.');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> saveDrug(Drug draft, {String? editingId}) async {
    try {
      if (editingId != null) {
        await _service.update(editingId, draft.toJson(includeId: false));
        Fluttertoast.showToast(msg: '${draft.brandName} data saved.');
      } else {
        await _service.create(draft);
        Fluttertoast.showToast(msg: '${draft.brandName} added to registry.');
      }
      await load();
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save medicine.');
      return false;
    }
  }

  Future<bool> stockIn(String drugId, DrugBatch batch) async {
    final drug = _inventory.where((d) => d.id == drugId).firstOrNull;
    if (drug == null) return false;
    try {
      await _service.update(drugId, {
        'batches': [...drug.batches.map((b) => b.toJson()), batch.toJson()],
        'stock': {
          'current': drug.stock.current + batch.quantity,
          'min': drug.stock.min,
          'max': drug.stock.max,
        },
      });
      await load();
      Fluttertoast.showToast(
        msg: 'Added ${batch.quantity} units to inventory.',
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to log stock-in.');
      return false;
    }
  }

  Future<bool> deleteDrug(String id) async {
    try {
      await _service.delete(id);
      await load();
      Fluttertoast.showToast(msg: 'Medicine deleted.');
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to delete medicine.');
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
