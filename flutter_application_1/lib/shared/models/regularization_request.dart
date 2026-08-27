enum RegularizationStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case RegularizationStatus.pending:
        return 'Pending HR/Admin Review';
      case RegularizationStatus.approved:
        return 'Approved (Late Attendance Marked)';
      case RegularizationStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isPending => this == RegularizationStatus.pending;
  bool get isApproved => this == RegularizationStatus.approved;
  bool get isRejected => this == RegularizationStatus.rejected;
}

class RegularizationRequest {
  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String department;
  final String requestType; // e.g. Late Punch IN, Missed Punch OUT, Both IN & OUT, Out of Geofence
  final String reasonCategory;
  final DateTime attendanceDate;
  final String requestedInTime;
  final String requestedOutTime;
  final String remarks;
  final DateTime appliedAt;
  final RegularizationStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminReviewRemarks;

  const RegularizationRequest({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.department,
    required this.requestType,
    required this.reasonCategory,
    required this.attendanceDate,
    required this.requestedInTime,
    required this.requestedOutTime,
    required this.remarks,
    required this.appliedAt,
    this.status = RegularizationStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.adminReviewRemarks,
  });

  RegularizationRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeCode,
    String? employeeName,
    String? department,
    String? requestType,
    String? reasonCategory,
    DateTime? attendanceDate,
    String? requestedInTime,
    String? requestedOutTime,
    String? remarks,
    DateTime? appliedAt,
    RegularizationStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? adminReviewRemarks,
  }) {
    return RegularizationRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      requestType: requestType ?? this.requestType,
      reasonCategory: reasonCategory ?? this.reasonCategory,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      requestedInTime: requestedInTime ?? this.requestedInTime,
      requestedOutTime: requestedOutTime ?? this.requestedOutTime,
      remarks: remarks ?? this.remarks,
      appliedAt: appliedAt ?? this.appliedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      adminReviewRemarks: adminReviewRemarks ?? this.adminReviewRemarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeCode': employeeCode,
      'employeeName': employeeName,
      'department': department,
      'requestType': requestType,
      'reasonCategory': reasonCategory,
      'attendanceDate': '${attendanceDate.year.toString().padLeft(4, '0')}-${attendanceDate.month.toString().padLeft(2, '0')}-${attendanceDate.day.toString().padLeft(2, '0')}',
      'requestedInTime': requestedInTime,
      'requestedOutTime': requestedOutTime,
      'remarks': remarks,
      'appliedAt': appliedAt.toIso8601String(),
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'adminReviewRemarks': adminReviewRemarks,
    };
  }

  factory RegularizationRequest.fromJson(Map<String, dynamic> json) {
    return RegularizationRequest(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeCode: json['employeeCode'] as String? ?? 'EMP',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      department: json['department'] as String? ?? 'Operations',
      requestType: json['requestType'] as String? ?? 'Missed Punch',
      reasonCategory: json['reasonCategory'] as String? ?? 'General',
      attendanceDate: DateTime.parse(json['attendanceDate'] as String),
      requestedInTime: json['requestedInTime'] as String? ?? '09:00 AM',
      requestedOutTime: json['requestedOutTime'] as String? ?? '06:00 PM',
      remarks: json['remarks'] as String? ?? '',
      appliedAt: json['appliedAt'] != null ? DateTime.parse(json['appliedAt'] as String) : DateTime.now(),
      status: RegularizationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RegularizationStatus.pending,
      ),
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
      adminReviewRemarks: json['adminReviewRemarks'] as String? ?? json['reviewComments'] as String?,
    );
  }
}
