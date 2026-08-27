import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/daily_attendance.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/widgets/app_header.dart';

class EmployeeOnboardingScreen extends ConsumerStatefulWidget {
  const EmployeeOnboardingScreen({super.key});

  @override
  ConsumerState<EmployeeOnboardingScreen> createState() => _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState extends ConsumerState<EmployeeOnboardingScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Personal Details
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  String _gender = 'Male';
  DateTime? _dob;
  final _fatherNameCtrl = TextEditingController();
  final _personalEmailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Step 2: Employment Details
  final _empCodeCtrl = TextEditingController();
  final _officialEmailCtrl = TextEditingController();
  String _department = 'Projects';
  final _designationCtrl = TextEditingController();
  final _workLocationCtrl = TextEditingController(text: 'Chennai Campus');
  DateTime _joiningDate = DateTime.now();
  EmployeeType _employeeType = EmployeeType.field;

  // Step 3: Salary Fixing, Increment & Banking Details
  final _monthlyCtcCtrl = TextEditingController(text: '35000');
  final _basicSalaryCtrl = TextEditingController(text: '17500');
  final _hraCtrl = TextEditingController(text: '8750');
  final _specialAllowanceCtrl = TextEditingController(text: '8750');
  final _incrementPercentageCtrl = TextEditingController(text: '10.0');
  String _incrementCycle = 'Annual';
  int _probationPeriodMonths = 6;
  DateTime? _nextIncrementDate;
  bool _autoCalculateBreakdown = true;
  String _paymentMode = 'Direct Deposit';

  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  String _accountType = 'Savings';
  final _panCtrl = TextEditingController();
  final _uanCtrl = TextEditingController();

  // Step 4: Attendance Configuration
  AttendanceSourceType _attendanceSource = AttendanceSourceType.mobile;
  final _biometricIdCtrl = TextEditingController();
  bool _requireGeofenceVerification = true;

