import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_bootstrap.dart';
import 'notification_gateway.dart';
import 'notification_sound.dart';
import 'permission_state.dart';
import 'scheduled_item.dart';

/// Real gateway over flutter_local_notifications (+ exact alarms on Android).
/// All scheduling DECISIONS live in NotificationService; this only executes.
class FlutterNotificationGateway implements NotificationGateway {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false, // we prompt via our priming flow
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const windows = WindowsInitializationSettings(
      appName: 'Tarf',
      appUserModelId: 'app.tarf.Tarf',
      guid: '4f1d2b6a-9c3e-4a7b-8f21-7e6d5c4b3a21',
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
        windows: windows,
      ),
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundTap,
    );

    // Create one Android channel per sound (channel sound is immutable).
    if (_isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      for (final id in NotificationSound.catalogIds) {
        final raw = NotificationSound.androidRawResource(id);
        await androidImpl?.createNotificationChannel(AndroidNotificationChannel(
          NotificationSound.androidChannelId(id),
          NotificationSound.channelName(id),
          importance: Importance.max,
          playSound: true,
          sound:
              raw == null ? null : RawResourceAndroidNotificationSound(raw),
        ));
      }
    }
    _ready = true;
  }

  @override
  Future<void> schedule(ScheduledItem item, DateTime fireAt) async {
    await init();
    final when = tz.TZDateTime.from(fireAt, tz.local);
    final androidRaw = NotificationSound.androidRawResource(item.soundId);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationSound.androidChannelId(item.soundId),
        NotificationSound.channelName(item.soundId),
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: item.kind != ScheduledKind.eyeBreak,
        sound: androidRaw == null
            ? null
            : RawResourceAndroidNotificationSound(androidRaw),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(
        sound: NotificationSound.appleSoundFile(item.soundId),
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      macOS: DarwinNotificationDetails(
        sound: NotificationSound.appleSoundFile(item.soundId),
      ),
      windows: const WindowsNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      item.notificationId,
      item.title,
      item.body.isEmpty ? null : item.body,
      when,
      details,
      payload: item.encodePayload(fireAt),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<PermissionStatus> queryNotificationPermission() async {
    if (_isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.areNotificationsEnabled() ?? false;
      return granted ? PermissionStatus.granted : PermissionStatus.denied;
    }
    if (_isApple) {
      // flutter_local_notifications does not expose a query on all versions;
      // treat as notDetermined until a request resolves it.
      return PermissionStatus.notDetermined;
    }
    return PermissionStatus.granted; // desktop best-effort
  }

  @override
  Future<PermissionStatus> requestNotificationPermission() async {
    if (_isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ok = await androidImpl?.requestNotificationsPermission() ?? false;
      return ok ? PermissionStatus.granted : PermissionStatus.denied;
    }
    if (!kIsWeb && Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final ok =
          await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
      return ok ? PermissionStatus.granted : PermissionStatus.denied;
    }
    if (!kIsWeb && Platform.isMacOS) {
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final ok =
          await mac?.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
      return ok ? PermissionStatus.granted : PermissionStatus.denied;
    }
    return PermissionStatus.granted; // windows/linux best-effort
  }

  @override
  Future<PermissionStatus> requestExactAlarmPermission() async {
    if (!_isAndroid) return PermissionStatus.granted; // n/a elsewhere
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ok = await androidImpl?.requestExactAlarmsPermission() ?? false;
    return ok ? PermissionStatus.granted : PermissionStatus.denied;
  }

  @override
  Future<PermissionStatus> queryExactAlarmPermission() async {
    if (!_isAndroid) return PermissionStatus.granted;
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ok = await androidImpl?.canScheduleExactNotifications() ?? false;
    return ok ? PermissionStatus.granted : PermissionStatus.denied;
  }
}
