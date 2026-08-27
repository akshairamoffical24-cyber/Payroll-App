import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/services/excel_import_service.dart';
import '../../../../shared/models/import_job.dart';

class ExcelImportDialog extends ConsumerStatefulWidget {
  const ExcelImportDialog({super.key});

  @override
  ConsumerState<ExcelImportDialog> createState() => _ExcelImportDialogState();
}

class _ExcelImportDialogState extends ConsumerState<ExcelImportDialog> {
  int _currentStep = 0; // 0: Select File & Mode, 1: Validation & Preview, 2: Complete Summary
  String? _fileName;
  Uint8List? _fileBytes;
  ImportMode _selectedMode = ImportMode.addAndUpdate;
  bool _isValidating = false;
  bool _isImporting = false;
  ExcelValidationResult? _validationResult;
  ImportJob? _completedJob;

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls'],
          withData: true,
        );
      } catch (customErr) {
        debugPrint('[FilePicker Custom Error, trying FileType.any] $customErr');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _fileName = file.name;
            _fileBytes = file.bytes;
          });
          await _runValidation();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not read file data. Please try selecting the file again.'),
                backgroundColor: AppColors.absent,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[FilePicker Error] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selection error: $e'),
            backgroundColor: AppColors.absent,
          ),
        );
      }
    }
  }

  Future<void> _loadSampleRoster() async {
    setState(() => _isValidating = true);
    try {
      final service = ref.read(excelImportServiceProvider);
      final bytes = service.generateEmployeeTemplate();
      setState(() {
        _fileName = 'WorkPulse_Sample_Employee_Roster.xlsx';
        _fileBytes = bytes;
      });
      await _runValidation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sample roster: $e'),
            backgroundColor: AppColors.absent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _runValidation() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() => _isValidating = true);

    try {
      final existingEmployees = await ref.read(employeeRepositoryProvider).getAllEmployees();
      final importService = ref.read(excelImportServiceProvider);

      final result = await importService.parseAndValidateExcel(
        fileBytes: _fileBytes!,
        fileName: _fileName!,
        existingEmployees: existingEmployees,
        mode: _selectedMode,
      );

      setState(() {
        _validationResult = result;
        _currentStep = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: $e'),
            backgroundColor: AppColors.absent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _downloadTemplate() async {
    final service = ref.read(excelImportServiceProvider);
    final bytes = service.generateEmployeeTemplate();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'WorkPulse_Employee_Master_Template.xlsx',
    );
  }

  Future<void> _downloadErrorReport() async {
    if (_validationResult == null || _validationResult!.errors.isEmpty) return;
    final service = ref.read(excelImportServiceProvider);
    final bytes = service.generateErrorReport(_validationResult!.errors);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Import_Errors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx',
    );
  }

  Future<void> _executeImport() async {
    if (_validationResult == null) return;

    setState(() => _isImporting = true);

    try {
      final employeesToSave = [
        ..._validationResult!.validEmployees,
        ..._validationResult!.updatedEmployees,
      ];

      await ref.read(employeeRepositoryProvider).importEmployees(employeesToSave, _selectedMode);

      final currentUser = ref.read(authStateProvider);
      final job = ImportJob(
        id: 'IMP-${DateTime.now().millisecondsSinceEpoch}',
        fileName: _fileName ?? 'employees.xlsx',
        importedBy: currentUser?.name ?? 'HR Administrator',
        role: currentUser?.role.displayName ?? 'HR',
        timestamp: DateTime.now(),
        totalRows: _validationResult!.totalRows,
        successfulCount: _validationResult!.validEmployees.length,
        updatedCount: _validationResult!.updatedEmployees.length,
        failedCount: _validationResult!.errors.length,
        mode: _selectedMode,
        errors: _validationResult!.errors,
      );

      ref.read(importJobsProvider.notifier).addJob(job);

      // Audit Log
      await ref.read(auditRepositoryProvider).logAction(
            action: 'IMPORT',
            userId: currentUser?.id,
            actorName: currentUser?.name ?? 'HR Administrator',
            actorRole: currentUser?.role.displayName ?? 'HR',
            module: 'Employees',
            entityType: 'Employee',
            description: 'Imported ${_validationResult!.validEmployees.length} new and updated ${_validationResult!.updatedEmployees.length} employees from $_fileName',
            details: 'Excel batch import executed in ${_selectedMode.displayName}. Total rows: ${_validationResult!.totalRows}, Success: ${_validationResult!.validEmployees.length + _validationResult!.updatedEmployees.length}, Failed: ${_validationResult!.errors.length}',
            newValues: {
              'fileName': _fileName,
              'mode': _selectedMode.name,
              'added': _validationResult!.validEmployees.length,
              'updated': _validationResult!.updatedEmployees.length,
              'failed': _validationResult!.errors.length,
            },
            isSuccess: true,
          );

      // Invalidate providers
      ref.invalidate(employeesListProvider);

      setState(() {
        _completedJob = job;
        _currentStep = 2;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import execution failed: $e'),
            backgroundColor: AppColors.absent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = screenSize.width < 860 ? screenSize.width * 0.95 : 820.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Container(
        width: dialogWidth,
        padding: Responsive.dialogPadding(context),
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.table_view_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Import Employee Master Data',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Upload Excel (.xlsx) file to batch-onboard or update employee records',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),

            // Step Indicator
            _buildStepIndicator(),
            const SizedBox(height: 20),

            // Step Content
            Expanded(
              child: _isValidating || _isImporting
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            _isValidating ? 'Validating Excel headers and records...' : 'Importing employee records into database...',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : _buildCurrentStepContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['1. Select File & Mode', '2. Validate & Preview', '3. Import Summary'];

    return Row(
      children: List.generate(steps.length, (index) {
        final isPassed = _currentStep > index;
        final isCurrent = _currentStep == index;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed
                      ? AppColors.present
                      : (isCurrent ? AppColors.primary : Colors.grey.withOpacity(0.25)),
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? AppColors.primary : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: isPassed ? AppColors.present : Colors.grey.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildSelectFileStep(isDark);
      case 1:
        return _buildPreviewStep(isDark);
      case 2:
        return _buildCompletedStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectFileStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Download Template Callout
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Need the standard template? Download our ready-to-use Excel template with required fields and guidelines.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _downloadTemplate,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                label: const Text('Download Template', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Import Mode Selector
        const Text('Select Import Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: ImportMode.values.map((mode) {
              return RadioListTile<ImportMode>(
                dense: true,
                value: mode,
                groupValue: _selectedMode,
                activeColor: AppColors.primary,
                title: Text(mode.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  mode == ImportMode.addNew
                      ? 'Rejects records if Employee ID or Code already exists in database.'
                      : (mode == ImportMode.updateExisting
                          ? 'Only updates fields of existing employees in database.'
                          : 'Adds non-existing records and updates matching existing employees.'),
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMode = val);
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // File Drag/Pick Area
        InkWell(
          onTap: _pickExcelFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _fileName != null ? AppColors.present : AppColors.primary.withOpacity(0.5),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _fileName != null ? Icons.file_present_rounded : Icons.cloud_upload_outlined,
                  size: 48,
                  color: _fileName != null ? AppColors.present : AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _fileName != null ? _fileName! : 'Click to Browse & Select .xlsx File',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _fileName != null ? AppColors.present : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fileName != null ? 'File loaded. Ready to re-validate.' : 'Supported formats: Microsoft Excel (.xlsx, .xls)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _loadSampleRoster,
              icon: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.amber),
              label: const Text(
                'Instant Test: Load Sample 10-Staff Excel Roster',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewStep(bool isDark) {
    if (_validationResult == null) return const SizedBox.shrink();
    final res = _validationResult!;
    final validTotal = res.validEmployees.length + res.updatedEmployees.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Stats Row
        Row(
          children: [
            _buildStatBox('Total Rows', '${res.totalRows}', Colors.blue, isDark),
            const SizedBox(width: 12),
            _buildStatBox('New Records', '${res.validEmployees.length}', AppColors.present, isDark),
            const SizedBox(width: 12),
            _buildStatBox('To Update', '${res.updatedEmployees.length}', Colors.amber, isDark),
            const SizedBox(width: 12),
            _buildStatBox('Errors / Invalid', '${res.errors.length}', AppColors.absent, isDark),
          ],
        ),
        const SizedBox(height: 16),

        // If has errors, show error table with download report button
        if (res.errors.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Validation Errors (${res.errors.length}):',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.absent),
              ),
              TextButton.icon(
                onPressed: _downloadErrorReport,
                icon: const Icon(Icons.download_rounded, size: 16, color: AppColors.absent),
                label: const Text('Download Error Report', style: TextStyle(color: AppColors.absent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.absent.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.absent.withOpacity(0.2)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: res.errors.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final err = res.errors[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.absent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Row ${err.rowNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.absent)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${err.fieldName}: ${err.errorMessage}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              if (err.rawValue.isNotEmpty)
                                Text('Provided value: "${err.rawValue}"', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ] else ...[
          // Valid preview list
          const Text('Valid Records Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.present)),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: ListView.separated(
                itemCount: validTotal,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final emp = i < res.validEmployees.length
                      ? res.validEmployees[i]
                      : res.updatedEmployees[i - res.validEmployees.length];
                  final isNew = i < res.validEmployees.length;

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isNew ? AppColors.present.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                      child: Text(
                        emp.code.length > 2 ? emp.code.substring(0, 2) : emp.code,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isNew ? AppColors.present : Colors.amber.shade800,
                        ),
                      ),
                    ),
                    title: Text('${emp.name} (${emp.code})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text('${emp.department} · ${emp.designation} · ${emp.type.displayName}', style: const TextStyle(fontSize: 11.5)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isNew ? AppColors.present.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isNew ? 'NEW' : 'UPDATE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isNew ? AppColors.present : Colors.amber.shade800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Action Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('Back to File Selection'),
            ),
            ElevatedButton.icon(
              onPressed: validTotal == 0 ? null : _executeImport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.present,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: Text(
                'Confirm & Import $validTotal Employee(s)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedStep(bool isDark) {
    if (_completedJob == null) return const SizedBox.shrink();
    final job = _completedJob!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.present.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.done_all_rounded, color: AppColors.present, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'IMPORT COMPLETE',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.present, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'File: ${job.fileName} · ${DateFormat('dd MMM yyyy hh:mm a').format(job.timestamp)}',
            style: const TextStyle(fontSize: 12.5, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Import metrics
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Total Rows Processed', '${job.totalRows}'),
                _buildSummaryRow('Successfully Imported', '${job.successfulCount}', valueColor: AppColors.present),
                _buildSummaryRow('Existing Updated', '${job.updatedCount}', valueColor: Colors.amber),
                _buildSummaryRow('Failed / Rejected', '${job.failedCount}', valueColor: job.failedCount > 0 ? AppColors.absent : Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (job.failedCount > 0)
                OutlinedButton.icon(
                  onPressed: _downloadErrorReport,
                  icon: const Icon(Icons.download_rounded, color: AppColors.absent),
                  label: const Text('Download Error Report', style: TextStyle(color: AppColors.absent)),
                ),
              if (job.failedCount > 0) const SizedBox(width: 14),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(employeesListProvider);
                  ref.invalidate(analyticsSummaryProvider);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: const Text('Done & View Employees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