  // Step 5: Site Assignment
  final Set<String> _selectedSiteIds = {};
  String? _primarySiteId;
  final DateTime _mappingStartDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nextIncrementDate = _joiningDate.add(const Duration(days: 365));
  }

  void _recomputeSalaryComponents(double ctc) {
    if (_autoCalculateBreakdown) {
      final basic = (ctc * 0.50).roundToDouble();
      final hra = (ctc * 0.25).roundToDouble();
      final special = (ctc - basic - hra).clamp(0.0, double.infinity);
      _basicSalaryCtrl.text = basic.toStringAsFixed(0);
      _hraCtrl.text = hra.toStringAsFixed(0);
      _specialAllowanceCtrl.text = special.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _personalEmailCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _empCodeCtrl.dispose();
    _officialEmailCtrl.dispose();
    _designationCtrl.dispose();
    _workLocationCtrl.dispose();
    _monthlyCtcCtrl.dispose();
    _basicSalaryCtrl.dispose();
    _hraCtrl.dispose();
    _specialAllowanceCtrl.dispose();
    _incrementPercentageCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _panCtrl.dispose();
    _uanCtrl.dispose();
    _biometricIdCtrl.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_firstNameCtrl.text.trim().isEmpty) {
        _showError('Please enter employee first name');
        return false;
      }
      if (_mobileCtrl.text.trim().isEmpty) {
        _showError('Please enter phone/mobile number');
        return false;
      }
    } else if (_currentStep == 1) {
      if (_empCodeCtrl.text.trim().isEmpty) {
        _showError('Please enter unique Employee Code / ID');
        return false;
      }
      if (_officialEmailCtrl.text.trim().isEmpty) {
        _showError('Please enter official email address');
        return false;
      }
      if (_designationCtrl.text.trim().isEmpty) {
        _showError('Please enter employee designation');
        return false;
      }
    } else if (_currentStep == 3) {
      if (_attendanceSource == AttendanceSourceType.biometric && _biometricIdCtrl.text.trim().isEmpty) {
        _showError('Please enter Biometric Device ID / Enrollment code');
        return false;
      }
    } else if (_currentStep == 4) {
      if (_employeeType == EmployeeType.field && _selectedSiteIds.isEmpty) {
        _showError('Please assign at least one client/work site for field staff');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.absent),
    );
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
      final monthlyCtc = double.tryParse(_monthlyCtcCtrl.text.replaceAll(',', '').trim()) ?? 35000.0;
      final basicSalary = double.tryParse(_basicSalaryCtrl.text.replaceAll(',', '').trim()) ?? (monthlyCtc * 0.50);
      final hra = double.tryParse(_hraCtrl.text.replaceAll(',', '').trim()) ?? (monthlyCtc * 0.25);
      final specialAllowance = double.tryParse(_specialAllowanceCtrl.text.replaceAll(',', '').trim()) ?? (monthlyCtc * 0.25);
      final incrementPct = double.tryParse(_incrementPercentageCtrl.text.replaceAll('%', '').trim()) ?? 10.0;

      final newEmployee = Employee(
        id: 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        code: _empCodeCtrl.text.trim(),
        name: fullName,
        department: _department,
        designation: _designationCtrl.text.trim(),
        type: _employeeType,
        biometricId: _attendanceSource == AttendanceSourceType.biometric ? _biometricIdCtrl.text.trim() : null,
        phone: _mobileCtrl.text.trim(),
        email: _officialEmailCtrl.text.trim(),
        officialEmail: _officialEmailCtrl.text.trim(),
        personalEmail: _personalEmailCtrl.text.trim().isNotEmpty ? _personalEmailCtrl.text.trim() : null,
        workLocation: _workLocationCtrl.text.trim(),
        joiningDate: _joiningDate,
        status: EmployeeStatus.active,
        gender: _gender,
        dob: _dob,
        fatherName: _fatherNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        emergencyContactName: _emergencyNameCtrl.text.trim().isNotEmpty ? _emergencyNameCtrl.text.trim() : null,
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isNotEmpty ? _emergencyPhoneCtrl.text.trim() : null,
        bankName: _bankNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        ifsc: _ifscCtrl.text.trim(),
        accountType: _accountType,
        pan: _panCtrl.text.trim(),
        uan: _uanCtrl.text.trim(),
        monthlyCtc: monthlyCtc,
        annualCtc: monthlyCtc * 12,
        basicSalary: basicSalary,
        hra: hra,
        specialAllowance: specialAllowance,
        incrementCycle: _incrementCycle,
        incrementPercentage: incrementPct,
        nextIncrementDate: _nextIncrementDate ?? _joiningDate.add(const Duration(days: 365)),
        probationPeriodMonths: _probationPeriodMonths,
        paymentMode: _paymentMode,
        attendanceType: _attendanceSource,
        creationSource: EmployeeCreationSource.manual,
      );

      // Save to Employee Repository
      await ref.read(employeeRepositoryProvider).addEmployee(newEmployee);

      // Save Site Mappings
      final currentUser = ref.read(authStateProvider);
      if (_selectedSiteIds.isNotEmpty) {
        await ref.read(mappingRepositoryProvider).saveEmployeeMappings(
              employeeId: newEmployee.id,
              siteIds: _selectedSiteIds.toList(),
              fromDate: _mappingStartDate,
              actorName: currentUser?.name ?? 'HR Admin',
            );
      }

      // Log Audit Trail
      await ref.read(auditRepositoryProvider).logAction(
            action: 'CREATE',
            userId: currentUser?.id,
            actorName: currentUser?.name ?? 'HR Admin',
            actorRole: currentUser?.role.displayName ?? 'HR',
            module: 'Employees',
            entityType: 'Employee',
            entityId: newEmployee.id,
            description: 'Onboarded employee $fullName (${newEmployee.code}) via 6-Step Wizard',
            details: 'Manual onboarding with ${_employeeType.displayName} profile and ${_attendanceSource.displayName} attendance configuration.',
            newValues: newEmployee.toJson(),
            isSuccess: true,
          );

      ref.invalidate(employeesListProvider);
      ref.invalidate(mappingsListProvider);
      ref.invalidate(analyticsSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee $fullName successfully onboarded!'),
            backgroundColor: AppColors.present,
          ),
        );
        context.go('/employees');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to onboard employee: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Employee Onboarding Wizard',
            subtitle: '6-Step structured employee registration with bi-modal attendance and site assignment',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: [
                      // Wizard Progress Bar
                      _buildWizardStepper(isDark),
                      const SizedBox(height: 24),

                      // Step Card Body
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStepHeader(),
                            const SizedBox(height: 20),
                            const Divider(height: 1),
                            const SizedBox(height: 24),
                            _buildStepForm(isDark),
                            const SizedBox(height: 32),
                            _buildNavigationButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardStepper(bool isDark) {
    final stepTitles = ['Personal', 'Employment', 'Salary & Bank', 'Attendance', 'Site Mapping', 'Review'];

    return Row(
      children: List.generate(stepTitles.length, (index) {
        final isPassed = _currentStep > index;
        final isCurrent = _currentStep == index;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed
                      ? AppColors.present
                      : (isCurrent ? AppColors.primary : Colors.grey.withOpacity(0.2)),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stepTitles[index],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? AppColors.primary : (isPassed ? Colors.white : Colors.grey),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (index < stepTitles.length - 1)
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

  Widget _buildStepHeader() {
    final titles = [
      'Step 1: Personal Details',
      'Step 2: Employment & Designation',
      'Step 3: Salary Fixing, Increment & Banking',
      'Step 4: Attendance Configuration',
      'Step 5: Client / Work Site Mapping',
      'Step 6: Review & Final Confirmation',
    ];

    final descriptions = [
      'Enter basic identity, contact and residential address details.',
      'Configure employee ID, role, department, and work classification.',
      'Configure CTC package, component breakdown, increment & appraisal policy, and bank details.',
      'Set attendance capture mode: Biometric Terminal or Mobile GPS.',
      'Select active client work sites to authorize employee geo-punches.',
      'Review all entered fields before saving to master directory.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titles[_currentStep],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        const SizedBox(height: 4),
        Text(
          descriptions[_currentStep],
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildStepForm(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildEmploymentStep();
      case 2:
        return _buildContactBankingStep(isDark);
      case 3:
        return _buildAttendanceConfigStep(isDark);
      case 4:
        return _buildSiteAssignmentStep(isDark);
      case 5:
        return _buildReviewStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 1: Personal ---
  Widget _buildPersonalStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('First Name *', _firstNameCtrl, hint: 'e.g. Alex'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Last Name', _lastNameCtrl, hint: 'e.g. Morgan'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _gender = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date of Birth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1995, 1, 1),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.cake_rounded, size: 18),
                    label: Text(_dob != null ? DateFormat('dd-MMM-yyyy').format(_dob!) : 'Select Date of Birth'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField("Father's Name", _fatherNameCtrl, hint: "Father / Guardian Name"),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Mobile Number *', _mobileCtrl, hint: 'e.g. +91 9876543210', keyboardType: TextInputType.phone),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Personal Email Address', _personalEmailCtrl, hint: 'e.g. alex.personal@gmail.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField('Residential Address', _addressCtrl, hint: 'Complete address with pincode', maxLines: 2),
      ],
    );
  }

  // --- Step 2: Employment ---
  Widget _buildEmploymentStep() {
    final departments = ['Projects', 'Field Operations', 'Engineering', 'Finance & Accounts', 'Human Resources', 'Management', 'Support'];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('Employee ID / Code *', _empCodeCtrl, hint: 'e.g. EMP009 / E049'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Official Work Email *', _officialEmailCtrl, hint: 'e.g. alex@workpulse.io', keyboardType: TextInputType.emailAddress),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Department *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _department,
                    decoration: const InputDecoration(isDense: true),
                    items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _department = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Designation *', _designationCtrl, hint: 'e.g. Site Engineer / Accounts Lead'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Staff Role Type *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<EmployeeType>(
                    value: _employeeType,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: EmployeeType.field, child: Text('Field Staff (Mobile GPS)')),
                      DropdownMenuItem(value: EmployeeType.office, child: Text('Office Staff (Biometric)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _employeeType = val;
                          _attendanceSource = val.isOffice ? AttendanceSourceType.biometric : AttendanceSourceType.mobile;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date of Joining *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _joiningDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setState(() => _joiningDate = picked);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(DateFormat('dd-MMM-yyyy').format(_joiningDate)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Work Base Location', _workLocationCtrl, hint: 'e.g. Chennai Headquarters / OMR Corridor'),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // --- Step 3: Salary Fixing, Increment & Banking ---
  Widget _buildContactBankingStep(bool isDark) {
    final monthlyCtc = double.tryParse(_monthlyCtcCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
    final annualCtc = monthlyCtc * 12;
    final basic = double.tryParse(_basicSalaryCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
    final incrementPct = double.tryParse(_incrementPercentageCtrl.text.replaceAll('%', '').trim()) ?? 0.0;
    final incrementAmount = (monthlyCtc * (incrementPct / 100)).roundToDouble();
    final projectedNewCtc = monthlyCtc + incrementAmount;
    final pfDeduction = (basic * 0.12).clamp(0.0, 1800.0);
    final estTakeHome = (monthlyCtc - pfDeduction - 200).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. SALARY FIXING SECTION ---
        _buildSectionHeader('💰 Salary Fixing & Monthly CTC Package', 'Define fixed compensation components and payment mode for payroll generation.'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.indigo.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly CTC / Gross Salary (₹) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _monthlyCtcCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 35000',
                            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                            isDense: true,
                            suffixText: 'INR / mo',
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                            setState(() => _recomputeSalaryComponents(parsed));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _paymentMode,
                          decoration: const InputDecoration(isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'Direct Deposit', child: Text('Direct Bank Deposit')),
                            DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMode = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick Fill Presets
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Quick Select:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ...[20000, 30000, 45000, 60000, 85000, 120000].map((amt) {
                    final isSelected = monthlyCtc.toInt() == amt;
                    return ActionChip(
                      label: Text('₹${(amt / 1000).toInt()}k/mo', style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : null)),
                      backgroundColor: isSelected ? AppColors.primary : null,
                      onPressed: () {
                        _monthlyCtcCtrl.text = amt.toString();
                        setState(() => _recomputeSalaryComponents(amt.toDouble()));
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              // Auto-breakdown switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Auto-Compute Components (50% Basic, 25% HRA, 25% Special Allowance)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _autoCalculateBreakdown,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _autoCalculateBreakdown = val;
                        if (val) _recomputeSalaryComponents(monthlyCtc);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Basic Salary (₹)', _basicSalaryCtrl, hint: 'e.g. 17500', keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField('HRA Allowance (₹)', _hraCtrl, hint: 'e.g. 8750', keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField('Special Allowance (₹)', _specialAllowanceCtrl, hint: 'e.g. 8750', keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Live Slip Preview Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Annual CTC Package', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                        Text('₹${NumberFormat('#,##,###').format(annualCtc.toInt())} / year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Est. PF Deduction', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                        Text('₹${pfDeduction.toStringAsFixed(0)} / mo', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Est. Net In-Hand Take Home', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                        Text('₹${NumberFormat('#,##,###').format(estTakeHome.toInt())} / mo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.present)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- 2. INCREMENT & APPRAISAL POLICY ---
        _buildSectionHeader('📈 Increment & Performance Appraisal Policy', 'Configure scheduled appraisal cycle, increment rate, probation period, and review milestones.'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.teal.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Appraisal / Increment Cycle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _incrementCycle,
                          decoration: const InputDecoration(isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'Annual', child: Text('Annual Review (Every 12 Months)')),
                            DropdownMenuItem(value: 'Semi-Annual', child: Text('Semi-Annual (Every 6 Months)')),
                            DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly (Every 3 Months)')),
                            DropdownMenuItem(value: 'On Confirmation', child: Text('On Probation Confirmation')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _incrementCycle = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Increment Percentage (%) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _incrementPercentageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 10.0',
                            prefixIcon: Icon(Icons.percent_rounded, size: 18),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Preset Increment Percentages
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Quick Rates:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ...[5.0, 8.0, 10.0, 12.5, 15.0, 20.0].map((pct) {
                    final isSelected = incrementPct == pct;
                    return ActionChip(
                      label: Text('$pct%', style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : null)),
                      backgroundColor: isSelected ? const Color(0xFF0D9488) : null,
                      onPressed: () {
                        _incrementPercentageCtrl.text = pct.toString();
                        setState(() {});
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Increment / Appraisal Due Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _nextIncrementDate ?? _joiningDate.add(const Duration(days: 365)),
                              firstDate: _joiningDate,
                              lastDate: DateTime.now().add(const Duration(days: 1825)),
                            );
                            if (picked != null) setState(() => _nextIncrementDate = picked);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.event_available_rounded, size: 18, color: Color(0xFF0D9488)),
                          label: Text(
                            _nextIncrementDate != null
                                ? DateFormat('dd-MMM-yyyy').format(_nextIncrementDate!)
                                : 'Select Due Date',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Probation Period', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _probationPeriodMonths,
                          decoration: const InputDecoration(isDense: true),
                          items: const [
                            DropdownMenuItem(value: 3, child: Text('3 Months Probation')),
                            DropdownMenuItem(value: 6, child: Text('6 Months Probation (Standard)')),
                            DropdownMenuItem(value: 0, child: Text('Direct Confirmation (No Probation)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _probationPeriodMonths = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Projected Increment Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFF0D9488), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Projected Revised Salary: ₹${NumberFormat('#,##,###').format(projectedNewCtc.toInt())} / mo (+₹${NumberFormat('#,##,###').format(incrementAmount.toInt())}/mo)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D9488)),
                          ),
                          Text(
                            'Annual Increment Impact: +₹${NumberFormat('#,##,###').format((incrementAmount * 12).toInt())} / year · Appraisal Due: ${_nextIncrementDate != null ? DateFormat('dd-MMM-yyyy').format(_nextIncrementDate!) : "1 year from joining"}',
                            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- 3. BANKING & STATUTORY SECTION ---
        _buildSectionHeader('🏦 Banking & Statutory Details', 'Employee payroll disbursement account and tax compliance identification.'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Bank Name', _bankNameCtrl, hint: 'e.g. HDFC Bank / ICICI Bank'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Account Number', _accountNumberCtrl, hint: 'e.g. 50100293849102'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('IFSC Code', _ifscCtrl, hint: 'e.g. HDFC0000593'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _accountType,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'Savings', child: Text('Savings Account')),
                      DropdownMenuItem(value: 'Salary', child: Text('Salary Account')),
                      DropdownMenuItem(value: 'Current', child: Text('Current Account')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _accountType = val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('PAN Card Number', _panCtrl, hint: 'e.g. ABCDE1234F'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('UAN Number', _uanCtrl, hint: 'e.g. 101969593419'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Emergency Contact Name', _emergencyNameCtrl, hint: 'Name of relative/contact'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Emergency Contact Phone', _emergencyPhoneCtrl, hint: 'e.g. +91 9876543211', keyboardType: TextInputType.phone),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 4: Attendance Config ---
  Widget _buildAttendanceConfigStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Primary Attendance Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSourceCard(
                AttendanceSourceType.biometric,
                'Biometric Terminal',
                'Office staff clock in/out via physical fingerprint / face recognition machines.',
                Icons.fingerprint_rounded,
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSourceCard(
                AttendanceSourceType.mobile,
                'Mobile GPS Punch',
                'Field staff punch directly from authorized client sites with GPS geofencing verification.',
                Icons.gps_fixed_rounded,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_attendanceSource == AttendanceSourceType.biometric) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.indigo.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fingerprint_rounded, color: Colors.indigo),
                    SizedBox(width: 10),
                    Text('Biometric Enrollment Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField('Biometric Terminal User ID / Code *', _biometricIdCtrl, hint: 'e.g. BIO-109 / 1009'),
                const SizedBox(height: 6),
                const Text(
                  'This ID links hardware punch logs from Essl/ZKTeco machines directly to this employee profile.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Field GPS Security Guardrails', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Strict Geofence Enforcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Reject punches taken outside authorized client site radius. (No auto-site creation).', style: TextStyle(fontSize: 12)),
                  value: _requireGeofenceVerification,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _requireGeofenceVerification = val),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceCard(AttendanceSourceType type, String title, String desc, IconData icon, bool isDark) {
    final isSelected = _attendanceSource == type;

    return InkWell(
      onTap: () => setState(() => _attendanceSource = type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (type == AttendanceSourceType.biometric ? Colors.indigo.withOpacity(0.15) : AppColors.primary.withOpacity(0.15))
              : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (type == AttendanceSourceType.biometric ? Colors.indigo : AppColors.primary)
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isSelected ? (type == AttendanceSourceType.biometric ? Colors.indigo : AppColors.primary) : Colors.grey, size: 28),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.present, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- Step 5: Site Assignment ---
  Widget _buildSiteAssignmentStep(bool isDark) {
    final sitesAsync = ref.watch(sitesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Authorize Work / Client Sites:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select mapped client locations where this employee is authorized to perform attendance punches.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        sitesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading sites: $err'),
          data: (sites) {
            if (sites.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No sites found in master. You can assign sites later from Employee Site Mapping screen.'),
              );
            }

            return Column(
              children: sites.map((site) {
                final isChecked = _selectedSiteIds.contains(site.id);
                final isPrimary = _primarySiteId == site.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isChecked ? AppColors.primary.withOpacity(0.08) : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isChecked ? AppColors.primary.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedSiteIds.add(site.id);
                                _primarySiteId ??= site.id;
                              } else {
                                _selectedSiteIds.remove(site.id);
                                if (_primarySiteId == site.id) {
                                  _primarySiteId = _selectedSiteIds.isNotEmpty ? _selectedSiteIds.first : null;
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${site.name} (${site.code})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text('${site.client} · ${site.address}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (isChecked)
                          TextButton.icon(
                            onPressed: () => setState(() => _primarySiteId = site.id),
                            icon: Icon(isPrimary ? Icons.star_rounded : Icons.star_border_rounded, color: isPrimary ? Colors.amber : Colors.grey, size: 18),
                            label: Text(
                              isPrimary ? 'Primary Site' : 'Set Primary',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                                color: isPrimary ? Colors.amber : Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- Step 6: Review Step ---
  Widget _buildReviewStep(bool isDark) {
    final monthlyCtc = double.tryParse(_monthlyCtcCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
    final incrementPct = double.tryParse(_incrementPercentageCtrl.text.replaceAll('%', '').trim()) ?? 0.0;
    final incrementAmt = (monthlyCtc * (incrementPct / 100)).roundToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewCard('Personal Details', [
          'Full Name: ${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
          'Gender: $_gender',
          'Date of Birth: ${_dob != null ? DateFormat('dd-MMM-yyyy').format(_dob!) : "Not specified"}',
          "Father's Name: ${_fatherNameCtrl.text.trim().isNotEmpty ? _fatherNameCtrl.text.trim() : "N/A"}",
          'Phone: ${_mobileCtrl.text.trim()}',
          'Personal Email: ${_personalEmailCtrl.text.trim().isNotEmpty ? _personalEmailCtrl.text.trim() : "N/A"}',
          'Address: ${_addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : "N/A"}',
        ]),
        const SizedBox(height: 14),
        _buildReviewCard('Employment & Role', [
          'Employee Code: ${_empCodeCtrl.text.trim()}',
          'Official Email: ${_officialEmailCtrl.text.trim()}',
          'Department: $_department',
          'Designation: ${_designationCtrl.text.trim()}',
          'Staff Role: ${_employeeType.displayName}',
          'Date of Joining: ${DateFormat('dd-MMM-yyyy').format(_joiningDate)}',
          'Base Location: ${_workLocationCtrl.text.trim()}',
        ]),
        const SizedBox(height: 14),
        _buildReviewCard('💰 Salary Fixing & CTC Package', [
          'Monthly CTC: ₹${NumberFormat('#,##,###').format(monthlyCtc.toInt())} / month',
          'Annual CTC: ₹${NumberFormat('#,##,###').format((monthlyCtc * 12).toInt())} / year',
          'Basic Salary: ₹${_basicSalaryCtrl.text.trim()} / month',
          'House Rent Allowance (HRA): ₹${_hraCtrl.text.trim()} / month',
          'Special Allowance: ₹${_specialAllowanceCtrl.text.trim()} / month',
          'Disbursement Mode: $_paymentMode',
        ]),
        const SizedBox(height: 14),
        _buildReviewCard('📈 Increment & Appraisal Policy', [
          'Appraisal Cycle: $_incrementCycle',
          'Increment Rate: $incrementPct% (+₹${NumberFormat('#,##,###').format(incrementAmt.toInt())} / mo)',
          'Projected Revised CTC: ₹${NumberFormat('#,##,###').format((monthlyCtc + incrementAmt).toInt())} / month',
          'Next Increment Due Date: ${_nextIncrementDate != null ? DateFormat('dd-MMM-yyyy').format(_nextIncrementDate!) : "1 year from joining"}',
          'Probation Period: $_probationPeriodMonths Months',
        ]),
        const SizedBox(height: 14),
        _buildReviewCard('🏦 Banking & Compliance', [
          'Bank Name: ${_bankNameCtrl.text.trim().isNotEmpty ? _bankNameCtrl.text.trim() : "N/A"}',
          'Account Number: ${_accountNumberCtrl.text.trim().isNotEmpty ? _accountNumberCtrl.text.trim() : "N/A"} ($_accountType)',
          'IFSC Code: ${_ifscCtrl.text.trim().isNotEmpty ? _ifscCtrl.text.trim() : "N/A"}',
          'PAN Card: ${_panCtrl.text.trim().isNotEmpty ? _panCtrl.text.trim() : "N/A"}',
          'UAN Number: ${_uanCtrl.text.trim().isNotEmpty ? _uanCtrl.text.trim() : "N/A"}',
          'Emergency Contact: ${_emergencyNameCtrl.text.trim().isNotEmpty ? "${_emergencyNameCtrl.text.trim()} (${_emergencyPhoneCtrl.text.trim()})" : "N/A"}',
        ]),
        const SizedBox(height: 14),
        _buildReviewCard('Attendance & Biometrics', [
          'Attendance Source: ${_attendanceSource.displayName}',
          if (_attendanceSource == AttendanceSourceType.biometric)
            'Biometric Terminal ID: ${_biometricIdCtrl.text.trim()}',
          if (_attendanceSource == AttendanceSourceType.mobile)
            'Geofence Policy: ${_requireGeofenceVerification ? "Strict Enforcement (Active)" : "Standard"}',
          'Authorized Sites Count: ${_selectedSiteIds.length}',
        ]),
      ],
    );
  }

  Widget _buildReviewCard(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          const SizedBox(height: 10),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Text(it, style: const TextStyle(fontSize: 12.5)),
              )),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == 5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: () => setState(() => _currentStep--),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            child: const Text('Back'),
          )
        else
          const SizedBox.shrink(),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  if (!_validateCurrentStep()) return;
                  if (isLastStep) {
                    _submitOnboarding();
                  } else {
                    setState(() => _currentStep++);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isLastStep ? AppColors.present : AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  isLastStep ? 'Submit & Onboard Employee' : 'Next Step',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
