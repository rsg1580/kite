import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

  await notificationsPlugin.initialize(initSettings);

  runApp(const KiteApp());
}

class KiteApp extends StatelessWidget {
  const KiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kite',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController titleController = TextEditingController();
  DateTime? selectedDateTime;
  bool daily = false;

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> scheduleNotification() async {
    if (titleController.text.isEmpty || selectedDateTime == null) return;

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await notificationsPlugin.zonedSchedule(
      id,
      titleController.text,
      'Reminder from Kite',
      tz.TZDateTime.from(selectedDateTime!, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kite_channel',
          'Kite Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          daily ? DateTimeComponents.time : null,
    );

    titleController.clear();
    setState(() => selectedDateTime = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kite 🪁')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Reminder title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: pickDateTime,
                  child: const Text('Pick Date & Time'),
                ),
                const SizedBox(width: 12),
                if (selectedDateTime != null)
                  Text(
                    DateFormat('dd MMM, hh:mm a')
                        .format(selectedDateTime!),
                  ),
              ],
            ),
            SwitchListTile(
              title: const Text('Repeat Daily'),
              value: daily,
              onChanged: (v) => setState(() => daily = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: scheduleNotification,
              child: const Text('Save Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
