# Background tracking behavior

This document explains why the current build keeps tracking toll-road segments
when the UI is backgrounded, and why a persistent Android notification is still
required for long-running sessions.

## How tracking continues with the UI hidden

* The `MapPage` listens to Flutter's lifecycle callbacks. As soon as the page is
  no longer `resumed`, it flips a boolean that tells the location layer to swap
  into foreground-service mode and resubscribes to the GPS stream so the change
  takes effect. When the page comes back to the foreground, the same mechanism
  switches the stream back to a UI-only configuration.【F:lib/presentation/pages/map_page.dart†L129-L214】
* The `LocationService` passes that boolean into the Geolocator plugin. On
  Android it builds a fresh `AndroidSettings` object and, when instructed, adds a
  `ForegroundNotificationConfig`. This is the hook Geolocator exposes to keep
  the process alive via an Android foreground service.【F:lib/services/location_service.dart†L21-L63】

If the app is only briefly sent to the background (for example when the user
opens the notification shade or switches apps for a moment), Android often keeps
an activity alive long enough for the existing `StreamSubscription` to continue
receiving fixes. That is why tracking can appear to "keep working" even if no
notification is currently visible.

## Why the notification still matters

Android's power management will aggressively stop background location updates
from regular activities once it decides the app is no longer in the foreground.
Without the foreground-service notification Geolocator cannot promote the
process, so the OS is free to throttle or terminate it at any time to save
battery. In other words: the short-term tracking you observe today is not a
promise that the system will let the app run indefinitely.

Ensuring the persistent notification is shown is what guarantees Android treats
the tracking loop as a foreground service. Without it there is no safeguard
against the OS eventually suspending the app and clearing the segment progress.

## Android 13+ notification permission

Android 13 introduces a runtime `POST_NOTIFICATIONS` permission. The map screen
now requests this permission (and directs the user to the system settings if it
remains disabled) so Geolocator's foreground-service notification can actually
be displayed. Without the permission Android silently drops the notification,
which means the OS can still stop the app to save power.【F:lib/presentation/pages/map_page.dart†L129-L240】【F:lib/services/notification_permission_service.dart†L1-L57】
