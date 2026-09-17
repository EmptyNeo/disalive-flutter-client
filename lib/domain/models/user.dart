// lib/domain/models/user.dart
import 'dart:io';

import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/models/badge.dart';
import 'package:disalive/domain/models/badge_user.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/enums/user_status.dart';

class UserModel extends Equatable {
  final int? id;
  final int? rolePrefix;
  final String? username;
  final String? displayName;
  final String? email;
  final UserStatus? status;
  final String? dateRegistration;
  final String? pathImage;
  final String? pathBanner;
  final String? bannerColor;
  final String? fontUsername;
  final String? bageMainColor;
  final String? bageAdditionalColor;
  final String? aboutMe;
  final String? myThink;
  final bool? canSendMeRequest;
  final int? isBanned;
  final String? banExpiresAt;
  final String? complaintsBlockedUntil;
  final bool? isMyFriend;
  final int? personalChatId;
  final Map<String, dynamic>? friendRequest;
  final String? lastVisit;
  final bool? followLastVisit;
  final bool? allowComments;
  final bool? allowOnlyFriendsComments;
  final bool? onlyIBlocked;
  final bool? onlyTheyBlocked;
  final bool? bothBlocked;
  final bool? isAnyBlocked;
  final String? totpSecret;
  final int? totpEnabled;
  final List<BadgeUserModel>? badges;
  final int? fkMainBadge;
  final BadgeModel? mainBadge;
  final File? fileAvatar;
  final File? fileBanner;
  final bool? deleteAvatar;
  final bool? deleteBanner;

