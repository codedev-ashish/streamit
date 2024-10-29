import 'package:flutter/material.dart';
import 'package:streamit_flutter/fragments/genre_fragment.dart';
import 'package:streamit_flutter/fragments/home_fragment.dart';
import 'package:streamit_flutter/fragments/more_fragment.dart';
import 'package:streamit_flutter/fragments/watchlist_fragment.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/utils/resources/colors.dart';
import 'package:streamit_flutter/utils/resources/images.dart';

class DashboardWidgetsModel {
  String? fragment;
  Widget? widget;
  Widget? icon;
  Widget? selectedIcon;

  DashboardWidgetsModel({this.fragment, this.widget, this.icon, this.selectedIcon});
}

List<DashboardWidgetsModel> getFragments() {
  List<DashboardWidgetsModel> list = [];

  list.add(
    DashboardWidgetsModel(
      fragment: language!.home,
      icon: Icon(Icons.home_outlined, size: 20, color: Colors.white),
      selectedIcon: Icon(Icons.home_filled, color: colorPrimary, size: 18),
      widget: HomeFragment(),
    ),
  );
  list.add(
    DashboardWidgetsModel(
      fragment: language!.watchList,
      icon: Icon(Icons.bookmark_border, size: 18, color: Colors.white),
      selectedIcon: Icon(Icons.bookmark, color: colorPrimary, size: 18),
      widget: WatchlistFragment(),
    ),
  );
  list.add(
    DashboardWidgetsModel(
      fragment: language!.genre,
      icon: Image.asset(ic_genre, fit: BoxFit.fitHeight, color: Colors.white, height: 18, width: 18),
      selectedIcon: Image.asset(ic_genre_filled, color: colorPrimary, height: 14, width: 14),
      widget: GenreFragment(),
    ),
  );
  list.add(
    DashboardWidgetsModel(
      fragment: language!.profile,
      icon: Icon(Icons.person_outlined, size: 20, color: Colors.white),
      selectedIcon: Icon(Icons.person, color: colorPrimary, size: 20),
      widget: MoreFragment(),
    ),
  );

  return list;
}
