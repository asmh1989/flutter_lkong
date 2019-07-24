import 'package:lkongapp/actions/actions.dart';
import 'package:lkongapp/models/models.dart';
import 'package:redux/redux.dart';

import 'forum_reducer.dart';
import 'misc_reducer.dart';
import 'profile_reducer.dart';
import 'search_reducer.dart';
import 'story_reducer.dart';
import 'userdata_reducer.dart';

final contentReducer = combineReducers<ContentCache>([
  TypedReducer<ContentCache, APIRequest>(_contentRequested),
  TypedReducer<ContentCache, APIFailure>(_contentRequestFailed),
  TypedReducer<ContentCache, APISuccess>(_contentRequestSucceed),
  _contentReducer,
]);

ContentCache _contentRequested(ContentCache content, APIRequest action) {
  return content.rebuild((b) => b
    ..lastError = null
    ..loading = true);
}

ContentCache _contentRequestFailed(ContentCache content, APIFailure action) {
  return content.rebuild((b) => b
    ..lastError = action.error
    ..loading = false);
}

ContentCache _contentRequestSucceed(ContentCache content, APISuccess action) {
  return content.rebuild((b) => b
    ..lastError = null
    ..loading = false);
}

ContentCache _contentReducer(ContentCache content, action) {
  return content.rebuild((b) => b
    ..homeList.replace(homeListReducer(content.homeList, action))
    ..storyRepo.replace(storyContentsReducer(content.storyRepo, action))
    ..forumInfo.replace(forumContentsReducer(content.forumInfo, action))
    ..userData.replace(userDataReducer(content.userData, action))
    ..searchResult.replace(searchResultReducer(content.searchResult, action))
    ..profiles.replace(profileReducer(content.profiles, action))
    ..hotDigest.replace(hotDigestReducer(content.hotDigest, action))
    ..blacklist.replace(blacklistReducer(content.blacklist, action))
    ..forumRepo.replace(forumRepoReducer(content.forumRepo, action)));
}
