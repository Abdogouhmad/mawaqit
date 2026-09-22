# Instructions — Fixes (Mawaqit)

- First don't run or build the app

so i got some issue and enhancement to be done
- when the app is open it always load before detecting GPS instead i wanna to keep the last GPS and load at back scean and push the new location
- fix the notification test where it says:
```text
Test notification failed: PlatformException (invalid_sound, The resource adhan_adham_al_sharqawe could not be found. Please make sure it has been added as a raw resource to your Android head project., null, null)

#0 StandardMethodCodec.decodeEnvelope

(package:fłutter/src/services/message_codecs.dart:653) #1 MethodChannel._invokeMethod (package:flutter/src/ services/platform_channel.dart:366)

< asynchronous suspension >

#2 AndroidFlutterLocalNotificationsPlugin.zonedSchedule

(package:flutter_local_notifications/src/

platform_flutter_local_notifications.dart:260)

<asynchronous suspension >

#3 FlutterLocalNotificationsPlugin.zonedSchedule

(package:flutter_local_notifications/src/

flutter_local_notifications_plugin.dart:434) <asynchronous suspension >

#4 NotificationService._postAt (package:mawaqit/data/

services/notification_service.dart:309)

<asynchronous suspension

#5 NotificationService.scheduleTestNotification
(package:mawaqit/data/services/notification_service.dart:192) <asynchronous suspension >
#6 _SettingsBody._sendTestNotification (package:mawaqit/ features/settings/settings_screen.dart:399) <asynchronous suspension >
```

- add pre-prayer tone like adhan tone so i can distinguish between pre prayer and prayer call tone
- make sure that adhan tone is forced in the lock screen as alarm with adhan tone
- remove anything related to home_widget and the changes you did within kotlin and please start this from scratch again  please see for more knowladge and inspiration`./home_widget_instruc.md`
