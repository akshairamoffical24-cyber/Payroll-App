import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../domain/face_registration_models.dart';

abstract class FaceRegistrationRepository {
  Future<FaceRegistrationStatus> getFaceStatus(String employeeId);
  Future<FaceRegistrationStatus> registerFace(FaceBiometricPayload payload);
  Future<FaceRegistrationStatus> invalidateFaceRegistration(String employeeId);
}

class HttpFaceRegistrationRepository implements FaceRegistrationRepository {
  final ApiClient _apiClient;

  HttpFaceRegistrationRepository(this._apiClient);

  @override
  Future<FaceRegistrationStatus> getFaceStatus(String employeeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.faceStatus(employeeId));
      if (response is Map<String, dynamic>) {
        return FaceRegistrationStatus.fromJson(response);
      }
    } catch (e) {
      debugPrint('[HttpFaceRepo] Error fetching face status: $e');
    }
    return FaceRegistrationStatus.notRegistered(employeeId);
  }

  @override
  Future<FaceRegistrationStatus> registerFace(FaceBiometricPayload payload) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerFace,
        body: payload.toJson(),
      );
      if (response is Map<String, dynamic>) {
        return FaceRegistrationStatus.fromJson(response);
      }
    } catch (e) {
      debugPrint('[HttpFaceRepo] Error registering face biometrics: $e');
      rethrow;
    }
    throw Exception('Failed to parse face registration response from server');
  }

  @override
  Future<FaceRegistrationStatus> invalidateFaceRegistration(String employeeId) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.invalidateFace(employeeId));
      if (response is Map<String, dynamic>) {
        return FaceRegistrationStatus.fromJson(response);
      }
    } catch (e) {
      debugPrint('[HttpFaceRepo] Error invalidating face registration: $e');
      rethrow;
    }
    return FaceRegistrationStatus.notRegistered(employeeId);
  }
}

final faceRegistrationRepositoryProvider = Provider<FaceRegistrationRepository>((ref) {
  return HttpFaceRegistrationRepository(ApiClient());
});

final faceRegistrationStatusProvider =
    FutureProvider.family<FaceRegistrationStatus, String>((ref, employeeId) async {
  final repo = ref.watch(faceRegistrationRepositoryProvider);
  return repo.getFaceStatus(employeeId);
});
