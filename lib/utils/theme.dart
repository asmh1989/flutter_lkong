import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lkongapp/models/models.dart';
import 'package:lkongapp/selectors/selectors.dart';
import 'package:quiver/core.dart';
import 'package:redux/redux.dart';

class LKongAppTheme {
  final bool isNightMode;
  final AppTheme appTheme;
  final double fontSize;

  Color get mainColor => htmlColor(appTheme.colors['main']);

  Color get barIconColor => isNightMode ? barTextColor : mainColor;

  Color get backgroundColor =>
      htmlColor(appTheme.colors['background'] ?? appTheme.colors['paper']);

  Color get pageColor => htmlColor(appTheme.colors['paper']);

  Color get barTextColor => htmlColor(appTheme.colors['barText']);

  Color get headerBG => htmlColor(appTheme.colors['headerBG']);

  Color get quoteBG => htmlColor(appTheme.colors['quoteBG']);

  Color get textColor => htmlColor(appTheme.colors['text']);

  Color get lightTextColor => htmlColor(appTheme.colors['lightText']);

  Color get mediumTextColor => htmlColor(appTheme.colors['mediumText']);

  Color get darkTextColor => htmlColor(appTheme.colors['darkText']);

  Color get linkColor => htmlColor(appTheme.colors['link']);

  Color get linkTapColor => htmlColor(appTheme.colors['linkTap']);

  @override
  bool operator ==(other) {
    return other is LKongAppTheme &&
        appTheme == other.appTheme &&
        isNightMode == other.isNightMode &&
        fontSize == other.fontSize;
  }

  @override
  int get hashCode {
    return hash3(appTheme, isNightMode, fontSize);
  }

  LKongAppTheme({
    @required this.appTheme,
    @required this.isNightMode,
    @required this.fontSize,
  });

  static LKongAppTheme fromStore(Store<AppState> store) {
    var setting = selectSetting(store);
    bool night = setting.nightMode;

    int themeIndex =
        night ? setting.themeSetting.night : setting.themeSetting.day;
    AppTheme theme = setting.themeSetting.theme[themeIndex];

    double fontSize = setting.fontSize;

    return LKongAppTheme(
        appTheme: theme, isNightMode: night, fontSize: fontSize);
  }

  ThemeData _themeData;

  ThemeData get themeData {
    return _themeData ??=
        (isNightMode ? ThemeData.dark() : ThemeData.light()).copyWith(
      primaryColor: mainColor,
      backgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      scaffoldBackgroundColor: pageColor,
      cardColor: pageColor,
      accentColor: mainColor,
      bottomAppBarColor: backgroundColor,
    );
  }

  double _sizeFactor;

  double get sizeFactor => _sizeFactor ??= (fontSize - 1) * 0.1 + 0.5;
  double _textSize;

  double get textSize => _textSize ??= 20 * sizeFactor;
  double _titleSize;

  double get titleSize => _titleSize ??= 20 * sizeFactor;
  double _subtitleSize;

  double get subtitleSize => _subtitleSize ??= 14 * sizeFactor;
  double _headerSize;

  double get headerSize => _headerSize ??= 22 * sizeFactor;
  double _subheadSize;

  double get subheadSize => _subheadSize ??= 16 * sizeFactor;
  double _captionSize;

  double get captionSize => _captionSize ??= 12 * sizeFactor;

  TextStyle _textStyle;

  TextStyle get textStyle => _textStyle ??= themeData.textTheme.title.copyWith(
        fontSize: textSize,
        color: darkTextColor,
        fontWeight: FontWeight.normal,
      );

  TextStyle _titleStyle;

  TextStyle get titleStyle =>
      _titleStyle ??= themeData.textTheme.title.copyWith(
        fontSize: titleSize,
        color: darkTextColor,
        fontWeight: FontWeight.normal,
      );

  TextStyle _headerStyle;

  TextStyle get headerStyle =>
      _headerStyle ??= themeData.textTheme.title.copyWith(
        fontSize: headerSize,
        color: darkTextColor,
        fontWeight: FontWeight.normal,
      );

  TextStyle _subheadStyle;

  TextStyle get subheadStyle =>
      _subheadStyle ??= themeData.textTheme.title.copyWith(
        fontSize: subheadSize,
        color: darkTextColor,
        fontWeight: FontWeight.normal,
      );

  TextStyle _subtitleStyle;

  TextStyle get subtitleStyle =>
      _subtitleStyle ??= themeData.textTheme.title.copyWith(
        fontSize: subtitleSize,
        color: mediumTextColor,
        fontWeight: FontWeight.normal,
      );

  TextStyle _captionStyle;

  TextStyle get captionStyle =>
      _captionStyle ??= themeData.textTheme.title.copyWith(
        fontSize: captionSize,
        color: mediumTextColor,
        fontWeight: FontWeight.normal,
      );

  static String randomColor() =>
      '#' +
      (Random.secure().nextInt(0xFFFFFFFF).toRadixString(16) + "000000")
          .substring(2, 6);

  String applyTheme(String css) {
    RegExp pattern = RegExp(r"#-([a-zA-Z0-9_]+)-", caseSensitive: false);
    String newCSS = css.replaceAllMapped(pattern, (Match match) {
      String name = match[1];
      String color = appTheme.colors[name];
      if (color != null) {
        return color;
      } else {
        return randomColor();
      }
    });
    return newCSS;
  }
}
