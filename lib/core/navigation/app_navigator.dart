import 'package:flutter/material.dart';

/// Global navigator key so out-of-tree code (the alarm/notification service)
/// can raise full-screen routes — like the adhan overlay — over the current
/// app shell without threading a BuildContext through the scheduler.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();