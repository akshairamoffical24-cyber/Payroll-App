import 'dart:async';
import '../../../shared/models/employee_site_mapping.dart';

abstract class MappingRepository {
  Future<List<EmployeeSiteMapping>> getAllMappings();
  Future<List<EmployeeSiteMapping>> getMappingsForEmployee(String employeeId);
  Future<List<String>> getActiveSiteIdsForEmployee(String employeeId, [DateTime? date]);
  Future<void> saveEmployeeMappings({
    required String employeeId,
    required List<String> siteIds,
    required DateTime fromDate,
    DateTime? toDate,
    required String actorName,
  });
  Future<void> toggleMappingStatus(String mappingId);
}

class MockMappingRepository implements MappingRepository {
  final List<EmployeeSiteMapping> _mappings = [
    EmployeeSiteMapping(
      id: 'MAP-048-1',
      employeeId: 'EMP-048',
      siteId: 'SITE-001', // CTS Chennai
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    EmployeeSiteMapping(
      id: 'MAP-048-2',
      employeeId: 'EMP-048',
      siteId: 'SITE-003', // WTC Chennai
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    // Raj (EMP-001) has multiple active site mappings as specified in requirements
    EmployeeSiteMapping(
      id: 'MAP-001',
      employeeId: 'EMP-001',
      siteId: 'SITE-001', // CTS Chennai
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    EmployeeSiteMapping(
      id: 'MAP-002',
      employeeId: 'EMP-001',
      siteId: 'SITE-002', // Wipro Chennai
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    EmployeeSiteMapping(
      id: 'MAP-003',
      employeeId: 'EMP-001',
      siteId: 'SITE-003', // WTC Chennai
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    EmployeeSiteMapping(
      id: 'MAP-004',
      employeeId: 'EMP-001',
      siteId: 'SITE-004', // Coimbatore Project
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    EmployeeSiteMapping(
      id: 'MAP-005',
      employeeId: 'EMP-001',
      siteId: 'SITE-006', // Cochin Project
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    // Suresh (EMP-002) mappings
    EmployeeSiteMapping(
      id: 'MAP-006',
      employeeId: 'EMP-002',
      siteId: 'SITE-002', // Wipro Chennai
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    // Vikram (EMP-005) mappings
    EmployeeSiteMapping(
      id: 'MAP-007',
      employeeId: 'EMP-005',
      siteId: 'SITE-005', // Client ABC
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
    EmployeeSiteMapping(
      id: 'MAP-008',
      employeeId: 'EMP-005',
      siteId: 'SITE-007', // Bangalore Tech Park
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 12, 31),
      status: MappingStatus.active,
      createdBy: 'Sarah Jenkins (HR)',
      createdDate: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<List<EmployeeSiteMapping>> getAllMappings() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_mappings);
  }

  @override
  Future<List<EmployeeSiteMapping>> getMappingsForEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mappings.where((m) => m.employeeId == employeeId).toList();
  }

  @override
  Future<List<String>> getActiveSiteIdsForEmployee(String employeeId, [DateTime? date]) async {
    final checkDate = date ?? DateTime.now();
    return _mappings
        .where((m) => m.employeeId == employeeId && m.isCurrentlyValid(checkDate))
        .map((m) => m.siteId)
        .toList();
  }

  @override
  Future<void> saveEmployeeMappings({
    required String employeeId,
    required List<String> siteIds,
    required DateTime fromDate,
    DateTime? toDate,
    required String actorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    // Mark unselected mappings as inactive rather than deleting to preserve historical audit trail
    for (int i = 0; i < _mappings.length; i++) {
      if (_mappings[i].employeeId == employeeId) {
        if (!siteIds.contains(_mappings[i].siteId)) {
          _mappings[i] = _mappings[i].copyWith(
            status: MappingStatus.inactive,
            updatedDate: now,
          );
        }
      }
    }

    // Add or reactivate selected mappings
    for (final siteId in siteIds) {
      final existingIndex = _mappings.indexWhere(
        (m) => m.employeeId == employeeId && m.siteId == siteId,
      );

      if (existingIndex != -1) {
        _mappings[existingIndex] = _mappings[existingIndex].copyWith(
          status: MappingStatus.active,
          fromDate: fromDate,
          toDate: toDate,
          updatedDate: now,
        );
      } else {
        _mappings.add(
          EmployeeSiteMapping(
            id: 'MAP-${now.millisecondsSinceEpoch}-${siteId.replaceAll('SITE-', '')}',
            employeeId: employeeId,
            siteId: siteId,
            fromDate: fromDate,
            toDate: toDate,
            status: MappingStatus.active,
            createdBy: actorName,
            createdDate: now,
          ),
        );
      }
    }
  }

  @override
  Future<void> toggleMappingStatus(String mappingId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mappings.indexWhere((m) => m.id == mappingId);
    if (index != -1) {
      final current = _mappings[index];
      _mappings[index] = current.copyWith(
        status: current.status == MappingStatus.active
            ? MappingStatus.inactive
            : MappingStatus.active,
        updatedDate: DateTime.now(),
      );
    }
  }
}
