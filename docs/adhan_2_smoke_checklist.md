# Adhan 2.0 on-device smoke checklist

The automated suite covers the Dart-side preferences, scheduling policy and
layouts. These steps cover the parts that only exist on a real Android phone:
the alarm engine, the lockscreen takeover and the system permission screens.

Run them on a physical device after every 0.21 build. Use a prayer time a few
minutes away so the whole flow can be observed without waiting a day.

## 1. Lockscreen takeover

1. Lock the phone with the screen off and an upcoming prayer set to **Full
   adhan**.
2. Wait for the call. It must wake the screen, start audio at alarm volume and
   show the full-screen Mawaqit presenter without unlocking first.
3. Press a volume key. The call must stop and the presenter must close without
   leaving the foreground service or Do Not Disturb lift engaged.
4. Unlock the phone, open another app and arm the **Test adhan** action again.
   With *Display over other apps* granted, the presenter must take the screen;
   without it, a heads-up card is expected instead (not a failure).
5. Repeat with the phone in silent mode. With *Do Not Disturb access* granted,
   the adhan must still be audible; afterwards the phone's own silent mode must
   be restored.

## 2. Silence and merge behaviour

1. In **Settings → Notifications → Adhan → Tone**, tap the speaker on a bundled
   tone, then on a device tone (Android). Preview must start and stop in place,
   and the loudness/merge explanations must remain visible.
2. Select **Silent**. The quiet card must still appear, but there must be no
   audio, no foreground playback service and no lockscreen takeover.
3. Set one prayer to **Silent card** and leave the next prayer **Full adhan**.
   Only the full prayer may ring; the weekly summary must show the difference.
4. Arm a pre-prayer reminder immediately followed by an adhan (a 1-minute lead
   works). The reminder must stop when the adhan starts; the two must never play
   over each other.
5. Switch the global adhan kill switch off. No prayer may ring even when its
   per-prayer control says **Full adhan**.

## 3. Reschedule and reliability

1. Change a prayer's offset by −5 and then +5 minutes with the app open. The
   next occurrence must ring at the new time exactly once — never at both the
   old and the new time.
2. Disable a prayer that is already armed for later today. Its adhan and
   reminder must both disappear, and the weekly summary must read *off all
   week*. Re-enable it and confirm both return.
3. Open **Settings → Permissions** and turn off one access in Android settings.
   Return to the app: the reliability dashboard must show **Fix** for that row
   and an honest "checks need attention" summary.
4. Tap **Fix**, grant the access and return. The pill must become **Allowed**,
   the app must re-arm immediately and a confirmation snackbar must appear.
5. Force-stop the app, wait for a reboot (or trigger `TIME_SET` in a test build)
   and confirm the daily reschedule task restores the same per-prayer plan.

If any step fails, record the Android version, OEM, the exact per-prayer
settings and whether the device was locked; the native alarm engine is treated
as unchanged unless a smoke failure proves otherwise.
