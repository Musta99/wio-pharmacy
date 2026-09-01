enum PharmacyStaffRole { pharmacist, cashier, inventoryManager, auditor }

extension PharmacyStaffRoleX on PharmacyStaffRole {
  static PharmacyStaffRole fromString(String s) {
    switch (s) {
      case 'cashier':
        return PharmacyStaffRole.cashier;
      case 'inventory_manager':
        return PharmacyStaffRole.inventoryManager;
      case 'auditor':
        return PharmacyStaffRole.auditor;
      case 'pharmacist':
      default:
        return PharmacyStaffRole.pharmacist;
    }
  }

  String get apiValue {
    switch (this) {
      case PharmacyStaffRole.pharmacist:
        return 'pharmacist';
      case PharmacyStaffRole.cashier:
        return 'cashier';
      case PharmacyStaffRole.inventoryManager:
        return 'inventory_manager';
      case PharmacyStaffRole.auditor:
        return 'auditor';
    }
  }

  String get label {
    switch (this) {
      case PharmacyStaffRole.pharmacist:
        return 'Pharmacist';
      case PharmacyStaffRole.cashier:
        return 'Cashier';
      case PharmacyStaffRole.inventoryManager:
        return 'Inventory Manager';
      case PharmacyStaffRole.auditor:
        return 'Auditor';
    }
  }
}

class PharmacyStaff {
  final String uid;
  final String pharmacyId;
  final String name;
  final String email;
  final PharmacyStaffRole subRole;
  final bool active;
  final String createdAt;
  final String createdBy;
  final String? updatedAt;

  PharmacyStaff({
    required this.uid,
    required this.pharmacyId,
    required this.name,
    required this.email,
    required this.subRole,
    required this.active,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
  });

  factory PharmacyStaff.fromJson(Map<String, dynamic> json) => PharmacyStaff(
    uid: json['uid'] as String? ?? '',
    pharmacyId: json['pharmacyId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    subRole: PharmacyStaffRoleX.fromString(
      json['subRole'] as String? ?? 'pharmacist',
    ),
    active: json['active'] as bool? ?? true,
    createdAt: json['createdAt'] as String? ?? '',
    createdBy: json['createdBy'] as String? ?? '',
    updatedAt: json['updatedAt'] as String?,
  );
}
