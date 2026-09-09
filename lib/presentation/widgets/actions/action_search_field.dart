import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActionSearchField extends StatefulWidget {
  const ActionSearchField({super.key});

  @override
  State<ActionSearchField> createState() => _ActionSearchFieldState();
}

class _ActionSearchFieldState extends State<ActionSearchField> {
  late final ChatBloc _chatBloc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _chatBloc.add(SearchChats(''));
    super.dispose();
  }

  void _onSearchChanged() {
    _chatBloc.add(SearchChats(_searchController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.search, color: AppColors.greyple, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField(
                controller: _searchController,
                placeholder: 'Поиск',
                placeholderStyle: TextStyle(
                  color: AppColors.greyple,
                  fontSize: 14,
                ),
                style: TextStyle(color: AppColors.white, fontSize: 14),
                decoration: null,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
