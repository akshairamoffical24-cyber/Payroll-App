import 'daily_attendance.dart';

enum EmployeeType {
  office,
  field;

  String get displayName => this == EmployeeType.office ? 'Office' : 'Field';
  bool get isOffice => this == EmployeeType.office;
  bool get isField => this == EmployeeType.field;
}

enum EmployeeStatus {
  active,
  inactive,
  onLeave,
  resigned,
  terminated;

  String get displayName {
    switch (this) {
      case EmployeeStatus.active:
        return 'Active';
      case EmployeeStatus.inactive:
        return 'Inactive';
      case EmployeeStatus.onLeave:
        return 'On Leave';
      case EmployeeStatus.resigned:
        return 'Resigned';
      case EmployeeStatus.terminated:
        return 'Terminated';
    }
  }

  bool get isActive => this == EmployeeStatus.active;
}

enum EmployeeCreationSource {
  manual,
  excelImport;

  String get displayName => this == EmployeeCreationSource.manual ? 'Manual' : 'Excel Import';
}

class Employee {
  final String id;
  final String code; // e.g. E017, EMP001
  final String name;
  final String department;
  final String designation;
  final EmployeeType type;
  final String? biometricId;
  final String phone;
  final String email;
  final String? officialEmail;
  final String? personalEmail;
  final String? alternatePhone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final EmployeeStatus status;
  final DateTime joiningDate;
  final String? avatarUrl;

  // Personal Details
  final String workLocation;
  final String gender;
  final String? bloodGroup;
  final String? maritalStatus;
  final DateTime? dob;
  final String fatherName;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;

  // Employment & Hierarchy
  final String? reportingManager;
  final String employeeCategory;
  final EmployeeCreationSource creationSource;

  // Attendance Configuration
  final AttendanceSourceType attendanceType;
  final String shift;
  final String shiftStartTime;
  final String shiftEndTime;
  final int gracePeriodMinutes;

  // Payroll & Compliance
  final bool portalAccess;
  final bool epfEnabled;
  final bool esiEnabled;
  final bool epsContribution;
  final bool professionalTaxEnabled;
  final String pfAccountNumber;
  final String uan;
  final String pan;
  final String differentlyAbledType;
  final String paymentMode;
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String accountType;
  final double monthlyCtc;
  final double annualCtc;
  final double? basicSalary;
  final double? hra;
  final double? specialAllowance;
  final String? incrementCycle; // Annual, Semi-Annual, Quarterly, On Confirmation
  final double? incrementPercentage; // e.g. 10.0, 15.0
  final DateTime? nextIncrementDate;
  final int? probationPeriodMonths;
  final double epfEmployerMonthly;
  final double epfEmployerAnnual;
  final bool? isFaceRegistered;
  final DateTime? faceRegisteredAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Employee({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.designation,
    required this.type,
    this.biometricId,
    required this.phone,
    required this.email,
    this.officialEmail,
    this.personalEmail,
    this.alternatePhone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.status,
    required this.joiningDate,
    this.avatarUrl,
    this.workLocation = 'Head Office',
    this.gender = 'Male',
    this.bloodGroup,
    this.maritalStatus,
    this.dob,
    this.fatherName = 'Baskaran',
    this.address = 'Suite 101, Perungudi OMR, Chennai, Tamil Nadu - 600096',
    this.city = 'Chennai',
    this.state = 'Tamil Nadu',
    this.country = 'India',
    this.pincode = '600096',
    this.reportingManager = 'Sarah Jenkins (HR Manager)',
    this.employeeCategory = 'White Collar',
    this.creationSource = EmployeeCreationSource.manual,
    this.attendanceType = AttendanceSourceType.mobile,
    this.shift = 'General Shift (09:00 AM - 06:00 PM)',
    this.shiftStartTime = '09:00 AM',
    this.shiftEndTime = '06:00 PM',
    this.gracePeriodMinutes = 15,
    this.portalAccess = true,
    this.epfEnabled = true,
    this.esiEnabled = false,
    this.epsContribution = false,
    this.professionalTaxEnabled = true,
    this.pfAccountNumber = 'TN/MAS/0019283/000/001',
    this.uan = '101969593419',
    this.pan = 'ABCDE1234F',
    this.differentlyAbledType = 'None',
    this.paymentMode = 'Direct Deposit',
    this.bankName = 'Kotak Mahindra Bank',
    this.accountNumber = '5020004918261673',
    this.ifsc = 'KKBK0000593',
    this.accountType = 'Savings',
    this.monthlyCtc = 31320.0,
    this.annualCtc = 375840.0,
    this.basicSalary,
    this.hra,
    this.specialAllowance,
    this.incrementCycle = 'Annual',
    this.incrementPercentage = 10.0,
    this.nextIncrementDate,
    this.probationPeriodMonths = 6,
    this.epfEmployerMonthly = 1800.0,
    this.epfEmployerAnnual = 21600.0,
    this.isFaceRegistered = false,
    this.faceRegisteredAt,
    this.createdAt,
    this.updatedAt,
  });

