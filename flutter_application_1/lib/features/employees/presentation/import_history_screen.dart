import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/import_job.dart';
import '../../../shared/widgets/app_header.dart';

class ImportHistoryScreen extends ConsumerWidget {
  const ImportHistoryScreen({super.key});

  void _showJobErrors(BuildContext context, WidgetRef ref, ImportJob job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.absent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Import Errors: ${job.fileName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Total ${job.errors.length} error(s) encountered during import:', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: job.errors.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final err = job.errors[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.absent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Row ${err.rowNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.absent)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${err.fieldName} — ${err.errorType.displayName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 2),
                                Text(err.errorMessage, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (err.rawValue.isNotEmpty)
                                  Text('Value: "${err.rawValue}"', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final service = ref.read(excelImportServiceProvider);
              final bytes = service.generateErrorReport(job.errors);
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'Error_Report_${job.id}.xlsx',
              );
            },
            icon: const Icon(Icons.download_rounded, color: AppColors.absent),
            label: const Text('Download Error Report (.xlsx)', style: TextStyle(color: AppColors.absent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(importJobsProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Excel Import History',
            subtitle: 'Complete log of batch employee onboarding jobs, validations, and error reports',
          ),
          Expanded(
            child: jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text(
                          'No Excel imports executed yet.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Use "Import Excel" on the Employees page to batch onboard staff.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GlassmorphicContainer(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: job.hasErrors ? Colors.amber.withOpacity(0.15) : AppColors.present.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  job.hasErrors ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                  color: job.hasErrors ? Colors.amber.shade800 : AppColors.present,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(job.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(job.mode.displayName, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Imported by ${job.importedBy} (${job.role}) on ${DateFormat('dd MMM yyyy, hh:mm a').format(job.timestamp)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildMiniStat('Total: ${job.totalRows}', Colors.grey),
                                        const SizedBox(width: 12),
                                        _buildMiniStat('Success: ${job.successfulCount}', AppColors.present),
                                        const SizedBox(width: 12),
                                        _buildMiniStat('Updated: ${job.updatedCount}', Colors.amber.shade800),
                                        const SizedBox(width: 12),
                                        _buildMiniStat('Failed: ${job.failedCount}', job.failedCount > 0 ? AppColors.absent : Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (job.hasErrors)
                                OutlinedButton.icon(
                                  onPressed: () => _showJobErrors(context, ref, job),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.absent),
                                  ),
                                  icon: const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.absent),
                                  label: const Text('View Errors', style: TextStyle(color: AppColors.absent, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
