enum PunchType {
  inPunch,
  outPunch;

  String get displayName => this == PunchType.inPunch ? 'IN' : 'OUT';
  bool get isIn => this == PunchType.inPunch;
  bool get isOut => this == PunchType.outPunch;
}

enum PunchSource {
  mobile,
  biometric;

  String get displayName => this == PunchSource.mobile ? 'MOBILE (GPS)' : 'BIOMETRIC';
  bool get isMobile => this == PunchSource.mobile;
  bool get isBiometric => this == PunchSource.biometric;
}

class AttendancePunch {
  final String id;
  final String employeeId;
  final DateTime timestamp;
  final PunchType type;
  final PunchSource source;
  final String? siteId; // Null for pure biometric office punch
  final String? siteName;
  final double? latitude;
  final double? longitude;
  final double? accuracy; // GPS accuracy in meters
  final double? distanceMeters; // Distance to verified site
  final bool isVerified;
  final bool isPendingSync; // Offline queue flag

  const AttendancePunch({
    required this.id,
    required this.employeeId,
    required this.timestamp,
    required this.type,
    required this.source,
    this.siteId,
    this.siteName,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.distanceMeters,
    this.isVerified = true,
    this.isPendingSync = false,
  });

  AttendancePunch copyWith({
    String? id,
    String? employeeId,
    DateTime? timestamp,
    PunchType? type,
    PunchSource? source,
    String? siteId,
    String? siteName,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? distanceMeters,
    bool? isVerified,
    bool? isPendingSync,
  }) {
    return AttendancePunch(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      source: source ?? this.source,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isVerified: isVerified ?? this.isVerified,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'source': source.name,
      'siteId': siteId,
      'siteName': siteName,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'distanceMeters': distanceMeters,
      'isVerified': isVerified,
      'isPendingSync': isPendingSync,
    };
  }

  factory AttendancePunch.fromJson(Map<String, dynamic> json) {
    return AttendancePunch(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: PunchType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PunchType.inPunch,
      ),
      source: PunchSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => PunchSource.mobile,
      ),
      siteId: json['siteId'] as String?,
      siteName: json['siteName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? true,
      isPendingSync: json['isPendingSync'] as bool? ?? false,
    );
  }
}
