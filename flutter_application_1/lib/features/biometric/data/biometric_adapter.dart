import 'dart:async';

class RawBiometricPunch {
  final String employeeCode;
  final DateTime timestamp;
  final String deviceSerial;
  final String terminalLocation;

  const RawBiometricPunch({
    required this.employeeCode,
    required this.timestamp,
    required this.deviceSerial,
    required this.terminalLocation,
  });

  Map<String, dynamic> toJson() => {
        'employeeCode': employeeCode,
        'timestamp': timestamp.toIso8601String(),
        'deviceSerial': deviceSerial,
        'terminalLocation': terminalLocation,
      };
}

abstract class BiometricAttendanceSource {
  Stream<RawBiometricPunch> get punchStream;
  Future<bool> isDeviceConnected();
  Future<void> simulatePunch(RawBiometricPunch punch);
  Future<List<RawBiometricPunch>> fetchBufferedPunches();
}

class SimulatedBiometricAdapter implements BiometricAttendanceSource {
  final StreamController<RawBiometricPunch> _punchController =
      StreamController<RawBiometricPunch>.broadcast();

  bool _isConnected = true;

  @override
  Stream<RawBiometricPunch> get punchStream => _punchController.stream;

  @override
  Future<bool> isDeviceConnected() async {
    return _isConnected;
  }

  void setConnected(bool connected) {
    _isConnected = connected;
  }

  @override
  Future<void> simulatePunch(RawBiometricPunch punch) async {
    _punchController.add(punch);
  }

  @override
  Future<List<RawBiometricPunch>> fetchBufferedPunches() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return [
      RawBiometricPunch(
        employeeCode: 'EMP003', // Priya
        timestamp: DateTime(now.year, now.month, now.day, 9, 2, 10),
        deviceSerial: 'ZKT-BIO-HQ-01',
        terminalLocation: 'HQ Main Entrance Turnstile',
      ),
      RawBiometricPunch(
        employeeCode: 'EMP004', // Anita
        timestamp: DateTime(now.year, now.month, now.day, 9, 14, 25),
        deviceSerial: 'ZKT-BIO-HQ-01',
        terminalLocation: 'HQ Main Entrance Turnstile',
      ),
      RawBiometricPunch(
        employeeCode: 'EMP006', // Karthik
        timestamp: DateTime(now.year, now.month, now.day, 9, 45, 0), // Late coming
        deviceSerial: 'ZKT-BIO-HQ-02',
        terminalLocation: 'HQ Rear Wing Terminal',
      ),
    ];
  }

  void dispose() {
    _punchController.close();
  }
}
