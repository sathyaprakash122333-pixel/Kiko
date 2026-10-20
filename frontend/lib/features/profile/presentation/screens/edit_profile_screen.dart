import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/logic/auth_service.dart';
import '../../logic/profile_api_service.dart';
import '../../models/user_profile.dart';

/// Screen for editing personal and academic profile details
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.authService,
    this.user,
    this.initialProfile,
    this.profileApiService,
  });

  final AuthService authService;
  final fb.User? user;
  final UserProfile? initialProfile;
  final ProfileApiService? profileApiService;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final ProfileApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _cityController;
  late final TextEditingController _institutionController;
  late final TextEditingController _degreeController;
  late final TextEditingController _departmentController;

  String? _selectedGender;
  String? _selectedAcademicYear;
  String? _selectedSemester;
  DateTime? _selectedDob;

  bool _isSaving = false;
  String? _errorMessage;
  bool _isInitialLoading = false;

  // Options matching educational standards
  static const List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  static const List<String> _academicYearOptions = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
    'Other',
  ];

  static const List<String> _semesterOptions = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _apiService = widget.profileApiService ??
        ProfileApiService(authService: widget.authService);

    final prof = widget.initialProfile;
    final fallbackName = widget.user?.displayName ??
        widget.authService.currentUser?.displayName ??
        '';

    final String? pFullName = prof?.fullName?.trim();
    final String? pDisplayName = prof?.displayName?.trim();
    final String trimmedFallback = fallbackName.trim();

    final String initialName;
    if (pFullName != null && pFullName.isNotEmpty) {
      initialName = pFullName;
    } else if (pDisplayName != null &&
        pDisplayName.isNotEmpty &&
        pDisplayName.toLowerCase() != 'programmer') {
      initialName = pDisplayName;
    } else if (trimmedFallback.isNotEmpty && trimmedFallback.toLowerCase() != 'programmer') {
      initialName = trimmedFallback;
    } else {
      initialName = '';
    }

    _fullNameController = TextEditingController(text: initialName);
    _dobController = TextEditingController(text: prof?.dateOfBirth ?? '');
    _cityController = TextEditingController(text: prof?.city ?? '');
    _institutionController = TextEditingController(text: prof?.institution ?? '');
    _degreeController = TextEditingController(text: prof?.degree ?? '');
    _departmentController = TextEditingController(text: prof?.department ?? '');

    _selectedGender = prof?.gender;
    _selectedAcademicYear = prof?.academicYear;
    _selectedSemester = prof?.semester;

    if (prof == null) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isInitialLoading = true);
    try {
      final prof = await _apiService.fetchProfile();
      if (!mounted) return;
      final String? pFullName = prof.fullName?.trim();
      final String? pDisplayName = prof.displayName?.trim();
      final String realName;
      if (pFullName != null && pFullName.isNotEmpty) {
        realName = pFullName;
      } else if (pDisplayName != null &&
          pDisplayName.isNotEmpty &&
          pDisplayName.toLowerCase() != 'programmer') {
        realName = pDisplayName;
      } else {
        realName = '';
      }

      setState(() {
        _fullNameController.text = realName;
        _dobController.text = prof.dateOfBirth ?? '';
        _cityController.text = prof.city ?? '';
        _institutionController.text = prof.institution ?? '';
        _degreeController.text = prof.degree ?? '';
        _departmentController.text = prof.department ?? '';
        _selectedGender = prof.gender;
        _selectedAcademicYear = prof.academicYear;
        _selectedSemester = prof.semester;
        _isInitialLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _institutionController.dispose();
    _degreeController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  bool _isDirty() {
    final prof = widget.initialProfile;
    if (prof == null) return false;

    return _fullNameController.text.trim() != (prof.fullName ?? prof.displayName ?? '') ||
        _dobController.text.trim() != (prof.dateOfBirth ?? '') ||
        _cityController.text.trim() != (prof.city ?? '') ||
        _institutionController.text.trim() != (prof.institution ?? '') ||
        _degreeController.text.trim() != (prof.degree ?? '') ||
        _departmentController.text.trim() != (prof.department ?? '') ||
        _selectedGender != prof.gender ||
        _selectedAcademicYear != prof.academicYear ||
        _selectedSemester != prof.semester;
  }

  Future<void> _handleCancel() async {
    if (_isDirty()) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: KikoColors.border),
          ),
          title: const Text(
            'Discard Changes?',
            style: TextStyle(
              color: KikoColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: TextStyle(
              color: KikoColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Keep Editing',
                style: TextStyle(
                  color: KikoColors.primaryForest,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Discard',
                style: TextStyle(
                  color: KikoColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldDiscard != true || !mounted) return;
    }

    Navigator.of(context).pop(false);
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initial = _selectedDob ??
        DateTime.tryParse(_dobController.text) ??
        DateTime(now.year - 20, 11, 15);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? initial : DateTime(now.year - 18, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: KikoColors.primaryForest,
              onPrimary: Colors.white,
              surface: KikoColors.surface,
              onSurface: KikoColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: KikoColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: KikoColors.border),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        // Format as DD-MM-YYYY
        final day = picked.day.toString().padLeft(2, '0');
        final month = picked.month.toString().padLeft(2, '0');
        _dobController.text = '$day-$month-${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'full_name': _fullNameController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
      'gender': _selectedGender,
      'city': _cityController.text.trim(),
      'institution': _institutionController.text.trim(),
      'degree': _degreeController.text.trim(),
      'department': _departmentController.text.trim(),
      'academic_year': _selectedAcademicYear,
      'semester': _selectedSemester,
    };

    try {
      await _apiService.updateProfile(payload);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Profile changes saved successfully!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: KikoColors.secondaryEmerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty() && !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleCancel();
        }
      },
      child: Scaffold(
        backgroundColor: KikoColors.background,
        appBar: AppBar(
          backgroundColor: KikoColors.surface,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: KikoColors.border, height: 1),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: KikoColors.secondarySurface,
                shape: BoxShape.circle,
                border: Border.all(color: KikoColors.border),
              ),
              child: const Icon(Icons.arrow_back, color: KikoColors.textPrimary, size: 18),
            ),
            onPressed: _handleCancel,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 20),
              ),
              Text(
                'Keep your personal and academic details up to date.',
                style: KikoTypography.bodySm(color: KikoColors.textSecondary)
                    .copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        body: _isInitialLoading
            ? const Center(
                child: CircularProgressIndicator(color: KikoColors.primaryForest),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: KikoColors.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: KikoColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: KikoColors.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: KikoColors.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Avatar section
                          _buildAvatarSection(),
                          const SizedBox(height: 24),

                          // Personal details card
                          _buildPersonalDetailsCard(),
                          const SizedBox(height: 20),

                          // Academic details card
                          _buildAcademicDetailsCard(),
                          const SizedBox(height: 28),

                          // Action buttons
                          _buildActionButtons(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: KikoColors.secondaryEmerald, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: KikoColors.secondaryEmerald.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/student_avatar_snowman.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: KikoColors.tertiaryMint,
                      child: const Icon(Icons.person, color: KikoColors.primaryForest, size: 48),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: KikoColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: KikoColors.secondaryEmerald, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 15,
                    color: KikoColors.primaryForest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Avatar photo editing uses your verified Google account picture.',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: KikoColors.primaryForest,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt_outlined, size: 15, color: KikoColors.textSecondary),
            label: const Text(
              'Change Photo',
              style: TextStyle(
                color: KikoColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: KikoColors.border),
              backgroundColor: KikoColors.secondarySurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: KikoColors.primaryForest, size: 20),
              const SizedBox(width: 8),
              Text(
                'Personal Details',
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Full Name
          _buildFieldLabel('Full Name *'),
          TextFormField(
            controller: _fullNameController,
            style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Full name is required';
              }
              if (val.trim().length < 2) {
                return 'Full name must be at least 2 characters';
              }
              if (val.length > 150) {
                return 'Full name is too long';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date of Birth
          _buildFieldLabel('Date of Birth'),
          InkWell(
            onTap: _selectDateOfBirth,
            borderRadius: BorderRadius.circular(12),
            child: IgnorePointer(
              child: TextFormField(
                controller: _dobController,
                style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
                decoration: _inputDecoration(
                  hint: 'Enter your date of birth (DD-MM-YYYY)',
                  prefixIcon: Icons.calendar_today_outlined,
                  suffixIcon: Icons.calendar_month_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gender
          _buildFieldLabel('Gender'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _genderOptions.contains(_selectedGender) ? _selectedGender : null,
            dropdownColor: KikoColors.surface,
            style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Select gender',
              prefixIcon: Icons.transgender_outlined,
            ),
            items: _genderOptions
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
          ),

          const SizedBox(height: 16),

          // City
          _buildFieldLabel('City (Optional)'),
          TextFormField(
            controller: _cityController,
            style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Enter your city',
              prefixIcon: Icons.location_on_outlined,
            ),
            validator: (val) {
              if (val != null && val.length > 100) {
                return 'City name is too long';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, color: KikoColors.primaryForest, size: 20),
              const SizedBox(width: 8),
              Text(
                'Academic Details',
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // College / Institution
          _buildFieldLabel('College / Institution'),
          TextFormField(
            controller: _institutionController,
            style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Enter your college / institution',
              prefixIcon: Icons.account_balance_outlined,
            ),
            validator: (val) {
              if (val != null && val.length > 200) {
                return 'Institution name is too long';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Degree / Course
          _buildFieldLabel('Degree / Course'),
          TextFormField(
            controller: _degreeController,
            style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Enter your degree / course',
              prefixIcon: Icons.menu_book_outlined,
            ),
            validator: (val) {
              if (val != null && val.length > 150) {
                return 'Degree name is too long';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Department
          _buildFieldLabel('Department'),
          TextFormField(
            controller: _departmentController,
            style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Enter your department',
              prefixIcon: Icons.groups_outlined,
            ),
            validator: (val) {
              if (val != null && val.length > 150) {
                return 'Department name is too long';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Academic Year & Semester row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;

              if (isNarrow) {
                return Column(
                  children: [
                    _buildFieldLabel('Academic Year'),
                    _buildYearDropdown(),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Semester'),
                    _buildSemesterDropdown(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Academic Year'),
                        _buildYearDropdown(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Semester'),
                        _buildSemesterDropdown(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _academicYearOptions.contains(_selectedAcademicYear)
          ? _selectedAcademicYear
          : null,
      dropdownColor: KikoColors.surface,
      style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
      decoration: _inputDecoration(
        hint: 'Select academic year',
        prefixIcon: Icons.calendar_month_outlined,
      ),
      items: _academicYearOptions
          .map((y) => DropdownMenuItem(value: y, child: Text(y)))
          .toList(),
      onChanged: (val) => setState(() => _selectedAcademicYear = val),
    );
  }

  Widget _buildSemesterDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _semesterOptions.contains(_selectedSemester) ? _selectedSemester : null,
      dropdownColor: KikoColors.surface,
      style: const TextStyle(color: KikoColors.textPrimary, fontSize: 14),
      decoration: _inputDecoration(
        hint: 'Select semester',
        prefixIcon: Icons.layers_outlined,
      ),
      items: _semesterOptions
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (val) => setState(() => _selectedSemester = val),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: KikoColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: KikoColors.surface,
      hintText: hint,
      hintStyle: const TextStyle(color: KikoColors.textPlaceholder, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: KikoColors.textSecondary, size: 18),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: KikoColors.textSecondary, size: 18)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KikoColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KikoColors.primaryForest, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KikoColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KikoColors.error, width: 1.5),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Save Changes
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            label: Text(
              _isSaving ? 'Saving Changes...' : 'Save Changes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: KikoColors.primaryForest,
              disabledBackgroundColor: KikoColors.primaryForest.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _isSaving ? null : _handleCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: KikoColors.border),
              backgroundColor: KikoColors.secondarySurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: KikoColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
