// Forwarding and re-exporting file to maintain full backward compatibility
export '../services/location_service.dart';
export '../services/geofence_service.dart';

import '../services/geofence_service.dart';

typedef GpsStatus = GeofenceEvaluationState;
typedef LocationEvaluationResult = GeofenceEvaluationResult;
