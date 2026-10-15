import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/category_channel_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

part 'category_channel_event.dart';
part 'category_channel_state.dart';

class CategoryChannelBloc
    extends Bloc<CategoryChannelEvent, CategoryChannelState> {
  final CategoryChannelRepository _repository;
  final WsEventBus _eventBus;
  StreamSubscription<WsEvent>? _subscription;
  final List<CategoryChannelEvent> _changesDuringLoad = [];
  int? _serverId;
  int _loadGeneration = 0;
  bool _isLoading = false;

  CategoryChannelBloc(this._repository, this._eventBus)
    : super(CategoryChannelInitial()) {
    on<GetChannelCategories>(_onGetChannelCategories);
    on<ChannelCategoryUpserted>(_onUpserted);
    on<ChannelCategoryRemoved>(_onRemoved);
    setupListeners();
  }

  void setupListeners() {
    _subscription?.cancel();
    _subscription = _eventBus.subscribeToTable(
      table: 'CategoryChannel',
      onData: (event) {
        final rawCategory = event.data['category'];
        final categoryData = rawCategory is Map
            ? Map<String, dynamic>.from(rawCategory)
            : <String, dynamic>{};
        final serverId = DataParser.parseInt(
          event.data['serverId'] ??
              event.data['entityId'] ??
              categoryData['serverId'],
        );
        if (serverId == null || serverId != _serverId) return;

        if (event.action == ActionType.create ||
            event.action == ActionType.update) {
          final id = DataParser.parseInt(
            categoryData['id'] ?? event.data['categoryId'],
          );
          if (id == null || rawCategory is! Map) return;
          categoryData['id'] = id;
          categoryData['serverId'] = serverId;
          add(ChannelCategoryUpserted(serverId, categoryData));
        } else if (event.action == ActionType.delete) {
          final id = DataParser.parseInt(
            event.data['categoryId'] ?? categoryData['id'],
          );
          if (id != null) add(ChannelCategoryRemoved(serverId, id));
        }
      },
    );
  }

  Future<void> _onGetChannelCategories(
    GetChannelCategories event,
    Emitter<CategoryChannelState> emit,
  ) async {
    if (_isLoading && _serverId == event.serverId) return;
    _serverId = event.serverId;
    _isLoading = true;
    final generation = ++_loadGeneration;
    _changesDuringLoad.clear();

    final cached = _repository.getCached(event.serverId);
    if (cached.isNotEmpty) {
      emit(ChannelCategoriesLoaded(event.serverId, List.unmodifiable(cached)));
    } else {
      emit(ChannelCategoriesLoading(event.serverId));
    }

    final result = await _repository.get(event.serverId);
    if (generation != _loadGeneration || isClosed) return;
    _isLoading = false;

    result.fold(
      (failure) {
        final current = _repository.getCached(event.serverId);
        if (current.isEmpty) {
          emit(ChannelCategoriesFailure(event.serverId, failure));
        } else {
          emit(
            ChannelCategoriesLoaded(event.serverId, List.unmodifiable(current)),
          );
        }
      },
      (loaded) {
        final categories = List<CategoryChannel>.from(loaded);
        for (final change in _changesDuringLoad) {
          if (change is ChannelCategoryUpserted) {
            _applyUpsert(categories, change.categoryData);
          } else if (change is ChannelCategoryRemoved) {
            categories.removeWhere((category) => category.id == change.id);
          }
        }
        _repository.updateCache(event.serverId, categories);
        emit(
          ChannelCategoriesLoaded(
            event.serverId,
            List.unmodifiable(categories),
          ),
        );
      },
    );
    _changesDuringLoad.clear();
  }

  void _onUpserted(
    ChannelCategoryUpserted event,
    Emitter<CategoryChannelState> emit,
  ) {
    if (event.serverId != _serverId) return;
    if (_isLoading) _changesDuringLoad.add(event);

    final categories = List<CategoryChannel>.from(
      _repository.getCached(event.serverId),
    );
    _applyUpsert(categories, event.categoryData);
    _repository.updateCache(event.serverId, categories);
    emit(
      ChannelCategoriesLoaded(event.serverId, List.unmodifiable(categories)),
    );
  }

  void _applyUpsert(
    List<CategoryChannel> categories,
    Map<String, dynamic> data,
  ) {
    final id = DataParser.parseInt(data['id']);
    if (id == null) return;
    final index = categories.indexWhere((item) => item.id == id);
    final previous = index < 0 ? null : categories[index];
    final category = CategoryChannel.fromMap({
      if (previous != null) ...previous.toMap(),
      ...data,
    });
    if (index < 0) {
      categories.add(category);
    } else {
      categories[index] = category;
    }
  }

  void _onRemoved(
    ChannelCategoryRemoved event,
    Emitter<CategoryChannelState> emit,
  ) {
    if (event.serverId != _serverId) return;
    if (_isLoading) _changesDuringLoad.add(event);

    final categories = List<CategoryChannel>.from(
      _repository.getCached(event.serverId),
    )..removeWhere((category) => category.id == event.id);
    _repository.updateCache(event.serverId, categories);
    emit(
      ChannelCategoriesLoaded(event.serverId, List.unmodifiable(categories)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    if (_serverId != null) _repository.clear(_serverId);
    await super.close();
  }
}
