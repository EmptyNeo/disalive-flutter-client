import 'dart:async';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/server_tag.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:flutter/cupertino.dart';

class ServerTagsField extends StatefulWidget {
  const ServerTagsField({
    super.key,
    required this.initialTags,
    required this.onChanged,
  });

  final List<ServerTag> initialTags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ServerTagsField> createState() => _ServerTagsFieldState();
}

class _ServerTagsFieldState extends State<ServerTagsField> {
  final TextEditingController _controller = TextEditingController();
  late final List<String> _selected = widget.initialTags
      .map((tag) => tag.name)
      .toList();
  Timer? _debounce;
  int _searchVersion = 0;
  List<ServerTag> _suggestions = const [];
  String? _error;
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final version = ++_searchVersion;
    final query = value.trim();
    if (query.isEmpty || _selected.length >= 3) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final result = await sl<ServerRepository>().searchTags(query);
      if (!mounted || version != _searchVersion) return;
      result.fold(
        (failure) => setState(() {
          _searching = false;
          _suggestions = const [];
          _error = failure.message;
        }),
        (tags) => setState(() {
          _searching = false;
          _suggestions = tags
              .where((tag) => !_contains(tag.name))
              .take(5)
              .toList();
        }),
      );
    });
  }

  bool _contains(String name) =>
      _selected.any((tag) => tag.toLowerCase() == name.toLowerCase());

  void _add(String value) {
    final name = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return;
    if (name.runes.length > 32) {
      setState(() => _error = 'Тег не может превышать 32 символа');
      return;
    }
    if (_selected.length >= 3) {
      setState(() => _error = 'Можно добавить не более 3 тегов');
      return;
    }
    if (_contains(name)) {
      setState(() => _error = 'Этот тег уже добавлен');
      return;
    }
    setState(() {
      _selected.add(name);
      _controller.clear();
      _suggestions = const [];
      _searching = false;
      _error = null;
    });
    ++_searchVersion;
    _debounce?.cancel();
    widget.onChanged(List.unmodifiable(_selected));
  }

  void _remove(String name) {
    setState(() => _selected.remove(name));
    widget.onChanged(List.unmodifiable(_selected));
    _onQueryChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        key: const ValueKey('server_tags_field'),
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.actionGrey,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final name in _selected)
              Semantics(
                button: true,
                label: 'Удалить тег $name',
                child: GestureDetector(
                  onTap: () => _remove(name),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width - 64,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blurple.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          CupertinoIcons.xmark,
                          color: AppColors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_selected.length < 3)
              SizedBox(
                width: 160,
                child: CupertinoTextField(
                  key: const ValueKey('server_tag_input'),
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  onSubmitted: _add,
                  placeholder: 'Добавить тег',
                  maxLength: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  style: TextStyle(color: AppColors.white),
                  decoration: null,
                  suffix: _controller.text.trim().isEmpty
                      ? null
                      : CupertinoButton(
                          key: const ValueKey('server_tag_add'),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          onPressed: () => _add(_controller.text),
                          child: const Icon(
                            CupertinoIcons.add_circled,
                            size: 22,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
      if (_searching)
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: CupertinoActivityIndicator(),
        ),
      if (_suggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: AppColors.actionGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (final tag in _suggestions)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(double.infinity, 40),
                  onPressed: () => _add(tag.name),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tag.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${tag.usageCount} исп.',
                        style: TextStyle(color: AppColors.greyple),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _error!,
            style: TextStyle(color: AppColors.errorRed, fontSize: 12),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          '${_selected.length}/3 тега',
          style: TextStyle(color: AppColors.greyple, fontSize: 12),
        ),
      ),
    ],
  );
}
