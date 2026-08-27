enum ImportMode {
  addNew,
  updateExisting,
  addAndUpdate;

  String get displayName {
    switch (this) {
      case ImportMode.addNew:
        return 'Add New Employees Only';
      case ImportMode.updateExisting:
        return 'Update Existing Employees Only';
      case ImportMode.addAndUpdate:
        return 'Add New + Update Existing Employees';
    }
  }
}

enum ImportErrorType {
  missingRequiredField,
  duplicateInFile,
  duplicateInDatabase,
  invalidEmail,
  invalidPhone,
  invalidDate,
  invalidType,
  invalidStatus,
  generalError;

  String get displayName {
    switch (this) {
      case ImportErrorType.missingRequiredField:
        return 'Missing Required Field';
      case ImportErrorType.duplicateInFile:
        return 'Duplicate in File';
      case ImportErrorType.duplicateInDatabase:
        return 'Already Exists in Database';
      case ImportErrorType.invalidEmail:
        return 'Invalid Email Format';
      case ImportErrorType.invalidPhone:
        return 'Invalid Phone Number';
      case ImportErrorType.invalidDate:
        return 'Invalid Date Format';
      case ImportErrorType.invalidType:
        return 'Invalid Employee Type';
      case ImportErrorType.invalidStatus:
        return 'Invalid Status';
      case ImportErrorType.generalError:
        return 'General Error';
    }
  }
}

class ImportError {
  final int rowNumber;
  final String fieldName;
  final String rawValue;
  final String errorMessage;
  final ImportErrorType errorType;

  const ImportError({
    required this.rowNumber,
    required this.fieldName,
    required this.rawValue,
    required this.errorMessage,
    required this.errorType,
  });

  Map<String, dynamic> toJson() => {
        'rowNumber': rowNumber,
        'fieldName': fieldName,
        'rawValue': rawValue,
        'errorMessage': errorMessage,
        'errorType': errorType.name,
      };

  factory ImportError.fromJson(Map<String, dynamic> json) => ImportError(
        rowNumber: json['rowNumber'] as int,
        fieldName: json['fieldName'] as String,
        rawValue: json['rawValue'] as String? ?? '',
        errorMessage: json['errorMessage'] as String,
        errorType: ImportErrorType.values.firstWhere(
          (e) => e.name == json['errorType'],
          orElse: () => ImportErrorType.generalError,
        ),
      );
}

class ImportJob {
  final String id;
  final String fileName;
  final String importedBy;
  final String role;
  final DateTime timestamp;
  final int totalRows;
  final int successfulCount;
  final int updatedCount;
  final int failedCount;
  final ImportMode mode;
  final List<ImportError> errors;

  const ImportJob({
    required this.id,
    required this.fileName,
    required this.importedBy,
    required this.role,
    required this.timestamp,
    required this.totalRows,
    required this.successfulCount,
    required this.updatedCount,
    required this.failedCount,
    required this.mode,
    this.errors = const [],
  });

  bool get hasErrors => failedCount > 0;
  bool get isFullSuccess => failedCount == 0 && totalRows > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'importedBy': importedBy,
        'role': role,
        'timestamp': timestamp.toIso8601String(),
        'totalRows': totalRows,
        'successfulCount': successfulCount,
        'updatedCount': updatedCount,
        'failedCount': failedCount,
        'mode': mode.name,
        'errors': errors.map((e) => e.toJson()).toList(),
      };

  factory ImportJob.fromJson(Map<String, dynamic> json) => ImportJob(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        importedBy: json['importedBy'] as String,
        role: json['role'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        totalRows: json['totalRows'] as int,
        successfulCount: json['successfulCount'] as int,
        updatedCount: json['updatedCount'] as int,
        failedCount: json['failedCount'] as int,
        mode: ImportMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => ImportMode.addAndUpdate,
        ),
        errors: (json['errors'] as List<dynamic>?)
                ?.map((e) => ImportError.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
