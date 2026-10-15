part of 'category_channel_bloc.dart';

abstract class CategoryChannelState extends Equatable {
  const CategoryChannelState();

  @override
  List<Object?> get props => [];
}

class CategoryChannelInitial extends CategoryChannelState {}

class ChannelCategoriesLoading extends CategoryChannelState {
  final int serverId;
  const ChannelCategoriesLoading(this.serverId);

  @override
  List<Object?> get props => [serverId];
}

class ChannelCategoriesLoaded extends CategoryChannelState {
  final int serverId;
  final List<CategoryChannel> categories;

  const ChannelCategoriesLoaded(this.serverId, this.categories);

  @override
  List<Object?> get props => [serverId, categories];
}

class ChannelCategoriesFailure extends CategoryChannelState {
  final int serverId;
  final Failure error;

  const ChannelCategoriesFailure(this.serverId, this.error);

  @override
  List<Object?> get props => [serverId, error];
}
