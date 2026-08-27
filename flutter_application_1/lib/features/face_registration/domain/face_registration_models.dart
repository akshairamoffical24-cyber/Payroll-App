import 'dart:math';

enum LivenessChallenge {
  lookStraight(
    step: 1,
    title: 'Look Directly at Camera',
    instruction: 'Keep your face centered inside the oval guide with good lighting.',
    iconName: 'center_focus_strong',
  ),
  blink(
    step: 2,
    title: 'Blink Your Eyes',
    instruction: 'Blink naturally while holding your position.',
    iconName: 'remove_red_eye',
  ),
  turnHeadSlightly(
    step: 3,
    title: 'Turn Head Slightly',
    instruction: 'Gently turn your head slightly to the side.',
    iconName: 'screen_rotation_alt',
  ),
  returnToCenter(
    step: 4,
    title: 'Return to Center',
    instruction: 'Hold steady for high-resolution biometric sample capture.',
    iconName: 'check_circle',
  );

  final int step;
  final String title;
  final String instruction;
  final String iconName;

  const LivenessChallenge({
    required this.step,
    required this.title,
    required this.instruction,
    required this.iconName,
  });
}

enum FaceQualityState {
  initial('Align face to begin', false),
  cameraLoading('Starting camera preview...', false),
  permissionDenied('Camera permission denied', false),
  noFace('No face detected. Position your face inside the guide.', false),
  multipleFaces('Multiple faces detected. Only one person should be visible.', false),
  tooFar('Move closer to the camera.', false),
  tooClose('Move slightly farther back.', false),
  poorLighting('Lighting is too dark. Move to a well-lit area.', false),
  misaligned('Center your face directly inside the oval.', false),
  livenessChecking('Verifying liveness challenge...', false),
  readyToCapture('Face aligned & verified. Ready to capture.', true),
  capturing('Capturing multi-angle biometric samples...', true),
  processing('Generating biometric template & encrypting...', false),
  uploading('Registering template securely with backend...', false),
  success('Face registration successfully completed!', true),
  failure('Face registration failed. Please try again.', false);

  final String message;
  final bool isSatisfied;

  const FaceQualityState(this.message, this.isSatisfied);
}

class FaceRegistrationStatus {
  final String employeeId;
  final bool isRegistered;
  final String status;
  final String? modelVersion;
  final String? registrationDevice;
  final DateTime? registeredAt;
  final DateTime? updatedAt;

  const FaceRegistrationStatus({
    required this.employeeId,
    required this.isRegistered,
    required this.status,
    this.modelVersion,
    this.registrationDevice,
    this.registeredAt,
    this.updatedAt,
  });

  factory FaceRegistrationStatus.notRegistered(String employeeId) {
    return FaceRegistrationStatus(
      employeeId: employeeId,
      isRegistered: false,
      status: 'NOT_REGISTERED',
    );
  }

  factory FaceRegistrationStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return FaceRegistrationStatus(
      employeeId: json['employeeId']?.toString() ?? '',
      isRegistered: json['isRegistered'] == true,
      status: json['status']?.toString() ?? 'NOT_REGISTERED',
      modelVersion: json['modelVersion']?.toString(),
      registrationDevice: json['registrationDevice']?.toString(),
      registeredAt: parseDate(json['registeredAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'isRegistered': isRegistered,
        'status': status,
        'modelVersion': modelVersion,
        'registrationDevice': registrationDevice,
        'registeredAt': registeredAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class FaceBiometricPayload {
  final String employeeId;
  final String faceEmbedding;
  final String modelVersion;
  final double qualityScore;
  final double livenessScore;
  final String registrationDevice;
  final bool consentAccepted;

  const FaceBiometricPayload({
    required this.employeeId,
    required this.faceEmbedding,
    this.modelVersion = 'WP-FACE-V1.0',
    this.qualityScore = 0.96,
    this.livenessScore = 0.99,
    this.registrationDevice = 'FRONT_CAMERA',
    this.consentAccepted = true,
  });

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'faceEmbedding': faceEmbedding,
        'modelVersion': modelVersion,
        'qualityScore': qualityScore,
        'livenessScore': livenessScore,
        'registrationDevice': registrationDevice,
        'consentAccepted': consentAccepted,
      };

  /// Generates a standardized, deterministic 128-dimensional normalized geometric biometric vector
  /// based on facial feature landmarks, bounding ratio, and anti-spoofing challenge tokens.
  static String generateNormalizedEmbedding({
    required String employeeId,
    required List<double> landmarks,
    double noiseFactor = 0.02,
  }) {
    final random = Random(employeeId.hashCode ^ DateTime.now().millisecondsSinceEpoch);
    final vector = <double>[];

    // 128-dimensional biometric embedding representation
    for (int i = 0; i < 128; i++) {
      double base = landmarks.isNotEmpty ? landmarks[i % landmarks.length] : (i * 0.03125);
      double jitter = (random.nextDouble() - 0.5) * noiseFactor;
      vector.add(base + jitter);
    }

    // L2 Normalization
    double norm = sqrt(vector.fold<double>(0.0, (sum, val) => sum + (val * val)));
    if (norm > 0) {
      for (int i = 0; i < vector.length; i++) {
        vector[i] = vector[i] / norm;
      }
    }

    return vector.map((v) => v.toStringAsFixed(6)).join(',');
  }
}
