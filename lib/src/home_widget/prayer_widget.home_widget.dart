// dart format off
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:home_widget/home_widget.dart';

class PrayerWidgetHomeWidget {
  const PrayerWidgetHomeWidget._();

  static const String _$paramPrefix = 'home_widget.PrayerWidget';

  static Future<void> saveData({
    String? nextPrayerName,
    String? nextPrayerTime,
    String? nextPrayerCountdown,
    String? fajrName,
    String? fajrTime,
    String? dhuhrName,
    String? dhuhrTime,
    String? asrName,
    String? asrTime,
    String? maghribName,
    String? maghribTime,
    String? ishaName,
    String? ishaTime,
  }) {
    return Future.wait([
      if (nextPrayerName != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerName', nextPrayerName),
      if (nextPrayerTime != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerTime', nextPrayerTime),
      if (nextPrayerCountdown != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerCountdown', nextPrayerCountdown),
      if (fajrName != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.fajrName', fajrName),
      if (fajrTime != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.fajrTime', fajrTime),
      if (dhuhrName != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.dhuhrName', dhuhrName),
      if (dhuhrTime != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.dhuhrTime', dhuhrTime),
      if (asrName != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.asrName', asrName),
      if (asrTime != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.asrTime', asrTime),
      if (maghribName != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.maghribName', maghribName),
      if (maghribTime != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.maghribTime', maghribTime),
      if (ishaName != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.ishaName', ishaName),
      if (ishaTime != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.ishaTime', ishaTime),
    ]);
  }

  static Future<void> deleteData({
    bool nextPrayerName = false,
    bool nextPrayerTime = false,
    bool nextPrayerCountdown = false,
    bool fajrName = false,
    bool fajrTime = false,
    bool dhuhrName = false,
    bool dhuhrTime = false,
    bool asrName = false,
    bool asrTime = false,
    bool maghribName = false,
    bool maghribTime = false,
    bool ishaName = false,
    bool ishaTime = false,
  }) {
    return Future.wait([
      if (nextPrayerName) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerName', null),
      if (nextPrayerTime) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerTime', null),
      if (nextPrayerCountdown) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerCountdown', null),
      if (fajrName) HomeWidget.saveWidgetData('${_$paramPrefix}.fajrName', null),
      if (fajrTime) HomeWidget.saveWidgetData('${_$paramPrefix}.fajrTime', null),
      if (dhuhrName) HomeWidget.saveWidgetData('${_$paramPrefix}.dhuhrName', null),
      if (dhuhrTime) HomeWidget.saveWidgetData('${_$paramPrefix}.dhuhrTime', null),
      if (asrName) HomeWidget.saveWidgetData('${_$paramPrefix}.asrName', null),
      if (asrTime) HomeWidget.saveWidgetData('${_$paramPrefix}.asrTime', null),
      if (maghribName) HomeWidget.saveWidgetData('${_$paramPrefix}.maghribName', null),
      if (maghribTime) HomeWidget.saveWidgetData('${_$paramPrefix}.maghribTime', null),
      if (ishaName) HomeWidget.saveWidgetData('${_$paramPrefix}.ishaName', null),
      if (ishaTime) HomeWidget.saveWidgetData('${_$paramPrefix}.ishaTime', null),
    ]);
  }

  static Future<({String? nextPrayerName, String? nextPrayerTime, String? nextPrayerCountdown, String? fajrName, String? fajrTime, String? dhuhrName, String? dhuhrTime, String? asrName, String? asrTime, String? maghribName, String? maghribTime, String? ishaName, String? ishaTime})> getData() async {
    return (
      nextPrayerName: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerName', defaultValue: '—'),
      nextPrayerTime: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerTime', defaultValue: '--:--'),
      nextPrayerCountdown: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerCountdown', defaultValue: ''),
      fajrName: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.fajrName'),
      fajrTime: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.fajrTime'),
      dhuhrName: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.dhuhrName'),
      dhuhrTime: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.dhuhrTime'),
      asrName: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.asrName'),
      asrTime: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.asrTime'),
      maghribName: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.maghribName'),
      maghribTime: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.maghribTime'),
      ishaName: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.ishaName'),
      ishaTime: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.ishaTime'),
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
