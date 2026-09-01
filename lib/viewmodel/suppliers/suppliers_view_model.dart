import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/shipment.dart';
import 'package:wio_pharmacy/models/supplier.dart';
import 'package:wio_pharmacy/services/inventory_service.dart';
import 'package:wio_pharmacy/services/supplier_service.dart';

class SuppliersViewModel extends ChangeNotifier {
  SuppliersViewModel({
    SupplierService? service,
    InventoryService? inventoryService,
  }) : _service = service ?? SupplierService(),
       _inventoryService = inventoryService ?? InventoryService();

  final SupplierService _service;
  final InventoryService _inventoryService;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Supplier> _suppliers = [];
  List<Shipment> _shipments = [];
  List<Drug> _inventory = [];
  String? _receivingId;

  List<Supplier> get suppliers => _suppliers;
  List<Shipment> get shipments => _shipments;
  List<Drug> get inventory => _inventory;
  String? get receivingId => _receivingId;

  Future<void> load() async {
    _isLoading = true;
    _safeNotify();
    try {
      final results = await Future.wait([
        _service.load(),
        _inventoryService.list(),
      ]);
      final (suppliers, shipments) =
          results[0] as (List<Supplier>, List<Shipment>);
      _suppliers = suppliers;
      _shipments = shipments;
      _inventory = results[1] as List<Drug>;
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> saveSupplier(Supplier draft, {String? editingId}) async {
    try {
      if (editingId != null) {
        await _service.updateSupplier(
          editingId,
          draft.toJson(includeId: false),
        );
        Fluttertoast.showToast(msg: '${draft.name} registry updated.');
      } else {
        await _service.createSupplier(draft);
        Fluttertoast.showToast(
          msg: '${draft.name} added to procurement network.',
        );
      }
      await load();
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
      return false;
    }
  }

  Future<bool> deleteSupplier(String id) async {
    try {
      await _service.deleteSupplier(id);
      await load();
      Fluttertoast.showToast(msg: 'Supplier retracted.');
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
      return false;
    }
  }

  Future<bool> submitShipment({
    required String supplierId,
    required String supplierName,
    required String invoiceNumber,
    required List<ShipmentItem> rows,
  }) async {
    final validRows =
        rows
            .where(
              (r) =>
                  r.drugId.isNotEmpty &&
                  r.quantity > 0 &&
                  r.batchNumber.trim().isNotEmpty &&
                  r.expiryDate.isNotEmpty,
            )
            .toList();
    if (supplierId.isEmpty ||
        invoiceNumber.trim().isEmpty ||
        validRows.isEmpty) {
      Fluttertoast.showToast(
        msg:
            'Pick a supplier, an invoice #, and at least one complete line item.',
      );
      return false;
    }
    try {
      await _service.createShipment(
        supplierId: supplierId,
        supplierName: supplierName,
        invoiceNumber: invoiceNumber,
        items: validRows,
      );
      Fluttertoast.showToast(
        msg: '${validRows.length} line item(s) marked In Transit.',
      );
      await load();
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
      return false;
    }
  }

  Future<void> receiveShipment(String id) async {
    _receivingId = id;
    _safeNotify();
    try {
      final restocked = await _service.receiveShipment(id);
      Fluttertoast.showToast(
        msg: '$restocked item(s) restocked into inventory.',
      );
      await load();
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    } finally {
      _receivingId = null;
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
