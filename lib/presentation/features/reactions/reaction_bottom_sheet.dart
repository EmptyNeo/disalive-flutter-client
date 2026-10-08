import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/emojis/emoji_definition.dart';
import 'package:disalive/domain/models/preferred_reaction.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/tabs/emojis_tab.dart';
import 'package:flutter/cupertino.dart';

class ReactionBottomSheet extends StatefulWidget {
  final Function(EmojiDefinition emoji) onReactionSelected;
  final List<PreferredReaction>? preferredReactions;

  const ReactionBottomSheet({
    super.key,
    required this.onReactionSelected,
    required this.preferredReactions,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(EmojiDefinition emoji) onReactionSelected,
    required List<PreferredReaction>? preferredReactions,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => ReactionBottomSheet(
        onReactionSelected: onReactionSelected,
        preferredReactions: preferredReactions,
      ),
    );
  }

  @override
  State<ReactionBottomSheet> createState() => _ReactionBottomSheetState();
}

class _ReactionBottomSheetState extends State<ReactionBottomSheet>
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
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
                    children: [
                      _buildGrabber(),

                      Expanded(
                        child: EmojisTab(
                          onTap: (emoji) {
                            widget.onReactionSelected(emoji);
                            Navigator.of(context).pop();
                          },
                          onBackspace: null,
                          preferredReactions: widget.preferredReactions,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrabber() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.greyple,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
