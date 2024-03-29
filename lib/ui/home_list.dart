import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lkongapp/actions/actions.dart';
import 'package:lkongapp/models/lkong_jsons/lkong_json.dart';
import 'package:lkongapp/models/models.dart';
import 'package:lkongapp/selectors/selectors.dart';
import 'package:lkongapp/ui/items/item_wrapper.dart';
import 'package:lkongapp/ui/tools/drawer_button.dart';
import 'package:lkongapp/utils/utils.dart';
import 'package:redux/redux.dart';

import 'story_list.dart';

class HomeList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeListState();
  }
}

class HomeListState extends StoryListState<HomeList> {
  @override
  Widget build(BuildContext context) {
    return buildWidgetWithVMFactory(context, HomeListModel.fromStore);
  }
}

class HomeListModel extends StoryListModel {
  final bool isAuthed;
  final bool threadOnlyHome;
  final FetchList<Story> storyList;
  final bool loading;
  final String lastError;
  final bool showDetailTime;

  HomeListModel({
    @required Store<AppState> store,
    @required this.loading,
    @required this.isAuthed,
    @required this.lastError,
    @required this.storyList,
    @required this.threadOnlyHome,
    @required this.showDetailTime,
  }) : super(store);

  static HomeListModel fromStore(Store<AppState> store) {
    return HomeListModel(
      store: store,
      isAuthed: store.state.persistState.authState.isAuthed,
      loading: store.state.uiState.content.homeList.loading,
      lastError: store.state.uiState.content.homeList.lastError,
      storyList: store.state.uiState.content.homeList,
      threadOnlyHome: store.state.persistState.appConfig.accountSettings
              .currentSetting?.threadOnlyHome ??
          false,
      showDetailTime: selectSetting(store).showDetailTime,
    );
  }

  @override
  Widget Function(BuildContext, Widget) get wrapCell => wrapItemAsCard;

  @override
  SliverAppBar buildAppBar(BuildContext context) => SliverAppBar(
        leading: DrawerButton(),
        title: GestureDetector(
          child: Text("首页",
              style:
                  Theme.of(context).textTheme.title.apply(color: Colors.white)),
          onTap: () => scrollToTop(context),
        ),
        floating: false,
        pinned: true,
      );

  @override
  APIRequest get fetchFromScratchRequest {
    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {
      // showToast(context, success ? 'Loading Succeed' : 'Loading Failed');
    });
    return HomeListNewRequest(completer, threadOnlyHome, 0, 0);
  }

  @override
  APIRequest get loadMoreRequest {
    if (storyList.nexttime == 0) {
      return null;
    }
    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {
      // showToast(context, success ? 'Loading Succeed' : 'Loading Failed');
    });
    return HomeListLoadMoreRequest(
        completer, threadOnlyHome, storyList.nexttime);
  }

  @override
  APIRequest get refreshRequest {
    if (storyList.current == 0) {
      return fetchFromScratchRequest;
    }
    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {
      // showToast(context, success ? 'Refresh Succeed' : 'Refresh Failed');
    });
    return HomeListRefreshRequest(completer, threadOnlyHome, storyList.current);
  }

  @override
  APIRequest get checkNewRequest =>
      HomeListCheckNewRequest(null, storyList.current);

  @override
  Future<Null> handleFetchFromScratch(BuildContext context) async {
    var request = fetchFromScratchRequest;
    if (request != null) {
      Duration delay;
      if (isAuthed) {
        delay = Duration();
      } else {
        // Delay for 2 seconds waiting for login.
        delay = Duration(seconds: 2);
      }
      Future.delayed(delay, () => dispatchAction(context)(request));
    }
  }
}
