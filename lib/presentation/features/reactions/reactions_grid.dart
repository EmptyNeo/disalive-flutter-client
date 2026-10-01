// lib/presentation/features/message/widgets/reactions/reactions_grid.dart
import 'package:disalive/domain/models/reaction_message.dart';
import 'package:disalive/presentation/features/reactions/reaction_item.dart';
import 'package:flutter/cupertino.dart';

/// Построчная сетка реакций под сообщением: чипы [ReactionItem] идут в
/// [Wrap] и сами переносятся на следующую строку, если не помещаются
/// по ширине пузыря сообщения.
class ReactionsGrid extends StatelessWidget {
  final List<ReactionMessage> reactions;
  final void Function(ReactionMessage reaction)? onTapReaction;

  const ReactionsGrid({super.key, required this.reactions, this.onTapReaction});

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactions
          .map(
            (reaction) => ReactionItem(
              reaction: reaction,
              onTap: onTapReaction == null
                  ? null
                  : () => onTapReaction!(reaction),
            ),
          )
          .toList(),
    );
  }
}
