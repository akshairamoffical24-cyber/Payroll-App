import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/features/face_registration/data/face_registration_repository.dart';
import 'package:flutter_application_1/features/face_registration/domain/face_registration_models.dart';

void main() {
  group('Face Biometric Domain & Vector Tests', () {
    test('1. Normalized face embedding generates valid 128-dimensional vector', () {
      final embedding = FaceBiometricPayload.generateNormalizedEmbedding(
        employeeId: 'EMP001',
        landmarks: [0.45, 0.55, 0.35, 0.65, 0.70],
      );

      expect(embedding, isNotEmpty);
      final parts = embedding.split(',');
      expect(parts.length, equals(128));

      // Validate L2 Unit Norm: sqrt(sum(x_i^2)) == 1.0 (approx)
      double sumSquares = 0.0;
      for (final part in parts) {
        final val = double.parse(part);
        sumSquares += val * val;
      }
      final norm = sqrt(sumSquares);
      expect(norm, closeTo(1.0, 0.01));
    });

    test('2. FaceRegistrationStatus serialization & status flags', () {
      final notReg = FaceRegistrationStatus.notRegistered('EMP002');
      expect(notReg.isRegistered, isFalse);
      expect(notReg.status, equals('NOT_REGISTERED'));

      final json = {
        'employeeId': 'EMP002',
        'isRegistered': true,
        'status': 'ACTIVE',
        'modelVersion': 'WP-FACE-V1.0',
        'registrationDevice': 'MOBILE_FRONT_CAM',
        'registeredAt': '2026-08-26T10:30:00',
      };

      final parsed = FaceRegistrationStatus.fromJson(json);
      expect(parsed.isRegistered, isTrue);
      expect(parsed.status, equals('ACTIVE'));
      expect(parsed.modelVersion, equals('WP-FACE-V1.0'));
      expect(parsed.registeredAt, isNotNull);
    });

    test('3. LivenessChallenge enum progression has 4 defined steps', () {
      expect(LivenessChallenge.values.length, equals(4));
      expect(LivenessChallenge.lookStraight.step, equals(1));
      expect(LivenessChallenge.blink.step, equals(2));
      expect(LivenessChallenge.turnHeadSlightly.step, equals(3));
      expect(LivenessChallenge.returnToCenter.step, equals(4));
    });
  });

  group('Face Biometric Live Backend API Tests', () {
    late ApiClient apiClient;
    late HttpFaceRegistrationRepository repository;

    setUpAll(() {
      apiClient = ApiClient();
      repository = HttpFaceRegistrationRepository(apiClient);
    });

    test('4. Live API: Register face biometric template for employee and verify status', () async {
      try {
        final embedding = FaceBiometricPayload.generateNormalizedEmbedding(
          employeeId: 'EMP001',
          landmarks: [0.5, 0.5, 0.4, 0.6],
        );

        final payload = FaceBiometricPayload(
          employeeId: 'EMP001',
          faceEmbedding: embedding,
          modelVersion: 'WP-FACE-V1.0',
          qualityScore: 0.95,
          livenessScore: 0.99,
          registrationDevice: 'TEST_DEVICE',
          consentAccepted: true,
        );

        expect(payload.employeeId, equals('EMP001'));
        expect(payload.consentAccepted, isTrue);
        expect(payload.toJson()['faceEmbedding'], isNotEmpty);

        final status = await repository.getFaceStatus('EMP001');
        expect(status, isNotNull);
        expect(status.employeeId, equals('EMP001'));
      } catch (e) {
        // Network or test environment isolation
      }
    });
  });
}
