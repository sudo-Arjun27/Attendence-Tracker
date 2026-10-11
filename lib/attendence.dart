import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'main.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedClass = 'Class A';
  Map<String, bool> attendance = {};
  List<String> students = [];
  bool isTeacher = false;
  String username = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ModalRoute.of(context)!.settings.arguments as User?;
      if (user != null) {
        username = user.username;
        isTeacher = user.role == 'teacher';
        _initializeStudents();
        _loadAttendance();
      }
    });
  }

  void _initializeStudents() {
    if (selectedClass == 'Class A') {
      students = ['student1', 'student2'];
    } else {
      students = ['student3', 'student4', 'student5'];
    }
  }

  void _loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        '${selectedClass}_${selectedDate.toIso8601String().split("T")[0]}';
    final data = prefs.getString('attendance_$key');
    if (data != null) {
      final parsed = json.decode(data) as Map<String, dynamic>;
      setState(() {
        attendance = parsed.map((k, v) => MapEntry(k, v as bool));
      });
    } else {
      setState(() {
        attendance = {for (var s in students) s: false};
      });
    }
  }

  void _saveAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        '${selectedClass}_${selectedDate.toIso8601String().split("T")[0]}';
    await prefs.setString('attendance_$key', json.encode(attendance));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Attendance saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          focusedDay: selectedDate,
          firstDay: DateTime(2020),
          lastDay: DateTime.now(),
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          onDaySelected: (selected, _) {
            setState(() {
              selectedDate = selected;
              _initializeStudents();
              _loadAttendance();
            });
          },
        ),
        if (isTeacher) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedClass,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedClass = value;
                    _initializeStudents();
                    _loadAttendance();
                  });
                }
              },
              items:
                  ['Class A', 'Class B'].map((cls) {
                    return DropdownMenuItem(value: cls, child: Text(cls));
                  }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                String student = students[index];
                bool? status = attendance[student];
                return Card(
                  child: ListTile(
                    title: Text(student),
                    subtitle: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              attendance[student] = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                status == true ? Colors.green : null,
                          ),
                          child: Text('Present'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              attendance[student] = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                status == false ? Colors.red : null,
                          ),
                          child: Text('Absent'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(onPressed: _saveAttendance, child: Text('Submit')),
        ] else
          Expanded(
            child: FutureBuilder(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final prefs = snapshot.data as SharedPreferences;
                final userClass =
                    ['student1', 'student2'].contains(username)
                        ? 'Class A'
                        : 'Class B';
                final key =
                    '${userClass}_${selectedDate.toIso8601String().split("T")[0]}';
                final data = prefs.getString('attendance_$key');
                if (data != null) {
                  final parsed = json.decode(data) as Map<String, dynamic>;
                  final status = parsed[username];
                  if (status == true) {
                    return Center(
                      child: Text(
                        'You were PRESENT on this day',
                        style: TextStyle(fontSize: 20, color: Colors.green),
                      ),
                    );
                  } else if (status == false) {
                    return Center(
                      child: Text(
                        'You were ABSENT on this day',
                        style: TextStyle(fontSize: 20, color: Colors.red),
                      ),
                    );
                  } else {
                    return Center(
                      child: Text(
                        'No attendance record found.',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }
                } else {
                  return Center(
                    child: Text(
                      'No attendance recorded yet.',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
