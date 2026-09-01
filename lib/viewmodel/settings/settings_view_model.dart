import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wio_pharmacy/models/pharmacy_staff.dart';
import 'package:wio_pharmacy/services/staff_service.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({StaffService? staffService})
    : _staffService = staffService ?? StaffService();

  final StaffService _staffService;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ── Staff ──
  bool _isLoadingStaff = true;
  bool get isLoadingStaff => _isLoadingStaff;
  bool _isCreatingStaff = false;
  bool get isCreatingStaff => _isCreatingStaff;
  List<PharmacyStaff> _staff = [];
  List<PharmacyStaff> get staff => _staff;

  // ── Notifications (local-only, mirrors web's useState) ──
  bool newOrderSmsAlerts = true;
  bool lowStockNotifications = true;

  // ── Invoicing (local-only) ──
  final vatController = TextEditingController(text: '5');
  final markupBufferController = TextEditingController(text: '10');
  final returnPolicyController = TextEditingController(
    text:
        'Life-saving drugs and cold-chain items are non-returnable. Please check seal before acceptance.',
  );

  // ── Strict Protocols (local-only) ──
  bool blockExpirySales = true;
  bool strictFifoFlow = true;
  bool auditMode = false;

  void setNewOrderSmsAlerts(bool v) {
    newOrderSmsAlerts = v;
    _safeNotify();
  }

  void setLowStockNotifications(bool v) {
    lowStockNotifications = v;
    _safeNotify();
  }

  void setBlockExpirySales(bool v) {
    blockExpirySales = v;
    _safeNotify();
  }

  void setStrictFifoFlow(bool v) {
    strictFifoFlow = v;
    _safeNotify();
  }

  void setAuditMode(bool v) {
    auditMode = v;
    _safeNotify();
  }

  Future<void> loadStaff() async {
    _isLoadingStaff = true;
    _safeNotify();
    try {
      _staff = await _staffService.list();
    } catch (e) {
      // Web: silent — empty table + toast-on-action is enough feedback.
    } finally {
      _isLoadingStaff = false;
      _safeNotify();
    }
  }

  Future<bool> createStaff({
    required String name,
    required String email,
    required String password,
    required PharmacyStaffRole subRole,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.length < 6) {
      Fluttertoast.showToast(
        msg: 'Name, email, and a 6+ character password are required.',
      );
      return false;
    }
    _isCreatingStaff = true;
    _safeNotify();
    try {
      await _staffService.create(
        name: name.trim(),
        email: email.trim(),
        password: password,
        subRole: subRole,
      );
      Fluttertoast.showToast(
        msg: '$name can now sign in as a ${subRole.label}.',
      );
      await loadStaff();
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
      return false;
    } finally {
      _isCreatingStaff = false;
      _safeNotify();
    }
  }

  Future<void> toggleActive(PharmacyStaff member) async {
    try {
      await _staffService.toggleActive(member.uid, !member.active);
      await loadStaff();
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
  }

  Future<void> changeRole(
    PharmacyStaff member,
    PharmacyStaffRole subRole,
  ) async {
    try {
      await _staffService.changeRole(member.uid, subRole);
      await loadStaff();
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
  }

  /// Mirrors web's handleSaveChanges — purely cosmetic, no backend call.
  void saveSettings() {
    Fluttertoast.showToast(msg: 'Pharmacy operational parameters updated.');
  }

  @override
  void dispose() {
    _disposed = true;
    vatController.dispose();
    markupBufferController.dispose();
    returnPolicyController.dispose();
    super.dispose();
  }
}
