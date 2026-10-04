// dart format off
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'dart:async';
import 'dart:io';
import 'package:home_widget/home_widget.dart';

class PrayerWidgetHomeWidget {
  const PrayerWidgetHomeWidget._();

  static const String _$paramPrefix = 'home_widget.PrayerWidget';

  static Future<void> saveData({
    String? locationShort,
    String? nextPrayerName,
    String? nextPrayerCountdown,
    String? nextPrayerTime,
    bool? fajrIsActive,
    bool? fajrIsPast,
    bool? dhuhrIsActive,
    bool? dhuhrIsPast,
    bool? asrIsActive,
    bool? asrIsPast,
    bool? maghribIsActive,
    bool? maghribIsPast,
    bool? ishaIsActive,
    bool? ishaIsPast,
  }) {
    return Future.wait([
      if (locationShort != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.locationShort', locationShort),
      if (nextPrayerName != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerName', nextPrayerName),
      if (nextPrayerCountdown != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerCountdown', nextPrayerCountdown),
      if (nextPrayerTime != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.nextPrayerTime', nextPrayerTime),
      if (fajrIsActive != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.fajrIsActive', fajrIsActive),
      if (fajrIsPast != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.fajrIsPast', fajrIsPast),
      if (dhuhrIsActive != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.dhuhrIsActive', dhuhrIsActive),
      if (dhuhrIsPast != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.dhuhrIsPast', dhuhrIsPast),
      if (asrIsActive != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.asrIsActive', asrIsActive),
      if (asrIsPast != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.asrIsPast', asrIsPast),
      if (maghribIsActive != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.maghribIsActive', maghribIsActive),
      if (maghribIsPast != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.maghribIsPast', maghribIsPast),
      if (ishaIsActive != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.ishaIsActive', ishaIsActive),
      if (ishaIsPast != null) HomeWidget.saveWidgetData<bool>('${_$paramPrefix}.ishaIsPast', ishaIsPast),
    ]);
  }

  static Future<void> deleteData({
    bool locationShort = false,
    bool nextPrayerName = false,
    bool nextPrayerCountdown = false,
    bool nextPrayerTime = false,
    bool fajrIsActive = false,
    bool fajrIsPast = false,
    bool dhuhrIsActive = false,
    bool dhuhrIsPast = false,
    bool asrIsActive = false,
    bool asrIsPast = false,
    bool maghribIsActive = false,
    bool maghribIsPast = false,
    bool ishaIsActive = false,
    bool ishaIsPast = false,
  }) {
    return Future.wait([
      if (locationShort) HomeWidget.saveWidgetData('${_$paramPrefix}.locationShort', null),
      if (nextPrayerName) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerName', null),
      if (nextPrayerCountdown) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerCountdown', null),
      if (nextPrayerTime) HomeWidget.saveWidgetData('${_$paramPrefix}.nextPrayerTime', null),
      if (fajrIsActive) HomeWidget.saveWidgetData('${_$paramPrefix}.fajrIsActive', null),
      if (fajrIsPast) HomeWidget.saveWidgetData('${_$paramPrefix}.fajrIsPast', null),
      if (dhuhrIsActive) HomeWidget.saveWidgetData('${_$paramPrefix}.dhuhrIsActive', null),
      if (dhuhrIsPast) HomeWidget.saveWidgetData('${_$paramPrefix}.dhuhrIsPast', null),
      if (asrIsActive) HomeWidget.saveWidgetData('${_$paramPrefix}.asrIsActive', null),
      if (asrIsPast) HomeWidget.saveWidgetData('${_$paramPrefix}.asrIsPast', null),
      if (maghribIsActive) HomeWidget.saveWidgetData('${_$paramPrefix}.maghribIsActive', null),
      if (maghribIsPast) HomeWidget.saveWidgetData('${_$paramPrefix}.maghribIsPast', null),
      if (ishaIsActive) HomeWidget.saveWidgetData('${_$paramPrefix}.ishaIsActive', null),
      if (ishaIsPast) HomeWidget.saveWidgetData('${_$paramPrefix}.ishaIsPast', null),
    ]);
  }

  static Future<({String? locationShort, String? nextPrayerName, String? nextPrayerCountdown, String? nextPrayerTime, bool? fajrIsActive, bool? fajrIsPast, bool? dhuhrIsActive, bool? dhuhrIsPast, bool? asrIsActive, bool? asrIsPast, bool? maghribIsActive, bool? maghribIsPast, bool? ishaIsActive, bool? ishaIsPast})> getData() async {
    return (
      locationShort: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.locationShort', defaultValue: '—'),
      nextPrayerName: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerName', defaultValue: 'ASR'),
      nextPrayerCountdown: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerCountdown', defaultValue: '01h 24m'),
      nextPrayerTime: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.nextPrayerTime', defaultValue: '3:45 PM'),
      fajrIsActive: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.fajrIsActive', defaultValue: false),
      fajrIsPast: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.fajrIsPast', defaultValue: false),
      dhuhrIsActive: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.dhuhrIsActive', defaultValue: false),
      dhuhrIsPast: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.dhuhrIsPast', defaultValue: false),
      asrIsActive: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.asrIsActive', defaultValue: false),
      asrIsPast: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.asrIsPast', defaultValue: false),
      maghribIsActive: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.maghribIsActive', defaultValue: false),
      maghribIsPast: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.maghribIsPast', defaultValue: false),
      ishaIsActive: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.ishaIsActive', defaultValue: false),
      ishaIsPast: await HomeWidget.getWidgetData<bool>('${_$paramPrefix}.ishaIsPast', defaultValue: false),
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

  /// The URL a tap on the widget opens the app with on Android, as the app
  /// will receive it.
  ///
  /// The configured `widgetUrl` carrying the `homeWidget` query
  /// parameter, parsed — so its scheme is lower-cased, exactly like
  /// the URL handed to the app.
  static final Uri androidWidgetUrl = Uri.parse('mawaqit:///times?homeWidget');

  /// The URL the app was launched with by a tap on the widget, or null
  /// when it was started any other way.
  ///
  /// Only the URL this widget opens on the platform the app is running
  /// on is reported; a tap on any other widget is not.
  /// Nothing is ever reported on iOS, where the widget opens no URL
  /// of its own.
  static Future<Uri?> initiallyLaunchedFromWidget() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri == null || !_$matchesWidgetUrl(uri)) {
      return null;
    }
    return uri;
  }

  /// The URL of every tap on the widget while the app is running.
  ///
  /// A tap that started the app in the first place is not replayed here
  /// — read [initiallyLaunchedFromWidget] for that one, or listen to
  /// [launchedFromWidget] for both.
  ///
  /// Only the URL this widget opens on the platform the app is running
  /// on is reported; a tap on any other widget is not.
  /// Nothing is ever reported on iOS, where the widget opens no URL
  /// of its own.
  static Stream<Uri> get widgetClicked =>
      HomeWidget.widgetClicked
          .where((uri) => uri != null && _$matchesWidgetUrl(uri))
          .cast<Uri>();

  /// Every tap on the widget, launch included.
  ///
  /// Yields the launch URL first when the app was started by a tap on
  /// the widget, then every tap that follows while it runs. Taps landing
  /// while the launch URL is still being read are kept, not dropped.
  ///
  /// Only the URL this widget opens on the platform the app is running
  /// on is reported; a tap on any other widget is not.
  /// Nothing is ever reported on iOS, where the widget opens no URL
  /// of its own.
  static Stream<Uri> launchedFromWidget() async* {
    final clicks = StreamController<Uri>();
    final subscription = HomeWidget.widgetClicked.listen(
      (uri) {
        if (uri != null && _$matchesWidgetUrl(uri)) clicks.add(uri);
      },
      onDone: clicks.close,
    );
    try {
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initial != null && _$matchesWidgetUrl(initial)) yield initial;
      yield* clicks.stream;
    } finally {
      await subscription.cancel();
      await clicks.close();
    }
  }

  /// Whether [uri] is the URL this platform's widget opens.
  ///
  /// Schemes are compared case-insensitively: the URL reaches the app parsed,
  /// which lower-cases the scheme it was written with.
  static bool _$matchesWidgetUrl(Uri uri) {
    final url = _$platformWidgetUrl;
    if (url == null) return false;
    return _$lowerCaseScheme(uri) == _$lowerCaseScheme(url);
  }

  /// The URL the widget opens on the platform the app is running on, or
  /// null where it opens none.
  static Uri? get _$platformWidgetUrl {
    if (Platform.isAndroid) return androidWidgetUrl;
    return null;
  }

  static String _$lowerCaseScheme(Uri uri) {
    final text = uri.toString();
    return uri.scheme.toLowerCase() + text.substring(uri.scheme.length);
  }
}
