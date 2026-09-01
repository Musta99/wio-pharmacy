import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/inventory_alert.dart';
import 'package:wio_pharmacy/services/inventory_service.dart';

const int kExpiryWarningDays = 90;

class AlertViewModel extends ChangeNotifier {
  AlertViewModel({InventoryService? service})
    : _service = service ?? InventoryService();

  final InventoryService _service;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Drug> _inventory = [];
  List<ReorderSuggestion> _reorderSuggestions = [];
  List<ReorderSuggestion> get reorderSuggestions => _reorderSuggestions;

  // Automation Engine — local-only, mirrors web's useState (no persistence).
  bool autoReorder = true;
  bool smsAlerts = false;
  bool substitution = true;

  void setAutoReorder(bool v) {
    autoReorder = v;
    _safeNotify();
  }

  void setSmsAlerts(bool v) {
    smsAlerts = v;
    _safeNotify();
  }

  void setSubstitution(bool v) {
    substitution = v;
    _safeNotify();
  }

  List<Drug> get criticalItems =>
      _inventory.where((d) => d.stock.current <= d.stock.min).toList();

  List<Drug> get lowStockItems =>
      _inventory
          .where(
            (d) =>
                d.stock.current > d.stock.min &&
                d.stock.current <= d.stock.min * 1.5,
          )
          .toList();

  List<ExpiryAlert> _expiredBatches = [];
  List<ExpiryAlert> _expiringSoonBatches = [];
  List<ExpiryAlert> get expiredBatches => _expiredBatches;
  List<ExpiryAlert> get expiringSoonBatches => _expiringSoonBatches;

  void _computeExpiryAlerts() {
    final now = DateTime.now();
    final expired = <ExpiryAlert>[];
    final expiringSoon = <ExpiryAlert>[];

    for (final drug in _inventory) {
      for (final batch in drug.batches) {
        if (batch.quantity <= 0) continue;
        final expiry = DateTime.tryParse(batch.expiryDate);
        if (expiry == null) continue;
        final daysUntilExpiry = expiry.difference(now).inDays;
        final alert = ExpiryAlert(
          drugId: drug.id,
          brandName: drug.brandName,
          batchNumber: batch.batchNumber,
          expiryDate: batch.expiryDate,
          quantity: batch.quantity,
          daysUntilExpiry: daysUntilExpiry,
        );
        if (daysUntilExpiry < 0) {
          expired.add(alert);
        } else if (daysUntilExpiry <= kExpiryWarningDays) {
          expiringSoon.add(alert);
        }
      }
    }
    expired.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    expiringSoon.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    _expiredBatches = expired;
    _expiringSoonBatches = expiringSoon;
  }

  Future<void> load() async {
    _isLoading = true;
    _safeNotify();
    try {
      final results = await Future.wait([
        _service.list(),
        _service.getReorderSuggestions(),
      ]);
      _inventory = results[0] as List<Drug>;
      _reorderSuggestions = results[1] as List<ReorderSuggestion>;
      _computeExpiryAlerts();
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void triggerReorder(String itemName, {int? suggestedQty}) {
    final msg =
        suggestedQty != null
            ? 'Procurement request for $suggestedQty units of $itemName sent to gold suppliers.'
            : 'Procurement request for $itemName sent to gold suppliers.';
    Fluttertoast.showToast(msg: msg);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
