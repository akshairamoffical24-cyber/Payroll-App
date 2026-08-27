import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../shared/models/daily_attendance.dart';
import '../../shared/models/employee.dart';
import '../../shared/models/import_job.dart';

class ExcelValidationResult {
  final List<Employee> validEmployees;
  final List<Employee> updatedEmployees;
  final List<ImportError> errors;
  final int totalRows;
  final String fileName;
  final ImportMode mode;

  const ExcelValidationResult({
    required this.validEmployees,
    required this.updatedEmployees,
    required this.errors,
    required this.totalRows,
    required this.fileName,
    required this.mode,
  });

  bool get isValid => errors.isEmpty;
  int get successfulCount => validEmployees.length;
  int get updatedCount => updatedEmployees.length;
  int get failedCount => errors.length;
}

class ExcelImportService {
  static const List<String> requiredHeaders = [
    'Employee ID',
    'Employee Code',
    'Full Name',
    'Email',
    'Phone',
    'Department',
    'Designation',
    'Employee Type',
    'Joining Date',
    'Status',
  ];

  static const List<String> optionalHeaders = [
    'Biometric ID',
    'Official Email',
    'Alternate Phone',
    'Work Location',
    'Gender',
    'Date of Birth',
    'Address',
    'City',
    'State',
    'Pincode',
    'Reporting Manager',
    'Monthly CTC',
  ];

  /// Generates a standardized .xlsx template with column guidelines and sample rows
  Uint8List generateEmployeeTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Employee_Master_Template'];
    excel.setDefaultSheet('Employee_Master_Template');

    // Header styling
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#2563EB'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final allHeaders = [...requiredHeaders, ...optionalHeaders];

    for (var col = 0; col < allHeaders.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(allHeaders[col]);
      cell.cellStyle = headerStyle;
    }

    // Sample Row 1 (Office Staff)
    final sample1 = [
      'EMP-001',
      'E001',
      'Rajesh Sharma',
      'rajesh.sharma@example.com',
      '9876543210',
      'Engineering',
      'Senior Site Engineer',
      'FIELD', // OFFICE or FIELD
      '2025-01-15',
      'ACTIVE', // ACTIVE, INACTIVE, ON_LEAVE, RESIGNED, TERMINATED
      'BIO-101',
      'rajesh.official@workpulse.com',
      '9876543211',
      'CTS Chennai Campus',
      'Male',
      '1995-06-20',
      '123 Anna Salai',
      'Chennai',
      'Tamil Nadu',
      '600002',
      'Sarah Jenkins',
      '45000',
    ];

    // Sample Row 2 (Office Biometric Staff)
    final sample2 = [
      'EMP-002',
      'E002',
      'Priya Venkatesh',
      'priya.v@example.com',
      '9876543222',
      'Human Resources',
      'HR Executive',
      'OFFICE',
      '2024-08-01',
      'ACTIVE',
      'BIO-102',
      'priya.hr@workpulse.com',
      '',
      'Head Office',
      'Female',
      '1997-11-14',
      '45 GST Road',
      'Chennai',
      'Tamil Nadu',
      '600045',
      'Admin',
      '38000',
    ];

