import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'dart:convert';

import 'main.dart';

class AttendanceStudent extends StatefulWidget {
  final User user;
  const AttendanceStudent({super.key, required this.user});

  @override
  _AttendanceStudentState createState() => _AttendanceStudentState();
}

class _AttendanceStudentState extends State<AttendanceStudent> {
  DateTime selectedDate = DateTime.now();
  String? selectedSubject;
  String studentClass = '';

  Map<DateTime, List<bool>> attendanceSummaryMap = {};
  Map<int, bool> selectedDayLectureStatus = {};

  final List<String> subjects = [
    'Maths',
    'Digital Electronics',
    'Physics',
    'Programming Logic Skills',
    'Python',
  ];

  @override
  void initState() {
    super.initState();
    selectedSubject = subjects.first;
    studentClass = _getClassByStudent(widget.user.username);
    _loadAttendanceForCalendar();
    _loadLectureStatusesForSelectedDate();
  }

  String _getClassByStudent(String username) {
    if (['student1', 'student2'].contains(username)) return 'Class A';
    return 'Class B';
  }

  // Fetch attendance data from Firestore and map it for calendar
  Future<void> _loadAttendanceForCalendar() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    Map<DateTime, List<bool>> tempMap = {};

    for (int i = 0; i < 365; i++) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      List<bool> statuses = [];

      for (int lec = 1; lec <= 5; lec++) {
        final key =
            '${selectedSubject}_${studentClass}_${_formatDate(date)}_lecture$lec';

        // Fetch data from Firestore based on the key
        final snapshot =
            await firestore.collection('attendance').doc(key).get();

        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data.containsKey(widget.user.username)) {
            statuses.add(data[widget.user.username] == true);
          }
        }
      }

      if (statuses.isNotEmpty) {
        tempMap[DateTime(date.year, date.month, date.day)] = statuses;
      }
    }

    setState(() {
      attendanceSummaryMap = tempMap;
    });
  }

  // Load lecture status for a specific date from Firestore
  Future<void> _loadLectureStatusesForSelectedDate() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    Map<int, bool> lectureStatusMap = {};

    for (int lecture = 1; lecture <= 5; lecture++) {
      final key =
          '${selectedSubject}_${studentClass}_${_formattedDate()}_lecture$lecture';

      // Fetch data from Firestore
      final snapshot = await firestore.collection('attendance').doc(key).get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey(widget.user.username)) {
          lectureStatusMap[lecture] = data[widget.user.username];
        }
      }
    }

    setState(() {
      selectedDayLectureStatus = lectureStatusMap;
    });
  }

  String _formattedDate() => selectedDate.toIso8601String().split("T")[0];
  String _formatDate(DateTime dt) => dt.toIso8601String().split("T")[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child:
                isWide
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSubjectDropdown()),
                        SizedBox(width: 20),
                        Expanded(child: _buildCalendar()),
                        SizedBox(width: 20),
                        Expanded(child: _buildStatusMessage()),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSubjectDropdown(),
                        SizedBox(height: 16),
                        _buildCalendar(),
                        SizedBox(height: 16),
                        _buildStatusMessage(),
                      ],
                    ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSubject,
      decoration: InputDecoration(
        labelText: "Select Subject",
        border: OutlineInputBorder(),
      ),
      items:
          subjects
              .map(
                (subject) =>
                    DropdownMenuItem(value: subject, child: Text(subject)),
              )
              .toList(),
      onChanged: (newSubject) {
        setState(() {
          selectedSubject = newSubject!;
          attendanceSummaryMap.clear();
          selectedDayLectureStatus.clear();
        });
        _loadAttendanceForCalendar();
        _loadLectureStatusesForSelectedDate();
      },
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      focusedDay: selectedDate,
      firstDay: DateTime(2020),
      lastDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      onDaySelected: (selected, _) {
        setState(() {
          selectedDate = selected;
        });
        _loadLectureStatusesForSelectedDate();
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final dayKey = DateTime(day.year, day.month, day.day);
          final statuses = attendanceSummaryMap[dayKey];

          if (statuses != null) {
            Color bgColor;
            int presentCount = statuses.where((s) => s).length;

            if (presentCount == 0) {
              bgColor = Colors.red.withOpacity(0.4);
            } else if (presentCount == statuses.length) {
              bgColor = Colors.green.withOpacity(0.4);
            } else {
              bgColor = Colors.blue.withOpacity(0.4);
            }

            return Container(
              margin: EdgeInsets.all(6),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return null;
        },
        todayBuilder: (context, day, _) {
          return Container(
            margin: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            "Attendance for ${_formattedDate()} in $selectedSubject",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          if (selectedDayLectureStatus.isEmpty)
            Text("No attendance recorded for this date."),
          if (selectedDayLectureStatus.isNotEmpty)
            ...selectedDayLectureStatus.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "Lecture ${entry.key} - ${entry.value ? 'Present' : 'Absent'}",
                  style: TextStyle(
                    fontSize: 16,
                    color: entry.value ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