  const UserModel({
    this.id,
    this.rolePrefix,
    this.username,
    this.displayName,
    this.email,
    this.status,
    this.dateRegistration,
    this.pathImage,
    this.pathBanner,
    this.bannerColor,
    this.fontUsername,
    this.bageMainColor,
    this.bageAdditionalColor,
    this.aboutMe,
    this.myThink,
    this.canSendMeRequest,
    this.isBanned,
    this.banExpiresAt,
    this.complaintsBlockedUntil,
    this.isMyFriend,
    this.personalChatId,
    this.friendRequest,
    this.lastVisit,
    this.followLastVisit,
    this.allowComments,
    this.allowOnlyFriendsComments,
    this.onlyIBlocked,
    this.onlyTheyBlocked,
    this.bothBlocked,
    this.isAnyBlocked,
    this.totpSecret,
    this.totpEnabled,
    this.badges,
    this.fkMainBadge,
    this.mainBadge,
    this.fileAvatar,
    this.fileBanner,
    this.deleteAvatar,
    this.deleteBanner,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      rolePrefix: map['rolePrefix'],
      username: map['username'],
      displayName: map['displayName'],
      email: map['email'],
      status: map['status'] != null
          ? UserStatus.fromString(map['status'] as String)
          : null,
      dateRegistration: map['dateRegistration'],
      pathImage: map['pathImage'],
      pathBanner: map['pathBanner'],
      bannerColor: map['bannerColor'],
      fontUsername: map['fontUsername'],
      bageMainColor: map['bageMainColor'],
      bageAdditionalColor: map['bageAdditionalColor'],
      aboutMe: map['aboutMe'],
      myThink: map['myThink'],
      canSendMeRequest: DataParser.parseBool(map['canSendMeRequest']),
      isBanned: DataParser.parseInt(map['isBanned']),
      banExpiresAt: map['banExpiresAt'],
      complaintsBlockedUntil: map['complaintsBlockedUntil'],
      isMyFriend: DataParser.parseBool(map['isMyFriend']),
      personalChatId: DataParser.parseInt(map['personalChatId']),
      friendRequest: map['friendRequest'] is Map<String, dynamic>
          ? map['friendRequest']
          : null,
      lastVisit: map['lastVisit'],
      followLastVisit: DataParser.parseBool(map['followLastVisit']),
      allowComments: DataParser.parseBool(map['allowComments']),
      allowOnlyFriendsComments: DataParser.parseBool(
        map['allowOnlyFriendsComments'],
      ),
      onlyIBlocked: DataParser.parseBool(map['onlyIBlocked']),
      onlyTheyBlocked: DataParser.parseBool(map['onlyTheyBlocked']),
      bothBlocked: DataParser.parseBool(map['bothBlocked']),
      isAnyBlocked: DataParser.parseBool(map['isAnyBlocked']),
      totpSecret: map['totpSecret'],
      totpEnabled: DataParser.parseInt(map['totpEnabled']),
      badges: map['badges'] != null
          ? (map['badges'] as List)
                .map((e) => BadgeUserModel.fromMap(e as Map<String, dynamic>))
                .toList()
          : null,
      fkMainBadge: DataParser.parseInt(map['fkMainBadge']),
      mainBadge: map['mainBadge'] != null
          ? BadgeModel.fromMap(map['mainBadge'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (rolePrefix != null) 'rolePrefix': rolePrefix,
      if (username != null) 'username': username,
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (status != null) 'status': status?.value,
      if (dateRegistration != null) 'dateRegistration': dateRegistration,
      if (pathImage != null) 'pathImage': pathImage,
      if (pathBanner != null) 'pathBanner': pathBanner,
      if (bannerColor != null) 'bannerColor': bannerColor,
      if (fontUsername != null) 'fontUsername': fontUsername,
      if (bageMainColor != null) 'bageMainColor': bageMainColor,
      if (bageAdditionalColor != null)
        'bageAdditionalColor': bageAdditionalColor,
      if (aboutMe != null) 'aboutMe': aboutMe,
      if (myThink != null) 'myThink': myThink,
      if (canSendMeRequest != null)
        'canSendMeRequest': canSendMeRequest ?? false ? 1 : 0,
      if (isBanned != null) 'isBanned': isBanned,
      if (banExpiresAt != null) 'banExpiresAt': banExpiresAt,
      if (complaintsBlockedUntil != null)
        'complaintsBlockedUntil': complaintsBlockedUntil,
      if (isMyFriend != null) 'isMyFriend': isMyFriend,
      if (personalChatId != null) 'personalChatId': personalChatId,
      if (friendRequest != null) 'friendRequest': friendRequest,
      if (lastVisit != null) 'lastVisit': lastVisit,
      if (followLastVisit != null)
        'followLastVisit': followLastVisit ?? false ? 1 : 0,
      if (allowComments != null)
        'allowComments': allowComments ?? false ? 1 : 0,
      if (allowOnlyFriendsComments != null)
        'allowOnlyFriendsComments': allowOnlyFriendsComments ?? false ? 1 : 0,
      if (onlyIBlocked != null) 'onlyIBlocked': onlyIBlocked,
      if (onlyTheyBlocked != null) 'onlyTheyBlocked': onlyTheyBlocked,
      if (totpSecret != null) 'totpSecret': totpSecret,
      if (totpEnabled != null) 'totpEnabled': totpEnabled,
      if (badges != null) 'badges': badges?.map((e) => e.toMap()).toList(),
      if (fkMainBadge != null) 'fkMainBadge': fkMainBadge,
      if (mainBadge != null) 'mainBadge': mainBadge?.toMap(),
      if (deleteAvatar != null) 'deleteAvatar': deleteAvatar ?? false ? 1 : 0,
      if (deleteBanner != null) 'deleteBanner': deleteBanner ?? false ? 1 : 0,
    };
  }

  Map<String, File?> toMapFiles() {
    return {
      if (fileAvatar != null) "avatar": fileAvatar,
      if (fileBanner != null) "banner": fileBanner,
    };
  }

  UserModel copyWith({
    int? id,
    int? rolePrefix,
    String? username,
    String? displayName,
    String? email,
    UserStatus? status,
    String? dateRegistration,
    String? pathImage,
    String? pathBanner,
    String? bannerColor,
    String? fontUsername,
    String? bageMainColor,
    String? bageAdditionalColor,
    String? aboutMe,
    String? myThink,
    bool? canSendMeRequest,
    int? isBanned,
    String? banExpiresAt,
    String? complaintsBlockedUntil,
    bool? isMyFriend,
    int? personalChatId,
    Map<String, dynamic>? friendRequest,
    String? lastVisit,
    bool? followLastVisit,
    bool? allowComments,
    bool? allowOnlyFriendsComments,
    bool? onlyIBlocked,
    bool? onlyTheyBlocked,
    bool? bothBlocked,
    bool? isAnyBlocked,
    String? totpSecret,
    int? totpEnabled,
    List<BadgeUserModel>? badges,
    int? fkMainBadge,
    BadgeModel? mainBadge,
    File? fileAvatar,
    File? fileBanner,
    bool? deleteAvatar,
    bool? deleteBanner,
  }) {
    return UserModel(
      id: id ?? this.id,
      rolePrefix: rolePrefix ?? this.rolePrefix,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      status: status ?? this.status,
      dateRegistration: dateRegistration ?? this.dateRegistration,
      pathImage: pathImage ?? this.pathImage,
      pathBanner: pathBanner ?? this.pathBanner,
      bannerColor: bannerColor ?? this.bannerColor,
      fontUsername: fontUsername ?? this.fontUsername,
      bageMainColor: bageMainColor ?? this.bageMainColor,
      bageAdditionalColor: bageAdditionalColor ?? this.bageAdditionalColor,
      aboutMe: aboutMe ?? this.aboutMe,
      myThink: myThink ?? this.myThink,
      canSendMeRequest: canSendMeRequest ?? this.canSendMeRequest,
      isBanned: isBanned ?? this.isBanned,
      banExpiresAt: banExpiresAt ?? this.banExpiresAt,
      complaintsBlockedUntil:
          complaintsBlockedUntil ?? this.complaintsBlockedUntil,
      isMyFriend: isMyFriend ?? this.isMyFriend,
      personalChatId: personalChatId ?? this.personalChatId,
      friendRequest: friendRequest ?? this.friendRequest,
      lastVisit: lastVisit ?? this.lastVisit,
      followLastVisit: followLastVisit ?? this.followLastVisit,
      allowComments: allowComments ?? this.allowComments,
      allowOnlyFriendsComments:
          allowOnlyFriendsComments ?? this.allowOnlyFriendsComments,
      onlyIBlocked: onlyIBlocked ?? this.onlyIBlocked,
      onlyTheyBlocked: onlyTheyBlocked ?? this.onlyTheyBlocked,
      bothBlocked: bothBlocked ?? this.bothBlocked,
      isAnyBlocked: isAnyBlocked ?? this.isAnyBlocked,
      totpSecret: totpSecret ?? this.totpSecret,
      totpEnabled: totpEnabled ?? this.totpEnabled,
      badges: badges ?? this.badges,
      fkMainBadge: fkMainBadge ?? this.fkMainBadge,
      mainBadge: mainBadge ?? this.mainBadge,
      fileAvatar: fileAvatar ?? this.fileAvatar,
      fileBanner: fileBanner ?? this.fileBanner,
      deleteAvatar: deleteAvatar ?? this.deleteAvatar,
      deleteBanner: deleteBanner ?? this.deleteBanner,
    );
  }

  // Геттеры для удобства
  bool get isOnline => status == UserStatus.online;

  bool get isOffline => status == UserStatus.offline;

  bool get isInvisible => status == UserStatus.invisible;

  bool get isBannedUser => isBanned == 1;

  bool get hasTotp => totpEnabled == 1;

  bool get isFriend => isMyFriend ?? false;

  bool get hasPersonalChat => personalChatId != null;

  String get urlAvatar => Domain.transformUrl(pathImage);

  String get getDisplayName => displayName ?? 'Пользователь';

  String get getDateRegistration => dateRegistration ?? 'N/A';

  int get getId => id ?? 0;

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    email,
    status,
    isMyFriend,
    personalChatId,
    mainBadge,
    badges,
    canSendMeRequest,
    allowComments,
    allowOnlyFriendsComments,
    followLastVisit,
  ];
}
