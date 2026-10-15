part of 'category_channel_bloc.dart';

abstract class CategoryChannelEvent extends Equatable {
  const CategoryChannelEvent();

  @override
  List<Object?> get props => [];
}

class GetChannelCategories extends CategoryChannelEvent {
  final int serverId;

  const GetChannelCategories(this.serverId);

  @override
  List<Object?> get props => [serverId];
}

class ChannelCategoryUpserted extends CategoryChannelEvent {
  final int serverId;
  final Map<String, dynamic> categoryData;

  const ChannelCategoryUpserted(this.serverId, this.categoryData);

  @override
  List<Object?> get props => [serverId, categoryData];
}

class ChannelCategoryRemoved extends CategoryChannelEvent {
  final int serverId;
  final int id;

  const ChannelCategoryRemoved(this.serverId, this.id);

  @override
  List<Object?> get props => [serverId, id];
}