  Employee copyWith({
    String? id,
    String? code,
    String? name,
    String? department,
    String? designation,
    EmployeeType? type,
    String? biometricId,
    String? phone,
    String? email,
    String? officialEmail,
    String? alternatePhone,
    EmployeeStatus? status,
    DateTime? joiningDate,
    String? avatarUrl,
    String? workLocation,
    String? gender,
    String? bloodGroup,
    String? maritalStatus,
    DateTime? dob,
    String? fatherName,
    String? address,
    String? city,
    String? state,
    String? country,
    String? pincode,
    String? reportingManager,
    String? employeeCategory,
    EmployeeCreationSource? creationSource,
    AttendanceSourceType? attendanceType,
    String? shift,
    String? shiftStartTime,
    String? shiftEndTime,
    int? gracePeriodMinutes,
    bool? portalAccess,
    bool? epfEnabled,
    bool? esiEnabled,
    bool? epsContribution,
    bool? professionalTaxEnabled,
    String? pfAccountNumber,
    String? uan,
    String? pan,
    String? differentlyAbledType,
    String? paymentMode,
    String? bankName,
    String? accountNumber,
    String? ifsc,
    String? accountType,
    double? monthlyCtc,
    double? annualCtc,
    double? basicSalary,
    double? hra,
    double? specialAllowance,
    String? incrementCycle,
    double? incrementPercentage,
    DateTime? nextIncrementDate,
    int? probationPeriodMonths,
    double? epfEmployerMonthly,
    double? epfEmployerAnnual,
    bool? isFaceRegistered,
    DateTime? faceRegisteredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      type: type ?? this.type,
      biometricId: biometricId ?? this.biometricId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      officialEmail: officialEmail ?? this.officialEmail,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      status: status ?? this.status,
      joiningDate: joiningDate ?? this.joiningDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      workLocation: workLocation ?? this.workLocation,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      dob: dob ?? this.dob,
      fatherName: fatherName ?? this.fatherName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      reportingManager: reportingManager ?? this.reportingManager,
      employeeCategory: employeeCategory ?? this.employeeCategory,
      creationSource: creationSource ?? this.creationSource,
      attendanceType: attendanceType ?? this.attendanceType,
      shift: shift ?? this.shift,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      portalAccess: portalAccess ?? this.portalAccess,
      epfEnabled: epfEnabled ?? this.epfEnabled,
      esiEnabled: esiEnabled ?? this.esiEnabled,
      epsContribution: epsContribution ?? this.epsContribution,
      professionalTaxEnabled: professionalTaxEnabled ?? this.professionalTaxEnabled,
      pfAccountNumber: pfAccountNumber ?? this.pfAccountNumber,
      uan: uan ?? this.uan,
      pan: pan ?? this.pan,
      differentlyAbledType: differentlyAbledType ?? this.differentlyAbledType,
      paymentMode: paymentMode ?? this.paymentMode,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      accountType: accountType ?? this.accountType,
      monthlyCtc: monthlyCtc ?? this.monthlyCtc,
      annualCtc: annualCtc ?? this.annualCtc,
      epfEmployerMonthly: epfEmployerMonthly ?? this.epfEmployerMonthly,
      epfEmployerAnnual: epfEmployerAnnual ?? this.epfEmployerAnnual,
      isFaceRegistered: isFaceRegistered ?? this.isFaceRegistered,
      faceRegisteredAt: faceRegisteredAt ?? this.faceRegisteredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'department': department,
      'designation': designation,
      'type': type.name,
      'biometricId': biometricId,
      'phone': phone,
      'email': email,
      'officialEmail': officialEmail,
      'personalEmail': personalEmail,
      'alternatePhone': alternatePhone,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'status': status.name,
      'joiningDate': '${joiningDate.year.toString().padLeft(4, '0')}-${joiningDate.month.toString().padLeft(2, '0')}-${joiningDate.day.toString().padLeft(2, '0')}',
      'avatarUrl': avatarUrl,
      'workLocation': workLocation,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'maritalStatus': maritalStatus,
      'dob': dob != null
          ? '${dob!.year.toString().padLeft(4, '0')}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}'
          : null,
      'fatherName': fatherName,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'reportingManager': reportingManager,
      'employeeCategory': employeeCategory,
      'creationSource': creationSource.name,
      'attendanceType': attendanceType.name,
      'shift': shift,
      'shiftStartTime': shiftStartTime,
      'shiftEndTime': shiftEndTime,
      'gracePeriodMinutes': gracePeriodMinutes,
      'portalAccess': portalAccess,
      'epfEnabled': epfEnabled,
      'esiEnabled': esiEnabled,
      'epsContribution': epsContribution,
      'professionalTaxEnabled': professionalTaxEnabled,
      'pfAccountNumber': pfAccountNumber,
      'uan': uan,
      'pan': pan,
      'differentlyAbledType': differentlyAbledType,
      'paymentMode': paymentMode,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifsc': ifsc,
      'accountType': accountType,
      'monthlyCtc': monthlyCtc,
      'annualCtc': annualCtc,
      'basicSalary': basicSalary,
      'hra': hra,
      'specialAllowance': specialAllowance,
      'incrementCycle': incrementCycle,
      'incrementPercentage': incrementPercentage,
      'nextIncrementDate': nextIncrementDate != null
          ? '${nextIncrementDate!.year.toString().padLeft(4, '0')}-${nextIncrementDate!.month.toString().padLeft(2, '0')}-${nextIncrementDate!.day.toString().padLeft(2, '0')}'
          : null,
      'probationPeriodMonths': probationPeriodMonths,
      'epfEmployerMonthly': epfEmployerMonthly,
      'epfEmployerAnnual': epfEmployerAnnual,
      'isFaceRegistered': isFaceRegistered,
      'faceRegisteredAt': faceRegisteredAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? 'General',
      designation: json['designation']?.toString() ?? 'Staff',
      type: EmployeeType.values.firstWhere(
        (t) => t.name == json['type'] || (json['type']?.toString().toLowerCase().contains('field') ?? false ? EmployeeType.field : EmployeeType.office) == t,
        orElse: () => EmployeeType.field,
      ),
      biometricId: json['biometricId']?.toString(),
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      officialEmail: json['officialEmail']?.toString(),
      personalEmail: json['personalEmail']?.toString(),
      alternatePhone: json['alternatePhone']?.toString(),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
      status: EmployeeStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == json['status']?.toString().toLowerCase(),
        orElse: () => EmployeeStatus.active,
      ),
      joiningDate: json['joiningDate'] != null
          ? DateTime.tryParse(json['joiningDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      avatarUrl: json['avatarUrl']?.toString(),
      workLocation: json['workLocation']?.toString() ?? 'Head Office',
      gender: json['gender']?.toString() ?? 'Male',
      bloodGroup: json['bloodGroup']?.toString(),
      maritalStatus: json['maritalStatus']?.toString(),
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      fatherName: json['fatherName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Chennai',
      state: json['state']?.toString() ?? 'Tamil Nadu',
      country: json['country']?.toString() ?? 'India',
      pincode: json['pincode']?.toString() ?? '600096',
      reportingManager: json['reportingManager']?.toString(),
      employeeCategory: json['employeeCategory']?.toString() ?? 'General',
      creationSource: EmployeeCreationSource.values.firstWhere(
        (c) => c.name == json['creationSource'],
        orElse: () => EmployeeCreationSource.manual,
      ),
      attendanceType: AttendanceSourceType.values.firstWhere(
        (a) => a.name == json['attendanceType'],
        orElse: () => (json['type']?.toString().toLowerCase() == 'office' ? AttendanceSourceType.biometric : AttendanceSourceType.mobile),
      ),
      shift: json['shift']?.toString() ?? 'General Shift',
      shiftStartTime: json['shiftStartTime']?.toString() ?? '09:00 AM',
      shiftEndTime: json['shiftEndTime']?.toString() ?? '06:00 PM',
      gracePeriodMinutes: (json['gracePeriodMinutes'] as num?)?.toInt() ?? 15,
      portalAccess: json['portalAccess'] as bool? ?? true,
      epfEnabled: json['epfEnabled'] as bool? ?? true,
      esiEnabled: json['esiEnabled'] as bool? ?? false,
      epsContribution: json['epsContribution'] as bool? ?? false,
      professionalTaxEnabled: json['professionalTaxEnabled'] as bool? ?? false,
      pfAccountNumber: json['pfAccountNumber']?.toString() ?? '-',
      uan: json['uan']?.toString() ?? '',
      pan: json['pan']?.toString() ?? '',
      differentlyAbledType: json['differentlyAbledType']?.toString() ?? 'None',
      paymentMode: json['paymentMode']?.toString() ?? 'Direct Deposit',
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? 'Savings',
      monthlyCtc: (json['monthlyCtc'] as num?)?.toDouble() ?? 30000.0,
      annualCtc: (json['annualCtc'] as num?)?.toDouble() ?? 360000.0,
      basicSalary: (json['basicSalary'] as num?)?.toDouble(),
      hra: (json['hra'] as num?)?.toDouble(),
      specialAllowance: (json['specialAllowance'] as num?)?.toDouble(),
      incrementCycle: json['incrementCycle']?.toString() ?? 'Annual',
      incrementPercentage: (json['incrementPercentage'] as num?)?.toDouble() ?? 10.0,
      nextIncrementDate: json['nextIncrementDate'] != null
          ? DateTime.tryParse(json['nextIncrementDate'].toString())
          : null,
      probationPeriodMonths: (json['probationPeriodMonths'] as num?)?.toInt() ?? 6,
      epfEmployerMonthly: (json['epfEmployerMonthly'] as num?)?.toDouble() ?? 1800.0,
      epfEmployerAnnual: (json['epfEmployerAnnual'] as num?)?.toDouble() ?? 21600.0,
      isFaceRegistered: json['isFaceRegistered'] == true,
      faceRegisteredAt: json['faceRegisteredAt'] != null
          ? DateTime.tryParse(json['faceRegisteredAt'].toString())
          : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }
}