    for (var col = 0; col < sample1.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1)).value =
          TextCellValue(sample1[col]);
    }

    for (var col = 0; col < sample2.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2)).value =
          TextCellValue(sample2[col]);
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Parses and thoroughly validates an uploaded Excel file bytes
  Future<ExcelValidationResult> parseAndValidateExcel({
    required Uint8List fileBytes,
    required String fileName,
    required List<Employee> existingEmployees,
    required ImportMode mode,
  }) async {
    final excel = Excel.decodeBytes(fileBytes);
    final validEmployees = <Employee>[];
    final updatedEmployees = <Employee>[];
    final errors = <ImportError>[];

    if (excel.tables.isEmpty) {
      return ExcelValidationResult(
        validEmployees: [],
        updatedEmployees: [],
        errors: [
          const ImportError(
            rowNumber: 1,
            fieldName: 'File',
            rawValue: '',
            errorMessage: 'The uploaded Excel file contains no worksheets.',
            errorType: ImportErrorType.generalError,
          ),
        ],
        totalRows: 0,
        fileName: fileName,
        mode: mode,
      );
    }

    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName]!;

    if (table.rows.isEmpty) {
      return ExcelValidationResult(
        validEmployees: [],
        updatedEmployees: [],
        errors: [
          const ImportError(
            rowNumber: 1,
            fieldName: 'File',
            rawValue: '',
            errorMessage: 'Worksheet is completely empty.',
            errorType: ImportErrorType.generalError,
          ),
        ],
        totalRows: 0,
        fileName: fileName,
        mode: mode,
      );
    }

    // 1. Read and Normalize Header Columns
    final headerRow = table.rows.first;
    final headerMap = <String, int>{};

    for (var i = 0; i < headerRow.length; i++) {
      final val = headerRow[i]?.value?.toString().trim().toLowerCase() ?? '';
      if (val.isNotEmpty) {
        headerMap[val] = i;
      }
    }

    // Validate Required Column Headers
    final missingHeaders = <String>[];
    for (final req in requiredHeaders) {
      final normalizedReq = req.toLowerCase();
      if (!headerMap.containsKey(normalizedReq)) {
        // try fuzzy match
        final found = headerMap.keys.any((k) => k.replaceAll(' ', '').contains(normalizedReq.replaceAll(' ', '')));
        if (!found) {
          missingHeaders.add(req);
        }
      }
    }

    if (missingHeaders.isNotEmpty) {
      return ExcelValidationResult(
        validEmployees: [],
        updatedEmployees: [],
        errors: [
          ImportError(
            rowNumber: 1,
            fieldName: 'Headers',
            rawValue: headerMap.keys.join(', '),
            errorMessage: 'Missing required columns: ${missingHeaders.join(', ')}',
            errorType: ImportErrorType.missingRequiredField,
          ),
        ],
        totalRows: table.rows.length - 1,
        fileName: fileName,
        mode: mode,
      );
    }

    // Helper to get cell value
    String getVal(List<Data?> row, String colName) {
      final normalized = colName.toLowerCase();
      var idx = headerMap[normalized];
      if (idx == null) {
        final key = headerMap.keys.firstWhere(
          (k) => k.replaceAll(' ', '').contains(normalized.replaceAll(' ', '')),
          orElse: () => '',
        );
        if (key.isNotEmpty) idx = headerMap[key];
      }
      if (idx != null && idx < row.length && row[idx] != null) {
        return row[idx]!.value?.toString().trim() ?? '';
      }
      return '';
    }

    // Track uniqueness within file
    final seenIds = <String>{};
    final seenCodes = <String>{};
    final seenEmails = <String>{};

    final existingIdMap = {for (var e in existingEmployees) e.id.toLowerCase().trim(): e};
    final existingCodeMap = {for (var e in existingEmployees) e.code.toLowerCase().trim(): e};
    final existingEmailMap = {for (var e in existingEmployees) e.email.toLowerCase().trim(): e};

    final dataRows = table.rows.skip(1).toList();

    for (var i = 0; i < dataRows.length; i++) {
      final rowNum = i + 2; // 1-indexed, header is row 1
      final row = dataRows[i];

      // Skip blank rows
      final isRowEmpty = row.every((c) => c == null || c.value == null || c.value.toString().trim().isEmpty);
      if (isRowEmpty) continue;

      final id = getVal(row, 'Employee ID');
      final code = getVal(row, 'Employee Code');
      final name = getVal(row, 'Full Name');
      final email = getVal(row, 'Email');
      final phone = getVal(row, 'Phone');
      final department = getVal(row, 'Department');
      final designation = getVal(row, 'Designation');
      final typeStr = getVal(row, 'Employee Type').toUpperCase();
      final dateStr = getVal(row, 'Joining Date');
      final statusStr = getVal(row, 'Status').toUpperCase();

      // Optional fields
      final biometricId = getVal(row, 'Biometric ID');
      final officialEmail = getVal(row, 'Official Email');
      final alternatePhone = getVal(row, 'Alternate Phone');
      final workLocation = getVal(row, 'Work Location');
      final gender = getVal(row, 'Gender');
      final dobStr = getVal(row, 'Date of Birth');
      final address = getVal(row, 'Address');
      final city = getVal(row, 'City');
      final state = getVal(row, 'State');
      final pincode = getVal(row, 'Pincode');
      final manager = getVal(row, 'Reporting Manager');
      final ctcStr = getVal(row, 'Monthly CTC');

      bool rowHasError = false;

      // 1. Mandatory Fields Check
      if (id.isEmpty) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Employee ID',
          rawValue: id,
          errorMessage: 'Employee ID is required and cannot be empty.',
          errorType: ImportErrorType.missingRequiredField,
        ));
        rowHasError = true;
      }

      if (code.isEmpty) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Employee Code',
          rawValue: code,
          errorMessage: 'Employee Code is required.',
          errorType: ImportErrorType.missingRequiredField,
        ));
        rowHasError = true;
      }

      if (name.isEmpty) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Full Name',
          rawValue: name,
          errorMessage: 'Employee Full Name is required.',
          errorType: ImportErrorType.missingRequiredField,
        ));
        rowHasError = true;
      }

      if (email.isEmpty) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Email',
          rawValue: email,
          errorMessage: 'Email address is required.',
          errorType: ImportErrorType.missingRequiredField,
        ));
        rowHasError = true;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Email',
          rawValue: email,
          errorMessage: 'Invalid email address format: $email',
          errorType: ImportErrorType.invalidEmail,
        ));
        rowHasError = true;
      }

      if (phone.isEmpty) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Phone',
          rawValue: phone,
          errorMessage: 'Mobile Phone Number is required.',
          errorType: ImportErrorType.missingRequiredField,
        ));
        rowHasError = true;
      }

      if (department.isEmpty) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Department',
          rawValue: department,
          errorMessage: 'Department is required.',
          errorType: ImportErrorType.missingRequiredField,
        ));
        rowHasError = true;
      }

      if (designation.isEmpty) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Designation',
          rawValue: designation,
          errorMessage: 'Designation is required.',
          errorType: ImportErrorType.missingRequiredField,
        ));
        rowHasError = true;
      }

      // 2. Validate Type & Status
      final isOffice = typeStr.contains('OFFICE');
      final isField = typeStr.contains('FIELD');
      if (!isOffice && !isField && typeStr.isNotEmpty) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Employee Type',
          rawValue: typeStr,
          errorMessage: 'Invalid Employee Type. Must be OFFICE or FIELD.',
          errorType: ImportErrorType.invalidType,
        ));
        rowHasError = true;
      }

      EmployeeStatus status = EmployeeStatus.active;
      if (statusStr.contains('INACTIVE')) {
        status = EmployeeStatus.inactive;
      } else if (statusStr.contains('LEAVE')) {
        status = EmployeeStatus.onLeave;
      } else if (statusStr.contains('RESIGN')) {
        status = EmployeeStatus.resigned;
      } else if (statusStr.contains('TERMINAT')) {
        status = EmployeeStatus.terminated;
      } else if (statusStr.isNotEmpty && !statusStr.contains('ACTIVE')) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Status',
          rawValue: statusStr,
          errorMessage: 'Invalid status "$statusStr". Must be ACTIVE, INACTIVE, ON_LEAVE, RESIGNED, or TERMINATED.',
          errorType: ImportErrorType.invalidStatus,
        ));
        rowHasError = true;
      }

      // 3. Validate Date
      DateTime joiningDate = DateTime.now();
      if (dateStr.isNotEmpty) {
        try {
          joiningDate = DateTime.parse(dateStr);
        } catch (_) {
          try {
            joiningDate = DateFormat('yyyy-MM-dd').parse(dateStr);
          } catch (_) {
            try {
              joiningDate = DateFormat('dd/MM/yyyy').parse(dateStr);
            } catch (_) {
              errors.add(ImportError(
                rowNumber: rowNum,
                fieldName: 'Joining Date',
                rawValue: dateStr,
                errorMessage: 'Invalid date format. Expected YYYY-MM-DD or DD/MM/YYYY.',
                errorType: ImportErrorType.invalidDate,
              ));
              rowHasError = true;
            }
          }
        }
      }

      DateTime? dob;
      if (dobStr.isNotEmpty) {
        try {
          dob = DateTime.parse(dobStr);
        } catch (_) {
          try {
            dob = DateFormat('yyyy-MM-dd').parse(dobStr);
          } catch (_) {}
        }
      }

      // 4. Duplicate checks inside Excel file
      final normId = id.toLowerCase().trim();
      final normCode = code.toLowerCase().trim();
      final normEmail = email.toLowerCase().trim();

      if (seenIds.contains(normId)) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Employee ID',
          rawValue: id,
          errorMessage: 'Duplicate Employee ID inside Excel file.',
          errorType: ImportErrorType.duplicateInFile,
        ));
        rowHasError = true;
      }
      seenIds.add(normId);

      if (seenCodes.contains(normCode)) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Employee Code',
          rawValue: code,
          errorMessage: 'Duplicate Employee Code inside Excel file.',
          errorType: ImportErrorType.duplicateInFile,
        ));
        rowHasError = true;
      }
      seenCodes.add(normCode);

      if (seenEmails.contains(normEmail)) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Email',
          rawValue: email,
          errorMessage: 'Duplicate Email inside Excel file.',
          errorType: ImportErrorType.duplicateInFile,
        ));
        rowHasError = true;
      }
      seenEmails.add(normEmail);

      // 5. Existing database conflict checks based on mode
      final existsInDb = existingIdMap.containsKey(normId) ||
          existingCodeMap.containsKey(normCode) ||
          existingEmailMap.containsKey(normEmail);

      final existingEmployee = existingIdMap[normId] ?? existingCodeMap[normCode] ?? existingEmailMap[normEmail];

      if (existsInDb && mode == ImportMode.addNew) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Employee',
          rawValue: '$id / $code',
          errorMessage: 'Employee already exists in database (Import Mode is Add New Only).',
          errorType: ImportErrorType.duplicateInDatabase,
        ));
        rowHasError = true;
      } else if (!existsInDb && mode == ImportMode.updateExisting) {
        errors.add(ImportError(
          rowNumber: rowNum,
          fieldName: 'Employee',
          rawValue: id,
          errorMessage: 'Employee not found in database (Import Mode is Update Existing Only).',
          errorType: ImportErrorType.generalError,
        ));
        rowHasError = true;
      }

      if (rowHasError) continue;

      final empType = isOffice ? EmployeeType.office : EmployeeType.field;
      final monthlyCtc = double.tryParse(ctcStr) ?? 35000.0;

      final employee = Employee(
        id: id,
        code: code,
        name: name,
        department: department,
        designation: designation,
        type: empType,
        biometricId: biometricId.isNotEmpty ? biometricId : null,
        phone: phone,
        email: email,
        officialEmail: officialEmail.isNotEmpty ? officialEmail : null,
        alternatePhone: alternatePhone.isNotEmpty ? alternatePhone : null,
        status: status,
        joiningDate: joiningDate,
        workLocation: workLocation.isNotEmpty ? workLocation : (existingEmployee?.workLocation ?? 'Head Office'),
        gender: gender.isNotEmpty ? gender : (existingEmployee?.gender ?? 'Male'),
        dob: dob ?? existingEmployee?.dob,
        address: address.isNotEmpty ? address : (existingEmployee?.address ?? ''),
        city: city.isNotEmpty ? city : (existingEmployee?.city ?? 'Chennai'),
        state: state.isNotEmpty ? state : (existingEmployee?.state ?? 'Tamil Nadu'),
        pincode: pincode.isNotEmpty ? pincode : (existingEmployee?.pincode ?? '600096'),
        reportingManager: manager.isNotEmpty ? manager : existingEmployee?.reportingManager,
        creationSource: EmployeeCreationSource.excelImport,
        attendanceType: isOffice ? AttendanceSourceType.biometric : AttendanceSourceType.mobile,
        monthlyCtc: monthlyCtc,
        annualCtc: monthlyCtc * 12,
        createdAt: existingEmployee?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existsInDb) {
        updatedEmployees.add(employee);
      } else {
        validEmployees.add(employee);
      }
    }

    return ExcelValidationResult(
      validEmployees: validEmployees,
      updatedEmployees: updatedEmployees,
      errors: errors,
      totalRows: dataRows.length,
      fileName: fileName,
      mode: mode,
    );
  }

  /// Generates a downloadable Excel Error Report for failed rows
  Uint8List generateErrorReport(List<ImportError> errors) {
    final excel = Excel.createExcel();
    final sheet = excel['Import_Errors'];
    excel.setDefaultSheet('Import_Errors');

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#EF4444'),
    );

    final headers = ['Row #', 'Error Type', 'Field Name', 'Provided Value', 'Error Description'];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var i = 0; i < errors.length; i++) {
      final err = errors[i];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value =
          IntCellValue(err.rowNumber);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value =
          TextCellValue(err.errorType.displayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value =
          TextCellValue(err.fieldName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value =
          TextCellValue(err.rawValue);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value =
          TextCellValue(err.errorMessage);
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }
}
