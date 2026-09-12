enum LeaveStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending Approval';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isPending => this == LeaveStatus.pending;
  bool get isApproved => this == LeaveStatus.approved;
  bool get isRejected => this == LeaveStatus.rejected;
}

class LeaveRequest {
  final String id;
  final String employeeId;
  final String? employeeCode;
  final String? employeeName;
  final String? department;
  final String leaveType; // CASUAL, SICK, PAID, UNPAID, MATERNITY
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final String? reason;
  final LeaveStatus status;
  final String? approvedBy;
  final String? reviewerRole;
  final DateTime? reviewedAt;
  final String? reviewRemarks;
  final DateTime? createdAt;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    this.employeeCode,
    this.employeeName,
    this.department,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
    this.status = LeaveStatus.pending,
    this.approvedBy,
    this.reviewerRole,
    this.reviewedAt,
    this.reviewRemarks,
    this.createdAt,
  });

  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeCode,
    String? employeeName,
    String? department,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    double? totalDays,
    String? reason,
    LeaveStatus? status,
    String? approvedBy,
    String? reviewerRole,
    DateTime? reviewedAt,
    String? reviewRemarks,
    DateTime? createdAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewRemarks: reviewRemarks ?? this.reviewRemarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeCode': employeeCode,
      'employeeName': employeeName,
      'department': department,
      'leaveType': leaveType,
      'startDate':
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'endDate':
          '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'totalDays': totalDays,
      'reason': reason,
      'status': status.name.toUpperCase(),
      'approvedBy': approvedBy,
      'reviewerRole': reviewerRole,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewRemarks': reviewRemarks,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().toUpperCase() ?? 'PENDING';
    LeaveStatus parsedStatus = LeaveStatus.pending;
    if (rawStatus == 'APPROVED') {
      parsedStatus = LeaveStatus.approved;
    } else if (rawStatus == 'REJECTED') {
      parsedStatus = LeaveStatus.rejected;
    }

    DateTime parsedStart;
    try {
      parsedStart = DateTime.parse(json['startDate'].toString());
    } catch (_) {
      parsedStart = DateTime.now();
    }

    DateTime parsedEnd;
    try {
      parsedEnd = DateTime.parse(json['endDate'].toString());
    } catch (_) {
      parsedEnd = parsedStart;
    }

    double days = 1.0;
    if (json['totalDays'] is num) {
      days = (json['totalDays'] as num).toDouble();
    } else if (json['totalDays'] != null) {
      days = double.tryParse(json['totalDays'].toString()) ?? 1.0;
    }

    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString(),
      employeeName: json['employeeName']?.toString(),
      department: json['department']?.toString(),
      leaveType: json['leaveType']?.toString() ?? 'CASUAL',
      startDate: parsedStart,
      endDate: parsedEnd,
      totalDays: days,
      reason: json['reason']?.toString(),
      status: parsedStatus,
      approvedBy: json['approvedBy']?.toString(),
      reviewerRole: json['reviewerRole']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      reviewRemarks: json['reviewRemarks']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
