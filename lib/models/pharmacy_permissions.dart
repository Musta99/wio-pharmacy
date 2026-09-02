/// Pharmacy sub-role permissions — Dart mirror of the web's single
/// permissions table (`lib/pharmacy-permissions.ts`), so a staff login sees
/// the same set of unlocked actions here as on the web dashboard.
library;

enum PharmacyStaffRole {
  pharmacist('pharmacist'),
  cashier('cashier'),
  inventoryManager('inventory_manager'),
  auditor('auditor');

  final String value;
  const PharmacyStaffRole(this.value);

  static PharmacyStaffRole? fromJson(String? raw) {
    if (raw == null) return null;
    for (final r in PharmacyStaffRole.values) {
      if (r.value == raw) return r;
    }
    return null;
  }
}

enum PharmacyStaffPermission {
  rxVerify('rx.verify'),
  orderFulfill('order.fulfill'),
  inventoryView('inventory.view'),
  inventoryAdjust('inventory.adjust'),
  returnApprove('return.approve');

  final String value;
  const PharmacyStaffPermission(this.value);
}

/// Permission presets per sub-role. The pharmacy tenant OWNER (`subRole ==
/// null`) is never subject to this map — owners always have every
/// permission, matching the web table's comment.
const Map<PharmacyStaffRole, List<PharmacyStaffPermission>>
pharmacyStaffPresets = {
  PharmacyStaffRole.pharmacist: [
    PharmacyStaffPermission.rxVerify,
    PharmacyStaffPermission.orderFulfill,
    PharmacyStaffPermission.inventoryView,
  ],
  PharmacyStaffRole.cashier: [
    PharmacyStaffPermission.orderFulfill,
    PharmacyStaffPermission.returnApprove,
    PharmacyStaffPermission.inventoryView,
  ],
  PharmacyStaffRole.inventoryManager: [
    PharmacyStaffPermission.inventoryAdjust,
    PharmacyStaffPermission.inventoryView,
  ],
  PharmacyStaffRole.auditor: [
    PharmacyStaffPermission.inventoryView,
    PharmacyStaffPermission.returnApprove,
  ],
};

/// Owners (`subRole == null`) always pass; staff are checked against their
/// preset.
bool hasPharmacyPermission(
  PharmacyStaffRole? subRole,
  PharmacyStaffPermission permission,
) {
  if (subRole == null) return true;
  return pharmacyStaffPresets[subRole]?.contains(permission) ?? false;
}
