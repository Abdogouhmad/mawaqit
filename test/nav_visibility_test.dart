import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/core/ui/widgets/floating_nav_bar.dart';

/// A minimal stand-in for a tab body: a `ListView` tall enough to scroll, so the
/// visibility plumbing can be exercised without booting the real screens (which
/// need location, settings, and the alarm pipeline).
Widget _scrollableBody({ScrollController? controller}) => ListView(
  controller: controller,
  children: const [SizedBox(height: 2000, child: Text('body'))],
);

/// Hosts a [NavVisibilityScope] *above* a scrollable and records every reported
/// visibility, exactly as `AppShell` does for a real tab.
///
/// The scope has to be an ancestor of the scrollable: [NavVisibilityScope.wrap]
/// looks itself up with `dependOnInheritedWidgetOfExactType`, so a context taken
/// above the scope finds nothing and silently does nothing.
Widget _harness(List<bool> reported) => MaterialApp(
  home: Scaffold(
    body: NavVisibilityScope(
      onChanged: reported.add,
      child: Builder(
        builder: (belowScope) =>
            NavVisibilityScope.wrap(belowScope, child: _scrollableBody()),
      ),
    ),
  ),
);

void main() {
  group('NavVisibilityScope.wrap', () {
    testWidgets('hides on scroll down and reveals on scroll up', (
      tester,
    ) async {
      final reported = <bool>[];
      await tester.pumpWidget(_harness(reported));

      expect(reported, isEmpty, reason: 'nothing reported before any scroll');

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      expect(reported.last, isFalse, reason: 'scrolled down, bar should hide');

      await tester.drag(find.byType(ListView), const Offset(0, 120));
      await tester.pump();
      expect(
        reported.last,
        isTrue,
        reason: 'any upward scroll should reveal immediately, not at the top',
      );
    });

    testWidgets('stays visible near the top of the list', (tester) async {
      final reported = <bool>[];
      await tester.pumpWidget(_harness(reported));

      await tester.drag(find.byType(ListView), const Offset(0, -8));
      await tester.pump();
      expect(
        reported.where((v) => !v),
        isEmpty,
        reason: 'a few pixels of overscroll must not dismiss the bar',
      );
    });

    testWidgets('does nothing when there is no enclosing scope', (
      tester,
    ) async {
      // A screen can only call `wrap()` unconditionally if the no-scope path is
      // a pass-through. `ListView` installs its own `NotificationListener` (it
      // owns the physics notifications), so presence alone proves nothing — what
      // matters is that scrolling neither throws nor attempts a report.
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _scrollableBody())),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('NavVisibilityScope.attachScroll', () {
    testWidgets('detaching stops the reporting', (tester) async {
      final reported = <bool>[];
      final controller = ScrollController();
      late VoidCallback detach;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavVisibilityScope(
              onChanged: reported.add,
              child: Builder(
                builder: (belowScope) {
                  detach = NavVisibilityScope.attachScroll(
                    belowScope,
                    controller,
                  );
                  return _scrollableBody(controller: controller);
                },
              ),
            ),
          ),
        ),
      );

      controller.jumpTo(400);
      await tester.pump();
      expect(
        reported.last,
        isFalse,
        reason: 'attached: down past the threshold',
      );

      detach();
      reported.clear();

      controller.jumpTo(0);
      await tester.pump();
      expect(
        reported,
        isEmpty,
        reason: 'a removed listener must not keep reporting into the shell',
      );

      controller.dispose();
    });

    testWidgets('is a no-op outside a scope', (tester) async {
      final controller = ScrollController();
      late VoidCallback detach;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                detach = NavVisibilityScope.attachScroll(context, controller);
                return _scrollableBody(controller: controller);
              },
            ),
          ),
        ),
      );

      expect(detach, isNotNull);

      controller.jumpTo(400);
      await tester.pump();

      detach();
      controller.dispose();
      expect(tester.takeException(), isNull);
    });
  });

  group('FloatingNavBar', () {
    final destinations = <NavDestination>[
      for (final (icon, label) in const [
        (Icons.home_outlined, 'Home'),
        (Icons.calendar_month_outlined, 'Times'),
        (Icons.settings_outlined, 'Settings'),
      ])
        NavDestination(icon: icon, selectedIcon: icon, label: label),
    ];

    Widget bar({
      int selectedIndex = 0,
      bool visible = true,
      ValueChanged<int>? onSelected,
    }) => MaterialApp(
      theme: AppTheme.light(),
      // Placed as `bottomNavigationBar`, which is where `AppShell` puts it. In
      // `body` the bar would be handed the full window height and the pill's
      // infinite radius would be laid out against the wrong constraints.
      home: Scaffold(
        body: const SizedBox.shrink(),
        bottomNavigationBar: FloatingNavBar(
          destinations: destinations,
          selectedIndex: selectedIndex,
          visible: visible,
          onDestinationSelected: onSelected ?? (_) {},
        ),
      ),
    );

    testWidgets('renders one labelled destination per tab', (tester) async {
      await tester.pumpWidget(bar());
      await tester.pumpAndSettle();

      for (final label in ['Home', 'Times', 'Settings']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('reports the tapped index', (tester) async {
      final selected = <int>[];
      await tester.pumpWidget(bar(onSelected: selected.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selected, [3]);
    });

    testWidgets('ignores taps once hidden', (tester) async {
      final selected = <int>[];
      await tester.pumpWidget(bar(visible: false, onSelected: selected.add));
      await tester.pumpAndSettle();

      // The bar slides out rather than being removed, so the widgets are still
      // in the tree — `IgnorePointer` is what has to stop the tap.
      final ignore = tester.widget<IgnorePointer>(
        find
            .descendant(
              of: find.byType(FloatingNavBar),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(ignore.ignoring, isTrue);

      await tester.tap(find.text('Settings'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, isEmpty);
    });

    testWidgets('exposes every destination to assistive tech', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(bar());
      await tester.pumpAndSettle();

      // A bar that only works by pixel hit-testing is unusable with a screen
      // reader, so every destination must carry its own label.
      for (final label in ['Home', 'Times', 'Settings']) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }

      handle.dispose();
    });
  });
}
