import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/daily_operational_check.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/services/pharmacy_service.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({PharmacyService? service})
    : _service = service ?? PharmacyService();

  final PharmacyService _service;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  List<PharmaOrder> _orders = [];
  List<Drug> _inventory = [];
  final List<DailyOperationalCheck> _dailyChecks = [];

  bool _isLoadingOrders = true;
  bool get isLoadingOrders => _isLoadingOrders;

  Timer? _pollTimer;
  String? _activeDeliveryId;
  String? get activeDeliveryId => _activeDeliveryId;
  bool _gpsLive = false;
  bool get gpsLive => _gpsLive;
  StreamSubscription<Position>? _positionSub;
  DateTime _lastGpsWrite = DateTime.fromMillisecondsSinceEpoch(0);
  bool _gpsErrorShown = false;

  List<PharmaOrder> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();

  List<PharmaOrder> get activeOrders =>
      _orders
          .where(
            (o) =>
                o.status == OrderStatus.processing ||
                o.status == OrderStatus.outForDelivery ||
                o.status == OrderStatus.quoted,
          )
          .toList();

  List<PharmaOrder> get outForDeliveryOrders =>
      activeOrders
          .where((o) => o.status == OrderStatus.outForDelivery)
          .toList();

  List<PharmaOrder> get orderHistory {
    final list =
        _orders
            .where(
              (o) =>
                  o.status == OrderStatus.completed ||
                  o.status == OrderStatus.cancelled,
            )
            .toList();
    list.sort(
      (a, b) =>
          DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
    );
    return list;
  }

  List<Drug> get coldChainItems =>
      _inventory
          .where(
            (d) =>
                d.storage.condition == 'Cold Chain' &&
                d.stock.current < (d.stock.min * 1.5),
          )
          .toList();

  List<Drug> get reorderItems =>
      _inventory.where((d) => d.stock.current < d.stock.min).toList();

  DailyOperationalCheck? checkFor(String type) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    try {
      return _dailyChecks.firstWhere((c) => c.date == today && c.type == type);
    } catch (_) {
      return null;
    }
  }

  void start() {
    _loadOrders();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadOrders(silent: true),
    );
    _loadInventory();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      _isLoadingOrders = true;
      _safeNotify();
    }
    try {
      final orders = await _service.getOrders();
      _orders = orders;
    } catch (_) {
      // silent — matches web behavior, next poll retries
    } finally {
      _isLoadingOrders = false;
      _safeNotify();
    }
  }

  Future<void> _loadInventory() async {
    try {
      _inventory = await _service.getInventory();
      _safeNotify();
    } catch (_) {
      // silent
    }
  }

  // Future<void> patchOrder(String orderId, Map<String, dynamic> body) async {
  //   final idx = _orders.indexWhere((o) => o.id == orderId);
  //   if (idx == -1) return;
  //   // optimistic local update for status changes
  //   if (body['status'] != null) {
  //     _orders[idx] = _orders[idx].copyWith(
  //       status: OrderStatusX.fromString(body['status'] as String),
  //     );
  //     _safeNotify();
  //   }
  //   try {
  //     await _service.patchOrder(orderId, body);
  //   } catch (_) {
  //     // 3s poll reconciles, same as web
  //   }
  // }

  Future<void> patchOrder(String orderId, Map<String, dynamic> body) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final previousOrder = _orders[idx]; // keep for rollback on failure

    // optimistic local update for status changes
    if (body['status'] != null) {
      _orders[idx] = _orders[idx].copyWith(
        status: OrderStatusX.fromString(body['status'] as String),
      );
      _safeNotify();
    }
    try {
      final updated = await _service.patchOrder(orderId, body);
      final freshIdx = _orders.indexWhere((o) => o.id == orderId);
      if (freshIdx != -1) {
        _orders[freshIdx] = updated;
        _safeNotify();
      }
    } on PharmacyServiceException catch (e) {
      // Roll back the optimistic update — the server rejected it, so the UI
      // must not keep showing a status that never actually took effect.
      final rollbackIdx = _orders.indexWhere((o) => o.id == orderId);
      if (rollbackIdx != -1) {
        _orders[rollbackIdx] = previousOrder;
        _safeNotify();
      }
      Fluttertoast.showToast(msg: _friendlyMessageFor(e));
      // 3s poll will also reconcile with the server's real state regardless.
    }
  }

  String _friendlyMessageFor(PharmacyServiceException e) {
    switch (e.code) {
      case 'RX_NOT_VERIFIED':
        return 'This order needs a pharmacist sign-off on the prescription before it can proceed.';
      case 'ORDER_UNPAID':
        return 'This order is awaiting online payment from the patient — it can\'t be completed yet.';
      case 'ORDER_UNOWNED':
        return 'This order has no owning pharmacy yet — accept or quote it first.';
    }
    if (e.isConflict) {
      // Covers the claim race ("Another pharmacy has already taken this
      // request") and illegal-transition 409s without hardcoding server text.
      return e.message;
    }
    return e.message;
  }

  // Future<void> updateStatus(String orderId, OrderStatus status) async {
  //   if (status == OrderStatus.outForDelivery) stopDeliveryGps();
  //   await patchOrder(orderId, {'status': status.label});
  //   Fluttertoast.showToast(
  //     msg:
  //         'Order #${orderId.substring(orderId.length - 5)} is now ${status.label}.',
  //   );
  // }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    if (status == OrderStatus.outForDelivery) stopDeliveryGps();
    await patchOrder(orderId, {'status': status.label});
    // Note: patchOrder already toasts on failure; only toast success here.
  }

  Future<void> sendQuote(String orderId, double subtotal) async {
    final tax = (subtotal * 0.05).roundToDouble();
    await patchOrder(orderId, {
      'status': 'Quoted',
      'subtotal': subtotal,
      'tax': tax,
      'total': subtotal + tax,
    });
  }

  // Future<void> sendQuote(String orderId, double subtotal) async {
  //   final tax = (subtotal * 0.05).roundToDouble();
  //   await patchOrder(orderId, {
  //     'status': 'Quoted',
  //     'subtotal': subtotal,
  //     'tax': tax,
  //     'total': subtotal + tax,
  //   });
  //   Fluttertoast.showToast(msg: 'Patient has been notified of the pricing.');
  // }

  // Future<void> assignRider(String orderId, DeliveryInfo patch) async {
  //   final idx = _orders.indexWhere((o) => o.id == orderId);
  //   if (idx == -1) return;
  //   final merged = (_orders[idx].delivery ?? DeliveryInfo()).copyWith(
  //     riderName: patch.riderName,
  //     riderPhone: patch.riderPhone,
  //     dispatchedAt: patch.dispatchedAt,
  //     deliveredAt: patch.deliveredAt,
  //     currentLocation: patch.currentLocation,
  //   );
  //   _orders[idx] = _orders[idx].copyWith(delivery: merged);
  //   _safeNotify();
  //   try {
  //     await _service.patchOrder(orderId, {'delivery': merged.toJson()});
  //   } catch (_) {}
  // }

  Future<void> assignRider(String orderId, DeliveryInfo patch) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final merged = (_orders[idx].delivery ?? DeliveryInfo()).copyWith(
      riderName: patch.riderName,
      riderPhone: patch.riderPhone,
      dispatchedAt: patch.dispatchedAt,
      deliveredAt: patch.deliveredAt,
      currentLocation: patch.currentLocation,
    );
    final previousOrder = _orders[idx];
    _orders[idx] = _orders[idx].copyWith(delivery: merged);
    _safeNotify();
    try {
      final updated = await _service.patchOrder(orderId, {
        'delivery': merged.toJson(),
      });
      final freshIdx = _orders.indexWhere((o) => o.id == orderId);
      if (freshIdx != -1) {
        _orders[freshIdx] = updated;
        _safeNotify();
      }
    } on PharmacyServiceException catch (e) {
      final rollbackIdx = _orders.indexWhere((o) => o.id == orderId);
      if (rollbackIdx != -1) {
        _orders[rollbackIdx] = previousOrder;
        _safeNotify();
      }
      Fluttertoast.showToast(msg: _friendlyMessageFor(e));
    }
  }

  void logSopCheck({
    required String type,
    required double? fridgeTemp,
    required double? roomTemp,
  }) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    _dailyChecks.add(
      DailyOperationalCheck(
        date: today,
        type: type,
        fridgeTemp: fridgeTemp,
        roomTemp: roomTemp,
        nearExpiryChecked: true,
        reconciliationDone: true,
        completedBy: 'Head Pharmacist',
      ),
    );
    _safeNotify();
    Fluttertoast.showToast(
      msg: '$type SOP completed. Daily routine logged successfully.',
    );
  }

  Future<void> verifyRx(String orderId, {String? notes}) async {
    try {
      final updated = await _service.verifyRx(orderId, notes: notes);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = updated;
        _safeNotify();
      }
      Fluttertoast.showToast(msg: 'Prescription verified.');
    } on PharmacyServiceException catch (e) {
      Fluttertoast.showToast(msg: _friendlyMessageFor(e));
    }
  }

  Future<void> startDeliveryGps(String orderId) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied ||
          req == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg: 'GPS unavailable — location permission denied.',
        );
        return;
      }
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      Fluttertoast.showToast(
        msg: 'GPS unavailable — enable location services.',
      );
      return;
    }

    _activeDeliveryId = orderId;
    _gpsLive = true;
    _gpsErrorShown = false;
    _safeNotify();

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (pos) {
        final now = DateTime.now();
        if (now.difference(_lastGpsWrite) < const Duration(seconds: 10)) return;
        _lastGpsWrite = now;
        _service
            .patchOrder(orderId, {
              'currentLocation': {
                'lat': pos.latitude,
                'lng': pos.longitude,
                'progress': 75,
              },
            })
            .catchError((_) {});
      },
      onError: (_) {
        if (_gpsErrorShown) return;
        _gpsErrorShown = true;
        stopDeliveryGps();
        Fluttertoast.showToast(
          msg: "Live GPS not broadcasting — check location permissions.",
        );
      },
    );
    Fluttertoast.showToast(
      msg: 'GPS Live — broadcasting rider location to patient.',
    );
  }

  void stopDeliveryGps() {
    _positionSub?.cancel();
    _positionSub = null;
    _gpsLive = false;
    _activeDeliveryId = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}
