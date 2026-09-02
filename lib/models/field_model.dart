/// Field dispatch: riders working a delivery round.
/// Mirrors `services/field-service/field-types.ts`.
library;

class LatLngModel {
  final double lat;
  final double lng;
  const LatLngModel({required this.lat, required this.lng});

  factory LatLngModel.fromJson(Map<String, dynamic> json) => LatLngModel(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );
}

enum FieldWorkerKind {
  rider('rider'),
  collector('collector');

  final String value;
  const FieldWorkerKind(this.value);

  static FieldWorkerKind fromJson(String? raw) => FieldWorkerKind.values
      .firstWhere((k) => k.value == raw, orElse: () => FieldWorkerKind.rider);
}

enum FieldJobType {
  delivery('delivery'),
  collection('collection');

  final String value;
  const FieldJobType(this.value);

  static FieldJobType fromJson(String? raw) =>
      raw == 'collection' ? FieldJobType.collection : FieldJobType.delivery;
}

enum FieldStopStatus {
  pending('pending'),
  arrived('arrived'),
  done('done'),
  failed('failed');

  final String value;
  const FieldStopStatus(this.value);

  static FieldStopStatus fromJson(String? raw) => FieldStopStatus.values
      .firstWhere((s) => s.value == raw, orElse: () => FieldStopStatus.pending);
}

class FieldWorker {
  final String id;
  final String tenantId;
  final FieldWorkerKind kind;
  final String name;
  final String phone;
  final bool active;
  final bool createdByAdmin;

  const FieldWorker({
    required this.id,
    required this.tenantId,
    required this.kind,
    required this.name,
    required this.phone,
    required this.active,
    this.createdByAdmin = false,
  });

  factory FieldWorker.fromJson(Map<String, dynamic> json) => FieldWorker(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String? ?? '',
    kind: FieldWorkerKind.fromJson(json['kind'] as String?),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    active: json['active'] as bool? ?? true,
    createdByAdmin: json['createdByAdmin'] as bool? ?? false,
  );
}

class PublicFieldShift {
  final String id;
  final String workerId;
  final LatLngModel? lastLocation;
  final String? lastLocationAt;
  final num cashCollected;

  const PublicFieldShift({
    required this.id,
    required this.workerId,
    this.lastLocation,
    this.lastLocationAt,
    this.cashCollected = 0,
  });

  factory PublicFieldShift.fromJson(Map<String, dynamic> json) => PublicFieldShift(
    id: json['id'] as String,
    workerId: json['workerId'] as String? ?? '',
    lastLocation: json['lastLocation'] != null
        ? LatLngModel.fromJson(json['lastLocation'] as Map<String, dynamic>)
        : null,
    lastLocationAt: json['lastLocationAt'] as String?,
    cashCollected: json['cashCollected'] as num? ?? 0,
  );
}

class BoardStop {
  final String id;
  final String refId;
  final int sequence;
  final FieldStopStatus status;
  final String patientName;
  final String address;
  final FieldJobType jobType;
  final String? failureReason;

  const BoardStop({
    required this.id,
    required this.refId,
    required this.sequence,
    required this.status,
    required this.patientName,
    required this.address,
    required this.jobType,
    this.failureReason,
  });

  factory BoardStop.fromJson(Map<String, dynamic> json) => BoardStop(
    id: json['id'] as String,
    refId: json['refId'] as String,
    sequence: json['sequence'] as int? ?? 0,
    status: FieldStopStatus.fromJson(json['status'] as String?),
    patientName: json['patientName'] as String? ?? '',
    address: json['address'] as String? ?? '',
    jobType: FieldJobType.fromJson(json['jobType'] as String?),
    failureReason: json['failureReason'] as String?,
  );
}

class BoardShift {
  final PublicFieldShift shift;
  final bool stale;
  final List<BoardStop> stops;

  const BoardShift({required this.shift, required this.stale, required this.stops});

  factory BoardShift.fromJson(Map<String, dynamic> json) => BoardShift(
    shift: PublicFieldShift.fromJson(json['shift'] as Map<String, dynamic>),
    stale: json['stale'] as bool? ?? true,
    stops: (json['stops'] as List<dynamic>? ?? [])
        .map((e) => BoardStop.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class DispatchableJob {
  final String id;
  final String patientName;
  final String address;
  final bool unpaid;

  const DispatchableJob({
    required this.id,
    required this.patientName,
    required this.address,
    required this.unpaid,
  });
}

class FieldReconciliation {
  final num collected;
  final num expected;
  final num shortfall;
  final int delivered;
  final int failed;
  final int unworked;

  const FieldReconciliation({
    required this.collected,
    required this.expected,
    required this.shortfall,
    required this.delivered,
    required this.failed,
    required this.unworked,
  });

  factory FieldReconciliation.fromJson(Map<String, dynamic> json) => FieldReconciliation(
    collected: json['collected'] as num? ?? 0,
    expected: json['expected'] as num? ?? 0,
    shortfall: json['shortfall'] as num? ?? 0,
    delivered: json['delivered'] as int? ?? 0,
    failed: json['failed'] as int? ?? 0,
    unworked: json['unworked'] as int? ?? 0,
  );
}