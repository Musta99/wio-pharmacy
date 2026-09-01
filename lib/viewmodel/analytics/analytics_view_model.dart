import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/payout_request.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
import 'package:wio_pharmacy/models/transaction_record.dart';
import 'package:wio_pharmacy/services/analytics_service.dart';

class DailyRevenuePoint {
  final String day;
  final String date;
  double revenue;
  DailyRevenuePoint({required this.day, required this.date, this.revenue = 0});
}

class AnalyticsViewModel extends ChangeNotifier {
  AnalyticsViewModel({AnalyticsService? service})
    : _service = service ?? AnalyticsService();

  final AnalyticsService _service;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _isWithdrawing = false;
  bool get isWithdrawing => _isWithdrawing;

  PayoutRequest? _pendingPayout;
  PayoutRequest? get pendingPayout => _pendingPayout;
  bool get canRequestPayout => _pendingPayout == null;

  List<PharmaOrder> _orders = [];
  List<Drug> _inventory = [];
  PharmacyWallet _wallet = PharmacyWallet(
    pharmacyId: '',
    currentBalance: 0,
    withdrawableBalance: 0,
    totalWithdrawn: 0,
  );
  List<TransactionRecord> _ledger = [];
  MarketplaceConfig _config = MarketplaceConfig(
    minPurchaseAmount: 100,
    platformFeePercentage: 10,
    payoutThresholdBdt: 1000,
  );

  PharmacyWallet get wallet => _wallet;
  MarketplaceConfig get config => _config;
  List<TransactionRecord> get recentSettlements => _ledger.take(5).toList();

  List<PharmaOrder> get _completed =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();

  double get totalGross => _completed.fold(0.0, (sum, o) => sum + o.total);
  double get totalNet => _ledger.fold(0.0, (sum, r) => sum + r.vendorEarning);
  int get orderCount => _orders.length;
  int get completedCount => _completed.length;
  int get lowStockCount =>
      _inventory.where((d) => d.stock.current < d.stock.min).length;
  double get avgOrderValue =>
      _completed.isEmpty ? 0 : totalGross / _completed.length;

  List<DailyRevenuePoint> get dailyRevenueData {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final now = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return DailyRevenuePoint(day: days[d.weekday % 7], date: dateStr);
    });

    for (final order in _completed) {
      final orderDate = order.createdAt.split('T').first;
      final point = last7.where((d) => d.date == orderDate).firstOrNull;
      if (point != null) point.revenue += order.total;
    }
    return last7;
  }

  // Future<void> load() async {
  //   _isLoading = true;
  //   _safeNotify();
  //   try {
  //     final ordersFuture = _service.getOrders();
  //     final inventoryFuture = _service.getInventory();
  //     final walletFuture = _service.getWalletBundle();

  //     _orders = await ordersFuture;
  //     _inventory = await inventoryFuture;
  //     final bundle = await walletFuture;
  //     _wallet = bundle.wallet;
  //     _ledger = bundle.ledger;
  //     if (bundle.config != null) _config = bundle.config!;
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: '$e');
  //   } finally {
  //     _isLoading = false;
  //     _safeNotify();
  //   }
  // }

  Future<void> load() async {
    _isLoading = true;
    _safeNotify();
    try {
      final ordersFuture = _service.getOrders();
      final inventoryFuture = _service.getInventory();
      final walletFuture = _service.getWalletBundle();

      _orders = await ordersFuture;
      _inventory = await inventoryFuture;
      final bundle = await walletFuture;
      _wallet = bundle.wallet;
      _ledger = bundle.ledger;
      _pendingPayout = bundle.pendingPayout;
      if (bundle.config != null) _config = bundle.config!;
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // Future<void> requestWithdraw() async {
  //   if (_wallet.withdrawableBalance < _config.payoutThresholdBdt) {
  //     Fluttertoast.showToast(
  //       msg:
  //           'Threshold not met. Minimum ${_config.payoutThresholdBdt.toStringAsFixed(0)} BDT required for payout.',
  //     );
  //     return;
  //   }
  //   _isWithdrawing = true;
  //   _safeNotify();
  //   final (ok, message) = await _service.requestWithdraw(
  //     _wallet.withdrawableBalance,
  //   );
  //   Fluttertoast.showToast(msg: message);
  //   if (ok) {
  //     final bundle = await _service.getWalletBundle();
  //     _wallet = bundle.wallet;
  //     _ledger = bundle.ledger;
  //     if (bundle.config != null) _config = bundle.config!;
  //   }
  //   _isWithdrawing = false;
  //   _safeNotify();
  // }

  Future<void> requestWithdraw() async {
    if (!canRequestPayout) {
      Fluttertoast.showToast(msg: 'You already have a payout awaiting review.');
      return;
    }
    if (_wallet.withdrawableBalance < _config.payoutThresholdBdt) {
      Fluttertoast.showToast(
        msg:
            'Threshold not met. Minimum ${_config.payoutThresholdBdt.toStringAsFixed(0)} BDT required for payout.',
      );
      return;
    }
    _isWithdrawing = true;
    _safeNotify();
    final (ok, message) = await _service.requestWithdraw(
      _wallet.withdrawableBalance,
    );
    Fluttertoast.showToast(msg: message);
    if (ok) {
      final bundle = await _service.getWalletBundle();
      _wallet = bundle.wallet;
      _ledger = bundle.ledger;
      _pendingPayout = bundle.pendingPayout;
      if (bundle.config != null) _config = bundle.config!;
    }
    _isWithdrawing = false;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
