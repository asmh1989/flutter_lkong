// Copyright 2018 The Flutter Architecture Sample Authors. All rights reserved.
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

library serializers;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:lkongapp/models/lkong_jsons/lkong_json.dart';
import 'package:lkongapp/models/models.dart';

part 'serializers.g.dart';

@SerializersFor(const [
  AppState,
  PersistentState,
  AppConfig,
  AppSetting,
  AuthState,
  UIState,
  ThemeSetting,
  AccountSettings,
  AccountSetting,
  AppTheme,
  Story,
  StoryListResult,
  ForumListResult,
  Forum,
  StoryInfoResult,
  ForumInfoResult,
  StoryContentResult,
  Comment,
  Ratelog,
  UpvoteResult,
  FollowList,
  PunchCardResult,
  UserData,
  SearchUserResult,
  SearchForumResult,
  HotDigestResult,
  NoticeResult,
  Notice,
  RatelogResult,
  PrivateMessageResult,
  PrivateMessage,
  PMSession,
  CheckNoticeResult,
  NewNotice,
])
final Serializers serializers =
    (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
