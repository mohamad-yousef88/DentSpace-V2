import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/repositories/tools_repository.dart';
import '../bloc/tools_bloc.dart';
import '../bloc/tools_event.dart';
import '../bloc/tools_state.dart';
import '../widgets/tool_form.dart';

class CreateToolPage extends StatefulWidget {
  const CreateToolPage({super.key});

  @override
  State<CreateToolPage> createState() => _CreateToolPageState();
}

class _CreateToolPageState extends State<CreateToolPage> {
  late final ToolsBloc _bloc;
  late final ImagePickerService _picker;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _category;
  String? _condition;
  final List<String> _imagePaths = [];

  /// ★ FIX #5 — guard against double-pop when 'tool_created' fires twice.
  bool _popInProgress = false;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<ToolsBloc>();
    _picker = GetIt.instance<ImagePickerService>();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _pickImages() async {
    final remaining = 5 - _imagePaths.length;
    if (remaining <= 0) return;
    final files = await _picker.pickMultipleFromGallery(limit: remaining);
    if (!mounted || files.isEmpty) return;
    setState(() => _imagePaths.addAll(files.map((f) => f.path)));
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_category == null || _condition == null) return;
    FocusScope.of(context).unfocus();

    _bloc.add(CreateToolWithImagesEvent(
      params: CreateToolParams(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category!,
        condition: _condition!,
        price: double.parse(_priceCtrl.text.trim()),
      ),
      imagePaths: List<String>.from(_imagePaths),
    ),);
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ToolsBloc, ToolsState>(
        listenWhen: (p, c) =>
        p.successMessage != c.successMessage ||
            p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.successMessage == 'tool_created' && !_popInProgress) {
            _popInProgress = true;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(
                  isArabic ? 'تم إنشاء الأداة' : 'Tool created',
                ),
                backgroundColor: AppColors.success,
              ),);
            _bloc.add(const ClearToolFeedbackEvent());
            // Defer to next frame so the SnackBar binds to a live context.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.pop(true);
            });
            return;
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),);
            _bloc.add(const ClearToolFeedbackEvent());
          }
        },
        builder: (context, state) {
          final isSubmitting = state.isSubmitting;

          return Scaffold(
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
                onPressed: isSubmitting ? null : () => context.pop(),
              ),
              title: Text(
                isArabic ? 'أداة جديدة' : 'New Tool',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),
            body: ToolForm(
              formKey: _formKey,
              nameCtrl: _nameCtrl,
              descCtrl: _descCtrl,
              priceCtrl: _priceCtrl,
              category: _category,
              condition: _condition,
              onCategoryChanged: (v) => setState(() => _category = v),
              onConditionChanged: (v) => setState(() => _condition = v),
              imagePaths: _imagePaths,
              onAddImages: _pickImages,
              onRemoveImage: _removeImage,
              isSubmitting: isSubmitting,
            ),
            bottomNavigationBar: _SubmitBar(
              isArabic: isArabic,
              isDark: isDark,
              isSubmitting: isSubmitting,
              onPressed: _submit,
            ),
          );
        },
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isArabic,
    required this.isDark,
    required this.isSubmitting,
    required this.onPressed,
  });
  final bool isArabic;
  final bool isDark;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onPressed,
            icon: isSubmitting
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
              isSubmitting
                  ? (isArabic ? 'جارٍ الإنشاء...' : 'Creating...')
                  : (isArabic ? 'نشر الأداة' : 'Publish tool'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}