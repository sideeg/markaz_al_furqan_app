// Path: lib/services/notification_service.dart
//
// ─── How it works ────────────────────────────────────────────────────────────
//  • On every app launch / cold start, schedules 30 days worth of notifications
//    (iOS limit is 64 pending; 30 days × 2 = 60 — safe).
//  • Each day gets a randomly picked morning AND evening notification.
//  • Call NotificationService.instance.scheduleAll() from main.dart after init.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Random _rng = Random();

  // ── Channel ids ─────────────────────────────────────────────────────────────
  static const String _channelId = 'adhkar_markaz';
  static const String _channelName = 'أذكار الصباح والمساء';
  static const String _channelDesc =
      'إشعارات يومية بأذكار الصباح والمساء من تطبيق مركز الفرقان';

  // ── Scheduling constants ─────────────────────────────────────────────────
  static const int _morningHour = 5;
  static const int _morningMinute = 30;
  static const int _eveningHour = 17;
  static const int _eveningMinute = 25;
  static const int _daysAhead = 30;

  // =========================================================================
  // ── Morning notifications list ────────────────────────────────────────────
  // =========================================================================
  static const List<Map<String, String>> _morning = [
    {
      'title': 'إشراقة جديدة ☀️',
      'body':
          'ابدأ يومك بذكر الله لتنال البركة والتوفيق في كل خطوة. أذكار الصباح بانتظارك.',
    },
    {
      'title': 'حصن يومك 🛡️',
      'body':
          'أذكار الصباح هي حصنك الحصين من كل شر ومكروه. لا تخرج من بيتك قبل أن تتحصن.',
    },
    {
      'title': 'صلاة وتسبيح 🌅',
      'body':
          '"فاصبر وسبح بحمد ربك قبل طلوع الشمس".. ابدأ رحلة يومك بتسبيحة تزيح عنك الهم وتفتح لك الأبواب.',
    },
    {
      'title': 'حين تقوم.. 🛡️',
      'body':
          '"واذكر ربك حين تقوم".. أولى لحظات يومك هي الأهم، فلا تنسَ عهدك مع الله في أذكار الصباح.',
    },
    {
      'title': 'عهد جديد مع الله 🤲',
      'body':
          '"اللهم بك أصبحنا".. رددها بيقين ليبارك الله لك في وقتك وعملك اليوم.',
    },
    {
      'title': 'لسانٌ رطب 💧',
      'body':
          'أوصى النبي ﷺ رجلاً بشيء يتشبث به فقال: "لا يزال لسانك رطباً بذكر الله". عطّر فمك واكسب أجرك الآن.',
    },
    {
      'title': 'صباح الذاكرين 🕊️',
      'body':
          'أنر صباحك بكلمات تقربك من خالقك، واطرد همومك. هل قرأت أذكارك اليوم؟',
    },
    {
      'title': 'كن من السبّاقين 🏃‍♂️',
      'body':
          'قال ﷺ: "سبق المُفَرِّدون"، قالوا: وما المفردون؟ قال: "الذاكرون الله كثيراً والذاكرات". لا تتخلف عن الركب!',
    },
    {
      'title': 'سيد الاستغفار 👑',
      'body':
          'من قاله موقناً به ومات من يومه دخل الجنة. هل طرقت باب المغفرة اليوم؟ اقرأ سيد الاستغفار في أذكارك.',
    },
    {
      'title': 'ألا بذكر الله تطمئن القلوب ❤️',
      'body':
          'دقائق قليلة تقضيها في ذكر الله قادرة على إزاحة جبال من الهموم عن صدرك.',
    },
    {
      'title': 'أنيسك في الطريق 🛣️',
      'body':
          '"قياماً وقعوداً".. اجعل لسانك رطباً بذكر الله وأنت في طريقك، فالله معك أينما كنت.',
    },
    {
      'title': 'هل نسيت شيئاً مهماً؟ 💡',
      'body':
          'زحام الحياة قد ينسينا أعظم زاد. توقف لحظة، وخذ نفساً، واذكر الله.',
    },
    {
      'title': 'رضى الرحمن 🤲',
      'body':
          '"من قال: رضيت بالله رباً، وبالإسلام ديناً، وبمحمد نبياً، وجبَتْ له الجنة". قلها بيقين في صباحك.',
    },
    {
      'title': 'مفتاح الرزق 🔑',
      'body':
          'من بدأ يومه بذكر الله، تكفل الله به وأرضاه. دقائق قليلة تفتح لك أبواب الخير.',
    },
    {
      'title': 'أحب الكلام إلى الله ❤️',
      'body':
          '"أحب الكلام إلى الله أربع: سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر". لا تبخل على نفسك بهذا الأجر.',
    },
    {
      'title': 'مطلع النور ✨',
      'body':
          'طهر أنفاسك بذكر الله قبل أن تشرق الشمس، لتشرق الطمأنينة في قلبك طوال اليوم.',
    },
    {
      'title': 'كفاية للهموم ☁️',
      'body':
          'حين تكثر الصلاة على النبي ﷺ "يُكفى همك، ويُغفر ذنبك". اجعل له نصيباً من ذكرك اليوم.',
    }
  ];

  // =========================================================================
  // ── Evening notifications list ────────────────────────────────────────────
  // =========================================================================
  static const List<Map<String, String>> _evening = [
    {
      'title': 'سكنٌ وراحة 🌙',
      'body':
          'بعد عناء النهار، اختم يومك بذكر الله لتطمئن روحك ويهدأ قلبك. حان وقت أذكار المساء.',
    },
    {
      'title': 'قبل الغروب 🌆',
      'body':
          '"وسبح بحمد ربك قبل طلوع الشمس وقبل الغروب".. اختم يومك بكلمات يحبها الرحمن، اقرأ أذكارك الآن.',
    },
    {
      'title': 'أمانٌ في ليلتك 🌌',
      'body':
          'أذكار المساء أمان وحفظ لك حتى تصبح. لا تحرم نفسك هذا الفضل العظيم، اقرأها الآن.',
    },
    {
      'title': 'نبض الحياة 💓',
      'body':
          'قال ﷺ: "مثل الذي يذكر ربه والذي لا يذكر ربه مَثَلُ الحي والميت". أحيِ قلبك الآن بذكر الله.',
    },
    {
      'title': 'ختام مسك ✨',
      'body':
          'طيِّب صحيفتك في نهاية هذا اليوم بذكر الله. دقائق من وقتك تجلب لك طمأنينة الليل.',
    },
    {
      'title': 'نداء السكينة 🌌',
      'body':
          '"ومن آناء الليل فسبح".. اجعل لنفسك نصيباً من ذكر الله قبل المبيت لتنام في حفظ الله ورعايته.',
    },
    {
      'title': 'غراس الجنة 🌴',
      'body':
          'لقِيَ النبي ﷺ إبراهيم الخليل فأوصاه لأمته: "أخبرهم أن الجنة طيعة التربة.. وأن غراسها: سبحان الله والحمد لله". ازرع غراسك.',
    },
    {
      'title': 'في كل أحوالك 🚶‍♂️',
      'body':
          '"الذين يذكرون الله قياماً وقعوداً وعلى جنوبهم".. كن مع الله في كل حركة وسكون، اذكر الله الآن.',
    },
    {
      'title': 'كنز في ميزانك ⚖️',
      'body':
          '"كلمتان خفيفتان على اللسان، ثقيلتان في الميزان: سبحان الله وبحمده، سبحان الله العظيم". رددها الآن.',
    },
    {
      'title': 'زاد الروح 🕯️',
      'body':
          'كما أطعمت جسدك اليوم، لا تنسَ غذاء روحك. أذكار المساء حصن وسكينة.',
    },
    {
      'title': 'كفاية من كل شيء 🛡️',
      'body':
          'قال ﷺ عن المعوذات وقل هو الله أحد: "تكفيك من كل شيء" إذا قلتها حين تمسي وحين تصبح. حصّن نفسك الآن.',
    },
    {
      'title': 'تجارة لن تبور 📈',
      'body':
          '"واذكر ربك إذا نسيت".. إن غفلت في زحام العمل، فعد الآن إلى واحة الذكر، فهو الربح الحقيقي.',
    },
    {
      'title': 'شكر النعم 🤲',
      'body':
          'مضى النهار بحلوه ومره، فاشكر الله على نعمه التي لا تعد ولا تحصى. أذكار المساء تنتظرك.',
    },
    {
      'title': 'صلاةٌ وسلام 🕊️',
      'body':
          'قال ﷺ: "من صلّى عليّ صلاة واحدة، صلّى الله عليه عشر صلوات". عطّر وقتك بالصلاة على الحبيب.',
    },
    {
      'title': 'وصية غالية 💎',
      'body':
          '"واصبر نفسك مع الذين يدعون ربهم".. رفقاء الذكر هم السند، والتطبيق يذكرك لتبقى في ركب الذاكرين.',
    },
    {
      'title': 'كن من الذاكرين 👑',
      'body':
          '(والذاكرين الله كثيراً والذاكرات).. اجعل لنفسك نصيباً من هذه الآية العظيمة في هذا المساء.',
    },
    {
      'title': 'زاد المساء 🕯️',
      'body':
          'كما تغرب الشمس، تذهب الهموم بالاستغفار والذكر. حصن نفسك وأهلك بأذكار المساء.',
    }
  ];

  // =========================================================================
  // ── Public API ────────────────────────────────────────────────────────────
  // =========================================================================

  /// Call once in main() after WidgetsFlutterBinding.ensureInitialized()
  Future<void> init() async {
    tz.initializeTimeZones();
    final String localName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Request runtime permissions (Android 13+ / iOS)
    await _requestPermissions();
  }

  // ── NEW: Check critical permissions before scheduling ─────────────────────
  /// Returns true only if exact-alarm permission is granted.
  /// Also requests notification and battery-optimization permissions.
  Future<bool> ensureCriticalPermissions() async {
    if (!Platform.isAndroid) return true;

    // 1. Notification permission (Android 13+)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    // 2. Exact alarm permission (Android 12+) — REQUIRED for exactAllowWhileIdle
    final exactAlarm = await Permission.scheduleExactAlarm.status;
    if (!exactAlarm.isGranted) {
      final req = await Permission.scheduleExactAlarm.request();
      if (!req.isGranted) {
        debugPrint(
            '❌ Exact alarm permission denied — notifications will be delayed by Doze');
        return false;
      }
    }

    // 3. Battery optimization — so alarms survive when app is swiped away
    final battery = await Permission.ignoreBatteryOptimizations.status;
    if (!battery.isGranted) {
      final req = await Permission.ignoreBatteryOptimizations.request();
      if (!req.isGranted) {
        debugPrint(
            '⚠️ Battery optimization active — some OEMs may kill alarms');
      }
    }

    return true;
  }

  /// Call every time the app comes to the foreground.
  /// Guards: only schedules if critical permissions are granted.
  Future<void> scheduleAll() async {
    // GUARD: Do not schedule until permission is confirmed
    final bool canSchedule = await ensureCriticalPermissions();
    if (!canSchedule) {
      debugPrint('⛔ scheduleAll() aborted: exact-alarm permission not granted');
      return;
    }

    // Check how many notifications are currently in the queue
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();

    // If we still have at least 10 days worth (20 notifications), skip
    if (pending.length > 20) {
      debugPrint(
          "🔔 Queue is healthy (${pending.length} pending). Skipping reschedule.");
      return;
    }

    debugPrint("🔄 Rebuilding 30-day notification queue...");
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (int day = 0; day < _daysAhead; day++) {
      final morningEntry = _morning[_rng.nextInt(_morning.length)];
      final eveningEntry = _evening[_rng.nextInt(_evening.length)];

      final morningId = day * 2;
      final eveningId = day * 2 + 1;

      final morningTime = _dayAt(now, day, _morningHour, _morningMinute);
      final eveningTime = _dayAt(now, day, _eveningHour, _eveningMinute);

      if (morningTime.isAfter(now)) {
        await _schedule(
          id: morningId,
          title: morningEntry['title']!,
          body: morningEntry['body']!,
          scheduledDate: morningTime,
        );
      }

      if (eveningTime.isAfter(now)) {
        await _schedule(
          id: eveningId,
          title: eveningEntry['title']!,
          body: eveningEntry['body']!,
          scheduledDate: eveningTime,
        );
      }
    }
    debugPrint("✅ Successfully scheduled 30 days of Adhkar.");
  }

  // =========================================================================
  // ── Private helpers ───────────────────────────────────────────────────────
  // =========================================================================

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  tz.TZDateTime _dayAt(
      tz.TZDateTime base, int daysOffset, int hour, int minute) {
    return tz.TZDateTime(
      tz.local,
      base.year,
      base.month,
      base.day + daysOffset,
      hour,
      minute,
    );
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'local_adhkar',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
