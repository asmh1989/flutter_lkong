import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lkongapp/actions/actions.dart';
import 'package:lkongapp/models/lkong_jsons/lkong_json.dart';
import 'package:lkongapp/models/models.dart';
import 'package:lkongapp/selectors/selectors.dart';
import 'package:lkongapp/ui/tools/item_handler.dart';
import 'package:redux/redux.dart';

import 'story_list.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FavoriteScreenState();
  }
}

class FavoriteScreenState extends StoryListState<FavoriteScreen> {
  FavoriteScreenState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildWidgetWithVMFactory(
        context,
        FavoriteScreenModel.fromStateAndStore(this),
      ),
    );
  }
}

class FavoriteScreenModel extends StoryListModel {
  final FetchList<Story> storyList;
  final bool loading;
  final String lastError;
  final int uid;
  final bool showDetailTime;

  FavoriteScreenModel({
    @required Store<AppState> store,
    @required this.loading,
    @required this.lastError,
    @required this.storyList,
    @required this.uid,
    @required this.showDetailTime,
  }) : super(store);

  @override
  SliverAppBar buildAppBar(BuildContext context) => SliverAppBar(
        title: GestureDetector(
          child: Text("收藏",
              style:
                  Theme.of(context).textTheme.title.apply(color: Colors.white)),
          onTap: () => scrollToTop(context),
        ),
        floating: false,
        pinned: true,
      );

  static final fromStateAndStore = (FavoriteScreenState state) =>
      (Store<AppState> store) => FavoriteScreenModel(
            store: store,
            loading: store.state.uiState.content.userData[selectUID(store)]
                ?.favorites?.loading,
            lastError: store.state.uiState.content.userData[selectUID(store)]
                ?.favorites?.lastError,
            storyList: store
                .state.uiState.content.userData[selectUID(store)]?.favorites,
            uid: selectUID(store),
            showDetailTime: selectSetting(store).showDetailTime,
          );

  @override
  APIRequest get fetchFromScratchRequest {
    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {});
    return GetMyFavoritesNewRequest(completer, uid, 0, 0);
  }

  @override
  APIRequest get loadMoreRequest {
    if (storyList == null || storyList.nexttime == 0) {
      return null;
    }

    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {});
    return GetMyFavoritesLoadMoreRequest(completer, uid, storyList.nexttime);
  }

  @override
  APIRequest get refreshRequest => fetchFromScratchRequest;

  // @override
  // APIRequest get refreshRequest {
  //   if (storyList == null || storyList.current == 0) {
  //     return null;
  //   }

  //   final Completer<String> completer = Completer<String>();
  //   completer.future.then((error) {});
  //   return GetMyFavoritesRefreshRequest(completer, uid, storyList.current);
  // }

  @override
  APIRequest get checkNewRequest => null;

  @override
  Function(BuildContext context, Story story) get handleStoryTap =>
      (context, story) => onStoryTap(context, story, favorite: true);

  @override
  Widget buildStoryListView(BuildContext context, StoryListState aState) {
    var state = aState as FavoriteScreenState;
    return super.buildStoryListView(context, state);
  }
}
