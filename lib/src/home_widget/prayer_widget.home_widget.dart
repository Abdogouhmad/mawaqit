// dart format off
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:home_widget/home_widget.dart';

class PrayerWidgetHomeWidget {
  const PrayerWidgetHomeWidget._();

  static const String _$paramPrefix = 'home_widget.PrayerWidget';

  static Future<void> saveData({
    String? locationShort,
    String? nextPrayerName,
    String? nextPrayerTime,
    String? nextPrayerCountdown,
  }) {
    return Future.wait([
      if (locationShort != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.locationShort', locationShort),
      if (nextPrayerName != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerName', nextPrayerName),
      if (nextPrayerTime != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerTime', nextPrayerTime),
      if (nextPrayerCountdown != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerCountdown', nextPrayerCountdown),
    ]);
  }

  static Future<void> deleteData({
    bool locationShort = false,
    bool nextPrayerName = false,
    bool nextPrayerTime = false,
    bool nextPrayerCountdown = false,
  }) {
    return Future.wait([
      if (locationShort) HomeWidget.saveWidgetData('${_$paramPrefix}.locationShort', null),
      if (nextPrayerName) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerName', null),
      if (nextPrayerTime) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerTime', null),
      if (nextPrayerCountdown) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerCountdown', null),
    ]);
  }

  static Future<({String? locationShort, String? nextPrayerName, String? nextPrayerTime, String? nextPrayerCountdown})> getData() async {
    return (
      locationShort: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.locationShort', defaultValue: '—'),
      nextPrayerName: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerName', defaultValue: '—'),
      nextPrayerTime: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerTime', defaultValue: '--:--'),
      nextPrayerCountdown: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerCountdown', defaultValue: 'NEXT IN —'),
    );
  }


  static Future<bool?> updateWidget() {
    return HomeWidget.updateWidget(
      androidName: 'PrayerWidgetHomeWidgetReceiver',
    );
  }

  /// Asks the launcher to re-render this widget's gallery preview.
  ///
  /// Android 15 and newer only; returns false elsewhere and when the system
  /// rate limit (about two updates per hour and widget) was hit. The plugin
  /// registers the preview automatically when the app starts, so this is only
  /// needed after data changes that should show in the gallery right away.
  static Future<bool> updatePreview() async {
    return await HomeWidget.updateWidgetPreview(
      androidName: 'PrayerWidgetHomeWidgetReceiver',
    ) ?? false;
  }

  /// Whether the launcher lets the app ask to add this widget to the home
  /// screen: Android 8 or newer with a launcher that supports pinning. Always
  /// false on iOS.
  static Future<bool> isRequestPinWidgetSupported() async {
    return await HomeWidget.isRequestPinWidgetSupported() ?? false;
  }

  /// Asks the launcher to add this widget to the home screen.
  ///
  /// Shows the system pin dialog where [isRequestPinWidgetSupported] is true
  /// and does nothing anywhere else.
  static Future<void> requestPinWidget() {
    return HomeWidget.requestPinWidget(
      androidName: 'PrayerWidgetHomeWidgetReceiver',
    );
  }

  /// Every instance of this widget currently placed on a home screen.
  ///
  /// Android reports one entry per placed instance, iOS one entry per family
  /// the widget is placed in.
  static Future<List<HomeWidgetInfo>> getInstalledWidgets() async {
    final widgets = await HomeWidget.getInstalledWidgets();
    return widgets.where(_$isThisWidget).toList();
  }

  /// Whether at least one instance of this widget is on a home screen.
  static Future<bool> isInstalled() async {
    return (await getInstalledWidgets()).isNotEmpty;
  }

  /// Whether [info] describes this widget.
  ///
  /// Android reports the provider's short class name — `.Receiver` when it
  /// lives in the package of the application id, and the qualified name
  /// otherwise — which is why the suffix is matched.
  static bool _$isThisWidget(HomeWidgetInfo info) {
    final androidClassName = info.androidClassName;
    if (androidClassName != null) {
      return androidClassName.endsWith('.PrayerWidgetHomeWidgetReceiver');
    }
    return false;
  }
}
