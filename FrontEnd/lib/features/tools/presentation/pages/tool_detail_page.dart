import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../orders/domain/repositories/orders_repository.dart';
import '../../../orders/presentation/bloc/orders_bloc.dart';
import '../../../orders/presentation/bloc/orders_event.dart';
import '../../../orders/presentation/bloc/orders_state.dart';
import '../../data/tool_catalogue.dart';
import '../../domain/entities/tool.dart';
import '../bloc/tools_bloc.dart';
import '../bloc/tools_event.dart';
import '../bloc/tools_state.dart';

class ToolDetailPage extends StatefulWidget {
  const ToolDetailPage({super.key, required this.toolId});
  final int toolId;

  @override
  State<ToolDetailPage> createState() => _ToolDetailPageState();
}

class _ToolDetailPageState extends State<ToolDetailPage> {
  late final ToolsBloc _bloc;
  late final OrdersBloc _orders;

  /// Prevents duplicate dispatches when the bottom sheet re-submits.
  bool _orderInFlight = false;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<ToolsBloc>();
    _orders = GetIt.instance<OrdersBloc>();
    _bloc.add(LoadToolByIdEvent(widget.toolId));
  }

  bool get _isOwner {
    final me = GetIt.instance<AuthBloc>().state.user;
    final tool = _bloc.state.currentTool;
    return me != null && tool != null && me.id == tool.sellerId;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloc),
        BlocProvider.value(value: _orders),
      ],
      // ★ FIX #4 — use BlocListener (no race condition).
      child: BlocListener<OrdersBloc, OrdersState>(
        listenWhen: (p, c) =>
        p.successMessage != c.successMessage ||
            p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (!_orderInFlight) return;

          if (state.successMessage == 'order_created') {
            _orderInFlight = false;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(
                  isArabic
                      ? 'تم إرسال طلب الشراء بنجاح'
                      : 'Purchase request sent',
                ),
                backgroundColor: AppColors.success,
              ),);
            _orders.add(const ClearOrderFeedbackEvent());
            return;
          }

          if (state.errorMessage != null) {
            _orderInFlight = false;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),);
            _orders.add(const ClearOrderFeedbackEvent());
          }
        },
        child: BlocConsumer<ToolsBloc, ToolsState>(
          listenWhen: (p, c) =>
          p.successMessage != c.successMessage ||
              p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content:
                  Text(_feedback(isArabic, state.successMessage!)),
                  backgroundColor: AppColors.success,
                ),);
              _bloc.add(const ClearToolFeedbackEvent());
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

            return Scaffold(
              backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
              appBar: AppBar(
                backgroundColor: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
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
                  isArabic ? 'تفاصيل الأداة' : 'Tool details',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
              ),
              body: tool == null
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
                  : _buildBody(tool, isArabic, isDark),
              bottomNavigationBar: tool == null
                  ? null
                  : _buildBottomBar(tool, isArabic, isDark, state.isSubmitting),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Widget _buildBody(Tool tool, bool isArabic, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ImageCarousel(tool: tool, isDark: isDark),
          const SizedBox(height: 20),
          _HeaderCard(tool: tool, isArabic: isArabic, isDark: isDark),
          const SizedBox(height: 16),
          _DescriptionCard(tool: tool, isArabic: isArabic, isDark: isDark),
          if (tool.seller != null) ...[
            const SizedBox(height: 16),
            _SellerCard(
              seller: tool.seller!,
              isArabic: isArabic,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar(
      Tool tool,
      bool isArabic,
      bool isDark,
      bool isSubmitting,
      ) {
    if (_isOwner) return const SizedBox.shrink();
    if (!tool.canBeOrdered) return const SizedBox.shrink();

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
            onPressed: isSubmitting ? null : () => _showOrderSheet(tool, isArabic),
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
            label: Text(
              isArabic ? 'طلب الشراء' : 'Request purchase',
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

  // ═══════════════════════════════════════════════════════════════
  Future<void> _showOrderSheet(Tool tool, bool isArabic) async {
    final messageCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isArabic ? 'تأكيد طلب الشراء' : 'Confirm purchase',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'سيتم إشعار البائع بطلبك. يمكنك إضافة رسالة اختيارية.'
                          : 'The seller will be notified. You can add an optional message.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              tool.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '\$${tool.price.toStringAsFixed(2)}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'رسالة (اختياري)'
                            : 'Message (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        isArabic ? 'إرسال الطلب' : 'Send request',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final message = messageCtrl.text.trim();
    messageCtrl.dispose();

    if (confirmed != true || !mounted) return;

    // ★ FIX #4 — dispatch and let BlocListener handle the result.
    _orderInFlight = true;
    _orders.add(CreateOrderEvent(
      CreateOrderParams(
        toolId: tool.id,
        message: message.isEmpty ? null : message,
      ),
    ),);
  }

  String _feedback(bool isArabic, String code) {
    switch (code) {
      case 'tool_created':
        return isArabic ? 'تم إنشاء الأداة' : 'Tool created';
      case 'tool_updated':
        return isArabic ? 'تم تحديث الأداة' : 'Tool updated';
      case 'tool_deleted':
        return isArabic ? 'تم حذف الأداة' : 'Tool deleted';
      default:
        return isArabic ? 'تم' : 'Done';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Image carousel
// ═══════════════════════════════════════════════════════════════
class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.tool, required this.isDark});
  final Tool tool;
  final bool isDark;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.tool.hasImages) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: widget.isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.handyman_outlined,
          size: 64,
          color: widget.isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.tool.imageUrls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: widget.tool.imageUrls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => ColoredBox(
                    color: widget.isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: widget.isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    child: const Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.tool.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.tool.imageUrls.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _index == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _index == i
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Header card
// ═══════════════════════════════════════════════════════════════
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.tool,
    required this.isArabic,
    required this.isDark,
  });
  final Tool tool;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tool.name,
            style: AppTextStyles.headlineSmall.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\$${tool.price.toStringAsFixed(2)}',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: translateToolCategory(
                  tool.category,
                  isArabic: isArabic,
                ),
                color: AppColors.primary,
              ),
              _Chip(
                label: translateToolCondition(
                  tool.condition,
                  isArabic: isArabic,
                ),
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 350.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Description card
// ═══════════════════════════════════════════════════════════════
class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({
    required this.tool,
    required this.isArabic,
    required this.isDark,
  });
  final Tool tool;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'الوصف' : 'Description',
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tool.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 350.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// Seller card
// ═══════════════════════════════════════════════════════════════
class _SellerCard extends StatelessWidget {
  const _SellerCard({
    required this.seller,
    required this.isArabic,
    required this.isDark,
  });
  final ToolSellerBrief seller;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initial = seller.fullName.trim().isEmpty
        ? '?'
        : seller.fullName.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'البائع' : 'Seller',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  seller.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (seller.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    seller.phone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 350.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}