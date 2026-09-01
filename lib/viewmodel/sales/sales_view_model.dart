// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:wio_pharmacy/models/pharma_order.dart';
// import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
// import 'package:wio_pharmacy/services/sales_service.dart';

// class SalesViewModel extends ChangeNotifier {
//   SalesViewModel({SalesService? service})
//     : _service = service ?? SalesService();

//   final SalesService _service;
//   bool _disposed = false;
//   void _safeNotify() {
//     if (!_disposed) notifyListeners();
//   }

//   bool _isLoading = true;
//   bool get isLoading => _isLoading;

//   List<PharmaOrder> _orders = [];
//   PharmacyWallet? _wallet;
//   PharmacyProfile? _profile;
//   bool _submittingPayout = false;
//   bool get submittingPayout => _submittingPayout;

//   PharmacyWallet? get wallet => _wallet;
//   PharmacyProfile? get profile => _profile;

//   List<PharmaOrder> get completedSales {
//     final list =
//         _orders.where((o) => o.status == OrderStatus.completed).toList();
//     list.sort(
//       (a, b) =>
//           DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
//     );
//     return list;
//   }

//   double get totalRevenue =>
//       completedSales.fold(0.0, (sum, o) => sum + o.total);
//   double get avgTicketSize =>
//       completedSales.isEmpty ? 0 : totalRevenue / completedSales.length;

//   bool _isOwner = true;
//   bool get isOwner => _isOwner;
//   // remove: bool get isOwner => _profile?.isOwner ?? true;

//   Future<void> load() async {
//     _isLoading = true;
//     _safeNotify();
//     try {
//       final results = await Future.wait([
//         _service.getOrders(),
//         _service.getWallet(),
//       ]);
//       _orders = results[0] as List<PharmaOrder>;
//       _wallet = results[1] as PharmacyWallet?;

//       final (profile, isOwner) = await _service.getProfileWithOwnership();
//       _profile = profile;
//       _isOwner = isOwner;
//     } catch (err) {
//       print('Error loading sales data: $err');
//       Fluttertoast.showToast(msg: 'Failed to load sales data.');
//     } finally {
//       _isLoading = false;
//       _safeNotify();
//     }
//   }

//   Future<bool> requestPayout(double amount) async {
//     if (amount <= 0) {
//       Fluttertoast.showToast(msg: 'Enter a valid amount.');
//       return false;
//     }
//     _submittingPayout = true;
//     _safeNotify();
//     final (ok, message) = await _service.requestPayout(amount);
//     _submittingPayout = false;
//     _safeNotify();
//     Fluttertoast.showToast(msg: message);
//     if (ok) await load();
//     return ok;
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     super.dispose();
//   }
// }

// ----------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wio_pharmacy/models/payout_request.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
import 'package:wio_pharmacy/services/sales_service.dart';

class SalesViewModel extends ChangeNotifier {
  SalesViewModel({SalesService? service})
    : _service = service ?? SalesService();

  final SalesService _service;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<PharmaOrder> _orders = [];
  PharmacyWallet? _wallet;
  PayoutRequest? _pendingPayout;
  bool _submittingPayout = false;
  bool get submittingPayout => _submittingPayout;

  PharmacyWallet? get wallet => _wallet;
  PayoutRequest? get pendingPayout => _pendingPayout;
  bool get canRequestPayout => _pendingPayout == null;

  PharmacyProfile? _profile;
  bool _isOwner = true;
  PharmacyProfile? get profile => _profile;
  bool get isOwner => _isOwner;

  List<PharmaOrder> get completedSales {
    final list =
        _orders.where((o) => o.status == OrderStatus.completed).toList();
    list.sort(
      (a, b) =>
          DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
    );
    return list;
  }

  double get totalRevenue =>
      completedSales.fold(0.0, (sum, o) => sum + o.total);
  double get avgTicketSize =>
      completedSales.isEmpty ? 0 : totalRevenue / completedSales.length;

  Future<void> load() async {
    _isLoading = true;
    _safeNotify();
    try {
      final results = await Future.wait([
        _service.getOrders(),
        _service.getWalletBundle(),
      ]);
      _orders = results[0] as List<PharmaOrder>;
      final bundle = results[1] as dynamic; // VendorWalletBundle
      _wallet = bundle.wallet as PharmacyWallet;
      _pendingPayout = bundle.pendingPayout as PayoutRequest?;

      final (profile, isOwner) = await _service.getProfileWithOwnership();
      _profile = profile;
      _isOwner = isOwner;
    } catch (_) {
      Fluttertoast.showToast(msg: 'Failed to load sales data.');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> requestPayout(double amount) async {
    if (!canRequestPayout) {
      Fluttertoast.showToast(msg: 'You already have a payout awaiting review.');
      return false;
    }
    if (amount <= 0) {
      Fluttertoast.showToast(msg: 'Enter a valid amount.');
      return false;
    }
    _submittingPayout = true;
    _safeNotify();
    final (ok, message) = await _service.requestPayout(amount);
    _submittingPayout = false;
    _safeNotify();
    Fluttertoast.showToast(msg: message);
    if (ok) await load(); // refetch → pendingPayout appears → sheet locks
    return ok;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
