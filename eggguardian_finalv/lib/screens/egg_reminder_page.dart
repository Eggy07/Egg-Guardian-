import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EggReminderPage extends StatefulWidget {
  const EggReminderPage({super.key});

  @override
  State<EggReminderPage> createState() => _EggReminderPageState();
}

class _EggReminderPageState extends State<EggReminderPage> {
  DateTime? _selectedDate;
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load saved hatching day and reminder status
  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString('hatchingDay');
    bool? enabled = prefs.getBool('reminderEnabled');

    setState(() {
      if (dateString != null) _selectedDate = DateTime.parse(dateString);
      _reminderEnabled = enabled ?? true;
    });

    if (_reminderEnabled && _selectedDate != null) {
      _showNotification();
    }
  }

  // Save hatching day
  Future<void> _saveDate(DateTime date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hatchingDay', date.toIso8601String());
    setState(() {
      _selectedDate = date;
      _reminderEnabled = true; // enable automatically when picking
    });
    await prefs.setBool('reminderEnabled', true);
    _showNotification();
  }

  // Enable/disable reminder
  Future<void> _toggleReminder(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminderEnabled', value);
    setState(() => _reminderEnabled = value);
  }

  // Show snack bar notification if hatching day is near
  void _showNotification() {
    if (_selectedDate == null || !_reminderEnabled) return;

    final now = DateTime.now();
    final difference = _selectedDate!.difference(now).inDays;

    if (difference >= 0 && difference <= 7) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              difference == 0
                  ? '🥚 Your egg is hatching today!'
                  : '🐣 Your egg will hatch in $difference day(s)',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
  }

  // Pick a hatching day
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) _saveDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Reminder'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hatching Day Info
            Text(
              _selectedDate == null
                  ? 'No hatching day selected'
                  : 'Hatching Day: ${_selectedDate!.toLocal()}'.split(' ')[0],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Pick Hatching Day Button (bigger)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.calendar_today, size: 30),
                label: const Text(
                  'Pick Hatching Day',
                  style: TextStyle(fontSize: 22),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Toggle Reminder On/Off
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Switch(
                  value: _reminderEnabled,
                  onChanged: (val) => _toggleReminder(val),
                  activeThumbColor: Colors.orange, // <- updated
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
