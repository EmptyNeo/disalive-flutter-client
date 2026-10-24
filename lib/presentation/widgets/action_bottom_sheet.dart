import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/preferred_reaction.dart';
import 'package:disalive/domain/models/reaction_message.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/presentation/features/reactions/bloc/preferred_reactions_bloc.dart';
import 'package:disalive/presentation/features/reactions/reaction_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActionBottomSheet extends StatefulWidget {
  final String? title;
  final List<ActionItem> actions;
  final List<PreferredReaction>? preferredReactions;
  final Function(PreferredReaction)? onReactionTap;

  const ActionBottomSheet({
    super.key,
    this.title,
    required this.actions,
    this.preferredReactions,
    this.onReactionTap,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    required List<ActionItem> actions,
    List<PreferredReaction>? preferredReactions,
    Function(PreferredReaction)? onReactionTap,
  }) {
    final preferredReactionsBloc = _tryReadBloc(context);

    final sheet = ActionBottomSheet(
      title: title,
      actions: actions,
      preferredReactions: preferredReactionsBloc != null
          ? preferredReactions
          : null,
      onReactionTap: preferredReactionsBloc != null ? onReactionTap : null,
    );

    return showCupertinoModalPopup(
      context: context,
      builder: (_) => preferredReactionsBloc != null
          ? BlocProvider.value(value: preferredReactionsBloc, child: sheet)
          : sheet,
    );
  }

  static PreferredReactionsBloc? _tryReadBloc(BuildContext context) {
    try {
      return context.read<PreferredReactionsBloc>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  State<ActionBottomSheet> createState() => _ActionBottomSheetState();
}

class _ActionBottomSheetState extends State<ActionBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  double _dragExtent = 0;

  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 700;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleGrabberDragUpdate(DragUpdateDetails details) {
    if (_dragExtent <= 0 && details.delta.dy < 0) return;
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dy).clamp(0, 600);
    });
  }

  void _handleGrabberDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragExtent > _dismissDistance || velocity > _dismissVelocity) {
      _dismiss();
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    final animation = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    void listener() => setState(() => _dragExtent = animation.value);
    animation.addListener(listener);
    _slideController
        .forward(from: 0)
        .whenComplete(() => animation.removeListener(listener));
  }

  void _dismiss() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final animation = Tween<double>(
      begin: _dragExtent,
      end: screenHeight,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));
    void listener() => setState(() => _dragExtent = animation.value);
    animation.addListener(listener);
    _slideController.forward(from: 0).whenComplete(() {
      animation.removeListener(listener);
      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _dragExtent),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _handleGrabberDragUpdate,
            onVerticalDragEnd: _handleGrabberDragEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.glassPanelTop,
                      AppColors.glassPanelBottom,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // Позволяет шторке сжиматься, если элементов мало
                  children: [
                    _buildGrabber(),
                    if (widget.title != null) _buildHeader(),
                    if (widget.preferredReactions != null &&
                        widget.preferredReactions!.isNotEmpty)
                      _buildFrequentReactionsRow(),

                    // 🎯 ИСПРАВЛЕНИЕ: Ограничиваем высоту и добавляем прокрутку
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        // Максимальная высота шторки — 60% от высоты экрана
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final action in widget.actions)
                                _buildActionTile(context, action),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrabber() {
    return const Padding(
      padding: EdgeInsets.only(top: 10, bottom: 8),
      child: Center(child: _GrabberHandle()),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: AppColors.blurple,
              borderRadius: BorderRadius.circular(2),
            ),
            constraints: const BoxConstraints(minHeight: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.lowTextStyle.copyWith(
                      color: AppColors.greyple, // 🎯 Уже динамический
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentReactionsRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: widget.preferredReactions!.asMap().entries.map((entry) {
              final index = entry.key;
              final pref = entry.value;
              final isLast = index == widget.preferredReactions!.length - 1;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: ReactionItem(
                    reaction: ReactionMessage(
                      nameReaction: pref.nameReaction,
                      hasUserReaction: false,
                    ),
                    isMine: false,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onReactionTap?.call(pref);
                    },
                    minHeight: 40,
                    emojiSize: 25,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, ActionItem action) {
    final color =
        action.color ??
        (action.isDestructive ? AppColors.errorRed : AppColors.white);

    return _PressableRow(
      onTap: () {
        Navigator.pop(context);
        action.onTap?.call();
      },
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: action.leading ?? Icon(action.icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.label,
                  style: AppText.mediumTextStyle.copyWith(color: color),
                ),
                if (action.subtitle != null)
                  Text(
                    action.subtitle!,
                    style: AppText.lowTextStyle.copyWith(
                      color: AppColors.greyple,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrabberHandle extends StatelessWidget {
  const _GrabberHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.greyple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _PressableRow extends StatefulWidget {
  const _PressableRow({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableRow> createState() => _PressableRowState();
}

class _PressableRowState extends State<_PressableRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.98 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.glassPanelPressed.withValues(alpha: 0.6)
                : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
