import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/gif_type_search.dart';
import 'package:disalive/domain/models/gif.dart';
import 'package:disalive/presentation/features/gifs/bloc/gif_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class GifsTab extends StatefulWidget {
  final Function(Gif gif) onTap;

  const GifsTab({super.key, required this.onTap});

  @override
  State<GifsTab> createState() => _GifsTabState();
}

class _GifsTabState extends State<GifsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // 🎯 ДОБАВЛЯЕМ КОНТРОЛЛЕР
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll); // 🎯 СЛУШАЕМ ПРОКРУТКУ
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<GifBloc>().state;

      if (state is GifLoaded && !state.hasReachedMax && !state.isLoadingMore) {
        context.read<GifBloc>().add(
          LoadGifs(
            type: state.currentType,
            tags: state.currentTags,
            skip: state.skip,
            take: state.take,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      // 🎯 При новом поиске прокручиваем список наверх для лучшего UX
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      context.read<GifBloc>().add(
        LoadGifs(
          type: query.isEmpty
              ? GifTypeSearch.popular
              : GifTypeSearch.searchGifs,
          tags: query,
          skip: 0,
          take: 20,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🎯 1. СЕТКА GIF
        BlocBuilder<GifBloc, GifState>(
          builder: (context, state) {
            if (state is GifLoading && state is! GifLoaded) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (state is GifLoaded) {
              return GridView.builder(
                controller: _scrollController,
                // 🎯 ПРИВЯЗЫВАЕМ КОНТРОЛЛЕР
                padding: const EdgeInsets.fromLTRB(8, 65, 8, 60),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                // 🎯 Добавляем +1 элемент для индикатора загрузки, если есть куда грузить
                itemCount: state.gifs.length + (state.hasReachedMax ? 0 : 1),
                itemBuilder: (context, index) {
                  // 🎯 ИНДИКАТОР ЗАГРУЗКИ ВНИЗУ СЕТКИ
                  if (index == state.gifs.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }

                  final gif = state.gifs[index];

                  return GestureDetector(
                    onTap: () => widget.onTap.call(gif),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: gif.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(radius: 10),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          CupertinoIcons.photo_fill,
                          color: AppColors.greyple,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // 🎯 2. ПЛАВАЮЩЕЕ ПОЛЕ ПОИСКА (Стеклянный эффект)
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CupertinoTextField(
              controller: _searchController,
              placeholder: 'Поиск GIF...',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
              placeholderStyle: AppText.mediumTextStyle.copyWith(
                color: AppColors.greyple,
              ),
              onChanged: _onSearchChanged,
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  CupertinoIcons.search,
                  color: AppColors.greyple,
                  size: 18,
                ),
              ),
            ),
          ),
        ),

        // 🎯 3. ПЛАВАЮЩАЯ АТРИБУЦИЯ
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'РАБОТАЕТ НА ',
                        style: AppText.lowTextStyle.copyWith(
                          color: AppColors.greyple,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SvgPicture.asset('assets/gifs/logo.svg', height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
