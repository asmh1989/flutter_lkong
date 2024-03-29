import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

abstract class GroupedListModel {
  var scrollController = ScrollController(keepScrollOffset: false);

  SliverAppBar buildAppBar(BuildContext context);

  int get numberOfSections;

  bool get reverse => false;

  bool scrolling = false;

  void scrolledToBottom(BuildContext context);

  int countOfItemsInSection({@required int section});

  Widget headerForSection(BuildContext context, {@required int section});

  Widget cellForSectionAndIndex(BuildContext context,
      {@required int section, @required int index});

  Widget fillupForEmptyView(BuildContext context);

  void scrollToTop(context) {
    scrollController.jumpTo(0.1); // 0.1 to avoid pull-to-refresh is triggered
    scrollController.jumpTo(0.0); // then move to top
  }

  List<Widget> buildSlivers(BuildContext context) {
    ThemeData theme = Theme.of(context);
    List<Widget> slivers = new List<Widget>();

    SliverAppBar bar = buildAppBar(context);
    if (bar != null) {
      slivers.add(bar);
    }

    for (int i = 0; i < numberOfSections; i++) {
      slivers.add(builderSection(context, i));
    }

    final fillup = fillupForEmptyView(context);
    if (fillup != null) {
      slivers.add(SliverFillRemaining(
        child: Container(
          color: theme.backgroundColor,
          child: fillup,
        ),
      ));
    }
    return slivers;
  }

  Widget builderSection(BuildContext context, int section) {
    var header = headerForSection(context, section: section);
    var list = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) =>
            cellForSectionAndIndex(context, section: section, index: i),
        childCount: countOfItemsInSection(section: section),
      ),
    );

    return header == null
        ? list
        : SliverStickyHeader(
            header: header,
            sliver: list,
          );
  }

  Widget buildGroupedListView(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        reverse: reverse,
        controller: scrollController,
        slivers: buildSlivers(context),
      ),
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          scrolling = true;
        } else if (notification is ScrollEndNotification) {
          scrolling = false;
        } else if (notification is OverscrollNotification) {
          scrolledToBottom(context);
        }
        return false;
      },
    );
  }
}
