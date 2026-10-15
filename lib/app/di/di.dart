import 'package:disalive/data/repositories/auth_repository_impl.dart';
import 'package:disalive/data/repositories/category_channel_repository_impl.dart';
import 'package:disalive/data/repositories/channel_server_repository_impl.dart';
import 'package:disalive/data/repositories/chat_repository_impl.dart';
import 'package:disalive/data/repositories/chat_server_repository_impl.dart';
import 'package:disalive/data/repositories/email_repository_impl.dart';
import 'package:disalive/data/repositories/friends_repository_impl.dart';
import 'package:disalive/data/repositories/gifs_repository_impl.dart';
import 'package:disalive/data/repositories/invite_repository_impl.dart';
import 'package:disalive/data/repositories/members_repository_impl.dart';
import 'package:disalive/data/repositories/message_repository_impl.dart';
import 'package:disalive/data/repositories/permission_repository_impl.dart';
import 'package:disalive/data/repositories/preferred_reactions_repository_impl.dart';
import 'package:disalive/data/repositories/reactions_repository_impl.dart';
import 'package:disalive/data/repositories/requests_repository_impl.dart';
import 'package:disalive/data/repositories/role_member_repository_impl.dart';
import 'package:disalive/data/repositories/setting_repository_impl.dart';
import 'package:disalive/data/repositories/session_repository_impl.dart';
import 'package:disalive/data/repositories/server_repository_impl.dart';
import 'package:disalive/data/repositories/sticker_pack_repository_impl.dart';
import 'package:disalive/data/repositories/stickers_repository_impl.dart';
import 'package:disalive/data/repositories/user_repository_impl.dart';
import 'package:disalive/data/repositories/user_stickers_pack_repository_impl.dart';
import 'package:disalive/data/repositories/ws_repository_impl.dart';
import 'package:disalive/domain/repositories/auth_repository.dart';
import 'package:disalive/domain/repositories/category_channel_repository.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/email_repository.dart';
import 'package:disalive/domain/repositories/friends_repository.dart';
import 'package:disalive/domain/repositories/gifs_repository.dart';
import 'package:disalive/domain/repositories/invite_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/permission_repository.dart';
import 'package:disalive/domain/repositories/preferred_reactions_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/repositories/requests_repository.dart';
import 'package:disalive/domain/repositories/role_member_repository.dart';
import 'package:disalive/domain/repositories/setting_repository.dart';
import 'package:disalive/domain/repositories/session_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';
import 'package:disalive/domain/repositories/stickers_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/repositories/user_stickers_pack_repository.dart';
import 'package:disalive/domain/repositories/ws_repository.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:disalive/presentation/bloc/session/session_bloc.dart';
import 'package:disalive/presentation/bloc/theme/theme_cubit.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat_server/bloc/chat_server_bloc.dart';
import 'package:disalive/presentation/features/gifs/bloc/gif_bloc.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/reactions/bloc/preferred_reactions_bloc.dart';
import 'package:disalive/presentation/features/register/bloc/register_bloc.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/features/role_members/bloc/role_members_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/reset/bloc/reset_password_bloc.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/features/verify/bloc/verify_code_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  sl.registerLazySingleton<HttpClientService>(
    () => HttpClientService(secureStorage: sl()),
  );

  sl.registerFactory(() => ThemeCubit(sl<SettingsRepository>()));

  // Repositories
  sl.registerLazySingleton<WsEventBus>(() => WsEventBus());
  sl.registerLazySingleton<WsRepository>(() => WsRepositoryImpl());
  sl.registerLazySingleton<ChatServerRepository>(
    () => ChatServerRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl());
  sl.registerLazySingleton<SessionRepository>(() => SessionRepositoryImpl());
  sl.registerLazySingleton<ServerRepository>(() => ServerRepositoryImpl());
  sl.registerLazySingleton<ChannelServerRepository>(
    () => ChannelServerRepositoryImpl(),
  );
  sl.registerLazySingleton<CategoryChannelRepository>(
    () => CategoryChannelRepositoryImpl(),
  );
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());
  sl.registerLazySingleton<MessageRepository>(() => MessageRepositoryImpl());
  sl.registerLazySingleton<PermissionRepository>(
    () => PermissionRepositoryImpl(),
  );
  sl.registerLazySingleton<RequestsRepository>(() => RequestsRepositoryImpl());
  sl.registerLazySingleton<InviteRepository>(() => InviteRepositoryImpl());
  sl.registerLazySingleton<RoleMemberRepository>(
    () => RoleMemberRepositoryImpl(),
  );
  sl.registerLazySingleton<MembersRepository>(() => MembersRepositoryImpl());
  sl.registerLazySingleton<FriendsRepository>(() => FriendsRepositoryImpl());
  sl.registerLazySingleton<EmailRepository>(() => EmailRepositoryImpl());
  sl.registerLazySingleton<GifsRepository>(() => GifsRepositoryImpl());
  sl.registerLazySingleton<StickerPackRepository>(
    () => StickerPackRepositoryImpl(),
  );
  sl.registerLazySingleton<ReactionsRepository>(
    () => ReactionsRepositoryImpl(),
  );
  sl.registerLazySingleton<PreferredReactionsRepository>(
    () => PreferredReactionsRepositoryImpl(),
  );
  sl.registerLazySingleton<UserStickersPackRepository>(
    () => UserStickersPackRepositoryImpl(),
  );
  sl.registerLazySingleton<StickersRepository>(() => StickersRepositoryImpl());

  // BLoC
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl(), sl()));
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(sl(), sl(), sl()));
  sl.registerFactory<ChatBloc>(() => ChatBloc(sl(), sl()));
  sl.registerFactory<MessageBloc>(() => MessageBloc(sl(), sl(), sl(), sl()));
  sl.registerFactory<ChatServerBloc>(() => ChatServerBloc(sl()));
  sl.registerFactory<RequestsBloc>(() => RequestsBloc(sl(), sl()));
  sl.registerFactory<MembersBloc>(() => MembersBloc(sl(), sl()));
  sl.registerFactory<InvitesBloc>(() => InvitesBloc(sl<InviteRepository>()));
  sl.registerFactoryParam<RoleMembersBloc, int, EntityType>(
    (entityId, entityType) => RoleMembersBloc(
      sl<RoleMemberRepository>(),
      sl<WsEventBus>(),
      entityId: entityId,
      entityType: entityType,
    ),
  );
  sl.registerFactory(
    () => ServersBloc(sl<ServerRepository>(), sl<WsEventBus>()),
  );
  sl.registerFactory<SessionBloc>(() => SessionBloc(sl(), sl(), sl(), sl()));
  sl.registerFactory<RegisterBloc>(() => RegisterBloc(sl(), sl()));
  sl.registerFactory<VerifyCodeBloc>(() => VerifyCodeBloc(sl(), sl()));
  sl.registerFactory<ResetPasswordBloc>(() => ResetPasswordBloc(sl(), sl()));
  sl.registerFactory<GifBloc>(() => GifBloc(sl()));
  sl.registerFactory<StickersPackBloc>(
    () => StickersPackBloc(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<PreferredReactionsBloc>(
    () => PreferredReactionsBloc(sl<PreferredReactionsRepositoryImpl>()),
  );
}
