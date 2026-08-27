enum SiteStatus {
  active,
  inactive;

  String get displayName => this == SiteStatus.active ? 'Active' : 'Inactive';
  bool get isActive => this == SiteStatus.active;
}

class Site {
  final String id;
  final String code; // e.g. SITE015
  final String name; // e.g. CTS Chennai, Coimbatore Project
  final String client; // e.g. Client ABC
  final String project; // e.g. Project XYZ
  final String address;
  final double latitude;
  final double longitude;
  final double geofenceRadius; // Radius in meters (e.g. 100)
  final String poNumber;
  final String siteManagerName;
  final String siteEngineerName;
  final SiteStatus status;

  const Site({
    required this.id,
    required this.code,
    required this.name,
    required this.client,
    required this.project,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadius,
    required this.poNumber,
    required this.siteManagerName,
    required this.siteEngineerName,
    required this.status,
  });

  Site copyWith({
    String? id,
    String? code,
    String? name,
    String? client,
    String? project,
    String? address,
    double? latitude,
    double? longitude,
    double? geofenceRadius,
    String? poNumber,
    String? siteManagerName,
    String? siteEngineerName,
    SiteStatus? status,
  }) {
    return Site(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      client: client ?? this.client,
      project: project ?? this.project,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      poNumber: poNumber ?? this.poNumber,
      siteManagerName: siteManagerName ?? this.siteManagerName,
      siteEngineerName: siteEngineerName ?? this.siteEngineerName,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'client': client,
      'project': project,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadius': geofenceRadius,
      'poNumber': poNumber,
      'siteManagerName': siteManagerName,
      'siteEngineerName': siteEngineerName,
      'status': status.name,
    };
  }

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      client: json['client']?.toString() ?? '',
      project: json['project']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      geofenceRadius: (json['geofenceRadius'] as num?)?.toDouble() ?? 100.0,
      poNumber: json['poNumber']?.toString() ?? '',
      siteManagerName: json['siteManagerName']?.toString() ?? '',
      siteEngineerName: json['siteEngineerName']?.toString() ?? '',
      status: SiteStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SiteStatus.active,
      ),
    );
  }
}
