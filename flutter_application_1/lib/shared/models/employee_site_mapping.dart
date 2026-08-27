enum MappingStatus {
  active,
  inactive;

  String get displayName => this == MappingStatus.active ? 'Active' : 'Inactive';
  bool get isActive => this == MappingStatus.active;
}

class EmployeeSiteMapping {
  final String id;
  final String employeeId;
  final String siteId;
  final DateTime fromDate;
  final DateTime? toDate;
  final MappingStatus status;
  final String createdBy;
  final DateTime createdDate;
  final String? updatedBy;
  final DateTime? updatedDate;

  const EmployeeSiteMapping({
    required this.id,
    required this.employeeId,
    required this.siteId,
    required this.fromDate,
    this.toDate,
    required this.status,
    required this.createdBy,
    required this.createdDate,
    this.updatedBy,
    this.updatedDate,
  });

  bool isCurrentlyValid([DateTime? checkDate]) {
    final date = checkDate ?? DateTime.now();
    if (!status.isActive) return false;
    if (date.isBefore(fromDate)) return false;
    if (toDate != null && date.isAfter(toDate!)) return false;
    return true;
  }

  EmployeeSiteMapping copyWith({
    String? id,
    String? employeeId,
    String? siteId,
    DateTime? fromDate,
    DateTime? toDate,
    MappingStatus? status,
    String? createdBy,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return EmployeeSiteMapping(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      siteId: siteId ?? this.siteId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'siteId': siteId,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'status': status.name,
      'createdBy': createdBy,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }

  factory EmployeeSiteMapping.fromJson(Map<String, dynamic> json) {
    return EmployeeSiteMapping(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      siteId: json['siteId'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate'] as String) : null,
      status: MappingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MappingStatus.active,
      ),
      createdBy: json['createdBy'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      updatedDate: json['updatedDate'] != null ? DateTime.parse(json['updatedDate'] as String) : null,
    );
  }
}
