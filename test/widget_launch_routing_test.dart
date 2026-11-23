import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/navigation/widget_launch_target.dart';
import 'package:mawaqit/src/home_widget/widget_tokens.dart';

void main() {
  test('the checked-in widget URL routes to Times', () {
    final uri = Uri.parse(WidgetTokens.launchUrl);
    expect(WidgetLaunchTarget.isWidgetUri(uri), isTrue);
    expect(WidgetLaunchTarget.route(uri), AppRoutes.times);
  });

  test('the plugin marker appended to a warm tap is ignored', () {
    // `home_widget` adds ?homeWidget to the generated click URL. Cold and warm
    // taps must land on the same tab; they share [WidgetLaunchTarget] so they
    // cannot drift apart.
    final cold = Uri.parse(WidgetTokens.launchUrl);
    final warm = Uri.parse('${WidgetTokens.launchUrl}?homeWidget');
    expect(WidgetLaunchTarget.route(cold), WidgetLaunchTarget.route(warm));
    expect(WidgetLaunchTarget.route(warm), AppRoutes.times);
  });

  test('a widget tap on any shipped tab is honoured', () {
    for (final tab in AppRoutes.tabs) {
      expect(WidgetLaunchTarget.route(Uri.parse('mawaqit://$tab')), tab);
    }
  });

  test('unknown, empty and malformed taps are refused', () {
    expect(WidgetLaunchTarget.route(null), isNull);
    expect(WidgetLaunchTarget.route(Uri.parse('')), isNull);
    expect(
      WidgetLaunchTarget.route(Uri.parse('mawaqit:///not-a-route')),
      isNull,
    );
    expect(
      WidgetLaunchTarget.route(Uri.parse('https://evil.example/times')),
      isNull,
    );
  });
}
