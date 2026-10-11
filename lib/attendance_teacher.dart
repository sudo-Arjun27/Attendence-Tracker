import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'main.dart';

class AttendanceTeacher extends StatefulWidget {
  final User user;

  const AttendanceTeacher({super.key, required this.user});

  @override
  _AttendanceTeacherState createState() => _AttendanceTeacherState();
}

class _AttendanceTeacherState extends State<AttendanceTeacher> {
  DateTime selectedDate = DateTime.now();
  Map<String, bool> attendance = {};
  List<String> students = [];
  late String subject;
  late String selectedClass;
  int lectureNumber = 1; // NEW: Support for multiple lectures

  final Map<String, String> teacherSubjectMap = {
    'teacher1': 'Maths',
    'teacher2': 'Digital Electronics',
    'teacher3': 'Physics',
    'teacher4': 'Programming Logic Skills',
    'teacher5': 'Python',
  };

  @override
  void initState() {
    super.initState();
    subject = teacherSubjectMap[widget.user.username] ?? 'Unknown';
    selectedClass = _getClassBySubject(subject);
    _initializeStudents();
    _loadAttendance();
  }

  String _getClassBySubject(String subject) {
    if (['Maths', 'Digital Electronics'].contains(subject)) return 'Class A';
    return 'Class B';
  }

  void _initializeStudents() {
    students =
        selectedClass == 'Class A'
            ? ['student1', 'student2']
            : ['student3', 'student4', 'student5'];
  }

  void _loadAttendance() async {
    FirebaseFirestore.instance
        .collection('attendance')
        .doc(
          '${subject}_${selectedClass}_${_formattedDate()}_lecture$lectureNumber',
        )
        .get()
        .then((docSnapshot) {
          if (docSnapshot.exists) {
            setState(() {
              attendance = Map<String, bool>.from(docSnapshot.data()!);
            });
          } else {
            setState(() {
              attendance = {for (var s in students) s: false};
            });
          }
        });
  }

  void _saveAttendance() async {
    FirebaseFirestore.instance
        .collection('attendance')
        .doc(
          '${subject}_${selectedClass}_${_formattedDate()}_lecture$lectureNumber',
        )
        .set(attendance)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Attendance saved for $subject (Lecture $lectureNumber)!',
              ),
            ),
          );
        });
  }

  String _formattedDate() => selectedDate.toIso8601String().split("T")[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child:
                isWide
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCalendarCard()),
                        SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildAttendancePanel()),
                      ],
                    )
                    : Column(
                      children: [
                        _buildCalendarCard(),
                        SizedBox(height: 16),
                        _buildAttendancePanel(),
                      ],
                    ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          focusedDay: selectedDate,
          firstDay: DateTime(2020),
          lastDay: DateTime.now(),
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          onDaySelected: (selected, _) {
            setState(() {
              selectedDate = selected;
              _initializeStudents();
              _loadAttendance();
            });
          },
        ),
      ),
    );
  }

  Widget _buildAttendancePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: InputDecoration(
            labelText: "Select Class",
            border: OutlineInputBorder(),
          ),
          items:
              [
                'Class A',
                'Class B',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) {
            setState(() {
              selectedClass = val!;
              _initializeStudents();
              _loadAttendance();
            });
          },
        ),
        SizedBox(height: 12),

        // NEW: Lecture Number Dropdown
        DropdownButtonFormField<int>(
          value: lectureNumber,
          decoration: InputDecoration(
            labelText: "Select Lecture Number",
            border: OutlineInputBorder(),
          ),
          items:
              List.generate(5, (index) => index + 1)
                  .map(
                    (num) => DropdownMenuItem(
                      value: num,
                      child: Text('Lecture $num'),
                    ),
                  )
                  .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                lectureNumber = val;
                _loadAttendance();
              });
            }
          },
        ),
        SizedBox(height: 12),

        Text(
          'Subject: $subject\nClass: $selectedClass',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (context, index) {
            String student = students[index];
            bool? status = attendance[student];

            return Card(
              margin: EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                attendance[student] = true;
                              });
                            },
                            icon: Icon(Icons.check),
                            label: Text('Present'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  status == true ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                attendance[student] = false;
                              });
                            },
                            icon: Icon(Icons.close),
                            label: Text('Absent'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  status == false ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveAttendance,
            icon: Icon(Icons.save),
            label: Text('Submit Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
