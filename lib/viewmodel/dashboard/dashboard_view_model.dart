import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:wio_pharmacy/models/daily_operational_check.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/field_model.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/models/pharmacy_permissions.dart';
import 'package:wio_pharmacy/services/pharmacy_service.dart';
import 'package:wio_pharmacy/services/profile_services.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({PharmacyService? service, ProfileService? profileService})
    : _service = service ?? PharmacyService(),
      _profileService = profileService ?? ProfileService();

  final PharmacyService _service;
  final ProfileService _profileService;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  List<PharmaOrder> _orders = [];
  List<Drug> _inventory = [];
  final List<DailyOperationalCheck> _dailyChecks = [];

  bool _isLoadingOrders = true;
  bool get isLoadingOrders => _isLoadingOrders;
  PharmacyStaffRole? _subRole;
  bool _subRoleResolved = false;
  String? _pharmacyName;
  String? _pharmacyLogoUrl;

  Timer? _pollTimer;

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

  /// Jobs offered to the Rider Dispatch panel — processing or already out
  /// for delivery, mirroring the web dashboard's `DispatchPanel jobs` prop.
  /// The panel itself filters out anything already on an active route.
  List<DispatchableJob> get dispatchableDeliveries =>
      _orders
          .where(
            (o) =>
                o.status == OrderStatus.processing ||
                o.status == OrderStatus.outForDelivery,
          )
          .map(
            (o) => DispatchableJob(
              id: o.id,
              patientName: o.patientName,
              address: o.address,
              unpaid: o.paymentStatus != 'paid',
            ),
          )
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

  /// `null` while the sub-role is still resolving — callers should render
  /// neither the verify button nor a "waiting" note until this is non-null,
  /// same as the web dashboard's `canVerifyRx === undefined` check.
  bool? get canVerifyRx {
    if (!_subRoleResolved) return null;
    return hasPharmacyPermission(_subRole, PharmacyStaffPermission.rxVerify);
  }

  String? get pharmacyName => _pharmacyName;
  String? get pharmacyLogoUrl => _pharmacyLogoUrl;

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
    _loadSubRole();
    _loadPharmacyProfile();
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

  Future<void> _loadSubRole() async {
    try {
      final raw = await _service.fetchSubRoleRaw();
      _subRole = PharmacyStaffRole.fromJson(raw);
      _subRoleResolved = true;
      _safeNotify();
    } catch (_) {
      // Stays unresolved — the verify affordance stays hidden rather than
      // guessing, same as the web dashboard's silent-catch profile fetch.
    }
  }

  /// Reuses `ProfileService.getProfile()` — already proven to parse the
  /// `/api/pharmacy/profile` response's `profile` object correctly (same
  /// parsing the Profile screen relies on) — rather than re-parsing the
  /// raw JSON a second time with guessed keys.
  Future<void> _loadPharmacyProfile() async {
    try {
      final (profile, _) = await _profileService.getProfile();
      _pharmacyName = profile.name.isNotEmpty ? profile.name : null;
      _pharmacyLogoUrl = profile.logoUrl.isNotEmpty ? profile.logoUrl : null;
      _safeNotify();
    } catch (_) {
      // Non-fatal — the drawer just shows its default fallback.
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

  Future<void> updateStatus(String orderId, OrderStatus status) async {
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

  /// [nearExpiryChecked] and [reconciliationDone] now record what was
  /// actually ticked in the sheet, and `completedBy` records that no signed-
  /// in identity is available here — matching the web dashboard's fix for
  /// what used to be two hardcoded `true` badges and a hardcoded name.
  void logSopCheck({
    required String type,
    required double? fridgeTemp,
    required double? roomTemp,
    required bool nearExpiryChecked,
    required bool reconciliationDone,
  }) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    _dailyChecks.add(
      DailyOperationalCheck(
        date: today,
        type: type,
        fridgeTemp: fridgeTemp,
        roomTemp: roomTemp,
        nearExpiryChecked: nearExpiryChecked,
        reconciliationDone: reconciliationDone,
        completedBy: 'Not recorded',
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

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
