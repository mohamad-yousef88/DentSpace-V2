import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/tool.dart';
import '../../domain/repositories/tools_repository.dart';
import '../bloc/tools_bloc.dart';
import '../bloc/tools_event.dart';
import '../bloc/tools_state.dart';
import '../widgets/tool_form.dart';

/// Edit an existing tool.
///
/// Image operations are **immediate** — the user taps to add / remove,
/// and the corresponding network call fires right away (the tool already
/// exists). Field changes are batched behind the "Save" button.
class EditToolPage extends StatefulWidget {
  const EditToolPage({super.key, required this.toolId});
  final int toolId;

  @override
  State<EditToolPage> createState() => _EditToolPageState();
}

class _EditToolPageState extends State<EditToolPage> {
  late final ToolsBloc _bloc;
  late final ImagePickerService _picker;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _category;
  String? _condition;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<ToolsBloc>();
    _picker = GetIt.instance<ImagePickerService>();
    _bloc.add(LoadToolByIdEvent(widget.toolId));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _seedFromTool(Tool tool) {
    if (_initialised) return;
    _initialised = true;
    _nameCtrl.text = tool.name;
    _descCtrl.text = tool.description;
    _priceCtrl.text = tool.price.toStringAsFixed(2);
    _category = tool.category;
    _condition = tool.condition;
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _addImages() async {
    final tool = _bloc.state.currentTool;
    if (tool == null) return;

    final remaining = 5 - tool.imageCount;
    if (remaining <= 0) return;

    final files = await _picker.pickMultipleFromGallery(limit: remaining);
    if (!mounted || files.isEmpty) return;

    for (final f in files) {
      _bloc.add(UploadToolImageEvent(toolId: tool.id, path: f.path));
    }
  }

  Future<void> _removeExisting(int index) async {
    final tool = _bloc.state.currentTool;
    if (tool == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          context.read<LocalizationCubit>().state.languageCode == 'ar'
              ? 'حذف الصورة'
              : 'Delete image',
        ),
        content: Text(
          context.read<LocalizationCubit>().state.languageCode == 'ar'
              ? 'هل تريد حذف هذه الصورة؟'
              : 'Remove this image?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.read<LocalizationCubit>().state.languageCode == 'ar'
                  ? 'رجوع'
                  : 'Cancel',
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              context.read<LocalizationCubit>().state.languageCode == 'ar'
                  ? 'حذف'
                  : 'Delete',
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _bloc.add(DeleteToolImageEvent(toolId: tool.id, index: index));
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_category == null || _condition == null) return;

    _bloc.add(UpdateToolEvent(
      id: widget.toolId,
      params: UpdateToolParams(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        condition: _condition,
        price: double.tryParse(_priceCtrl.text.trim()),
      ),
    ),);
  }

  Future<void> _deleteTool() async {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isArabic ? 'حذف الأداة' : 'Delete tool'),
        content: Text(
          isArabic
              ? 'سيتم حذف الأداة وصورها نهائياً. هل أنت متأكد؟'
              : 'This will permanently delete the tool and its images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'رجوع' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _bloc.add(DeleteToolEvent(widget.toolId));
    }
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
          if (state.successMessage == 'tool_updated') {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(
                  isArabic ? 'تم حفظ التعديلات' : 'Changes saved',
                ),
                backgroundColor: AppColors.success,
              ),);
            _bloc.add(const ClearToolFeedbackEvent());
            context.pop(true);
            return;
          }
          if (state.successMessage == 'tool_deleted') {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(
                  isArabic ? 'تم حذف الأداة' : 'Tool deleted',
                ),
                backgroundColor: AppColors.success,
              ),);
            _bloc.add(const ClearToolFeedbackEvent());
            context.pop(true);
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
          final tool = state.currentTool;

          if (tool == null && state.isLoading) {
            return Scaffold(
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              appBar: AppBar(
                backgroundColor: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                elevation: 0,
              ),
              body: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (tool == null) {
            return Scaffold(
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              appBar: AppBar(elevation: 0),
              body: const Center(child: Text('Tool not found')),
            );
          }

          _seedFromTool(tool);
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
                isArabic ? 'تعديل الأداة' : 'Edit Tool',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: isArabic ? 'حذف الأداة' : 'Delete tool',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                  onPressed: isSubmitting ? null : _deleteTool,
                ),
              ],
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
              imagePaths: const [],
              existingImages: tool.imageUrls,
              onAddImages: _addImages,
              onRemoveImage: (_) {}, // unused in edit
              onRemoveExistingImage: _removeExisting,
              isSubmitting: isSubmitting,
            ),
            bottomNavigationBar: DecoratedBox(
              decoration: BoxDecoration(
                color:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: FilledButton.icon(
                    onPressed: isSubmitting ? null : _save,
                    icon: isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      isArabic ? 'حفظ التعديلات' : 'Save changes',
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
            ),
          );
        },
      ),
    );
  }
}