import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/symptom_catalogue.dart';
import '../../domain/repositories/cases_repository.dart';
import '../bloc/cases_bloc.dart';
import '../bloc/cases_event.dart';
import '../bloc/cases_state.dart';
import '../widgets/diagnosis_result_card.dart';
import '../widgets/symptom_chip.dart';

class DiagnosisFormPage extends StatefulWidget {
  const DiagnosisFormPage({super.key});

  @override
  State<DiagnosisFormPage> createState() => _DiagnosisFormPageState();
}

class _DiagnosisFormPageState extends State<DiagnosisFormPage> {
  late final CasesBloc _bloc;
  late final ImagePickerService _picker;

  // ─── Form state ────────────────────────────────────────
  LocationItem? _location;
  final Set<String> _selectedSymptomKeys = {};   // ★ Arabic keys
  bool? _hasPain;
  SeverityItem? _painSeverity;
  bool? _hasSwelling;
  SeverityItem? _swellingSeverity;
  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<CasesBloc>();
    _picker = GetIt.instance<ImagePickerService>();
  }

  bool get _canPreview {
    return _location != null &&
        _selectedSymptomKeys.isNotEmpty &&
        _hasPain != null &&
        _hasSwelling != null &&
        (!(_hasPain ?? false) || _painSeverity != null) &&
        (!(_hasSwelling ?? false) || _swellingSeverity != null);
  }

  /// Build the input DTO using the Arabic keys only.
  CaseInput get _input => CaseInput(
    symptoms: _selectedSymptomKeys.toList(),
    location: _location!.key,
    hasPain: _hasPain ?? false,
    painSeverity: _painSeverity?.key,
    hasSwelling: _hasSwelling ?? false,
    swellingSeverity: _swellingSeverity?.key,
  );

  Future<void> _pickImage() async {
    final f = await _picker.pickFromGallery();
    if (f != null) {
      setState(() => _pickedImagePath = f.path);
    }
  }

  Future<void> _confirmCreate() async {
    final result = await _bloc.stream.firstWhere(
          (s) => s.successMessage == 'case_created' || s.errorMessage != null,
    );

    if (!mounted) return;

    if (result.successMessage == 'case_created') {
      if (_pickedImagePath != null && result.cases.isNotEmpty) {
        final created = result.cases.first;
        _bloc.add(UploadImageEvent(
          caseId: created.id,
          path: _pickedImagePath!,
        ),);
      }
      context.pop(true);
    } else if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.errorMessage!),
        backgroundColor: AppColors.error,
      ),);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isArabic ? 'حالة جديدة' : 'New case',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<CasesBloc, CasesState>(
          listener: (context, state) {
            if (state.errorMessage != null &&
                state.status == CasesStatus.failure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                ),);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    isArabic
                        ? 'أين مكان المشكلة؟'
                        : 'Where is the problem?',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kLocations
                        .map((loc) => SymptomChip(
                      label: loc.labelFor(isArabic: isArabic),
                      selected: _location?.key == loc.key,
                      onTap: () =>
                          setState(() => _location = loc),
                    ),)
                        .toList(),
                  ),

                  const SizedBox(height: 28),

                  _sectionTitle(
                    isArabic ? 'هل يوجد ألم؟' : 'Do you feel pain?',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _yesNo(
                    value: _hasPain,
                    onChanged: (v) => setState(() {
                      _hasPain = v;
                      if (v == false) _painSeverity = null;
                    }),
                    isArabic: isArabic,
                  ),
                  if (_hasPain == true) ...[
                    const SizedBox(height: 12),
                    _sectionTitle(
                      isArabic ? 'شدة الألم' : 'Pain severity',
                      isDark,
                      small: true,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: kSeverities
                          .map((s) => SymptomChip(
                        label: s.labelFor(isArabic: isArabic),
                        selected:
                        _painSeverity?.key == s.key,
                        onTap: () =>
                            setState(() => _painSeverity = s),
                      ),)
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 28),

                  _sectionTitle(
                    isArabic
                        ? 'هل يوجد تورم؟'
                        : 'Do you have swelling?',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _yesNo(
                    value: _hasSwelling,
                    onChanged: (v) => setState(() {
                      _hasSwelling = v;
                      if (v == false) _swellingSeverity = null;
                    }),
                    isArabic: isArabic,
                  ),
                  if (_hasSwelling == true) ...[
                    const SizedBox(height: 12),
                    _sectionTitle(
                      isArabic ? 'شدة التورم' : 'Swelling severity',
                      isDark,
                      small: true,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: kSeverities
                          .map((s) => SymptomChip(
                        label: s.labelFor(isArabic: isArabic),
                        selected:
                        _swellingSeverity?.key == s.key,
                        onTap: () =>
                            setState(() => _swellingSeverity = s),
                      ),)
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 28),

                  _sectionTitle(
                    isArabic
                        ? 'اختر الأعراض المرتبطة'
                        : 'Select related symptoms',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  ...kSymptomGroups.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                          const EdgeInsets.only(top: 14, bottom: 8),
                          child: Text(
                            group.titleFor(isArabic: isArabic),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: group.symptoms.map((s) {
                            final selected =
                            _selectedSymptomKeys.contains(s.key);
                            return SymptomChip(
                              label: s.labelFor(isArabic: isArabic),
                              selected: selected,
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedSymptomKeys.remove(s.key);
                                } else {
                                  _selectedSymptomKeys.add(s.key);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 28),

                  _sectionTitle(
                    isArabic
                        ? 'صورة بانورامية (اختياري)'
                        : 'Panoramic image (optional)',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _imagePicker(isArabic, isDark),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _canPreview && !state.isPreviewing
                          ? () =>
                          _bloc.add(PreviewDiagnosisEvent(_input))
                          : null,
                      icon: state.isPreviewing
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                          : const Icon(Icons.psychology_outlined,
                          size: 20,),
                      label: Text(
                        isArabic
                            ? 'معاينة التشخيص الأولي'
                            : 'Preview preliminary diagnosis',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color:
                          AppColors.primary.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  if (state.preview != null) ...[
                    const SizedBox(height: 24),
                    DiagnosisResultCard(preview: state.preview!),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () {
                          _bloc.add(CreateCaseEvent(_input));
                          _confirmCreate();
                        },
                        icon: state.isLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          isArabic
                              ? 'تأكيد وحفظ الحالة'
                              : 'Confirm & save',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark, {bool small = false}) {
    return Text(
      title,
      style:
      (small ? AppTextStyles.labelLarge : AppTextStyles.titleMedium)
          .copyWith(
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _yesNo({
    required bool? value,
    required ValueChanged<bool> onChanged,
    required bool isArabic,
  }) {
    return Row(
      children: [
        Expanded(
          child: SymptomChip(
            label: isArabic ? 'نعم' : 'Yes',
            selected: value == true,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SymptomChip(
            label: isArabic ? 'لا' : 'No',
            selected: value == false,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }

  Widget _imagePicker(bool isArabic, bool isDark) {
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _pickImage,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _pickedImagePath == null
                    ? Icons.add_photo_alternate_outlined
                    : Icons.check_circle_rounded,
                color: _pickedImagePath == null
                    ? AppColors.primary
                    : AppColors.success,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _pickedImagePath == null
                      ? (isArabic
                      ? 'اختر صورة من المعرض'
                      : 'Pick an image from gallery')
                      : (isArabic
                      ? 'تم اختيار الصورة'
                      : 'Image selected'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? Colors.white70
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}