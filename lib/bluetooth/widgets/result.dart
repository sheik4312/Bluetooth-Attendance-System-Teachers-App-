import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:login/drawer.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({Key? key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Set<String> selectedStudents = {};
  int currentPeriod = 1; // Initial period is 1
  int period = 1; // Declare period as a class-level variable

  // AddStudent Dialog
  Future<void> _addStudent() async {
    final existingStudents =
        await FirebaseFirestore.instance.collection('students').get();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0.0,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Add Student',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Divider(
                  color: Colors.grey,
                  height: 1,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: existingStudents.docs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          var student = existingStudents.docs[index];
                          if (student.data() != null &&
                              student.data()!.containsKey('name')) {
                            await FirebaseFirestore.instance
                                .collection('students')
                                .doc(student.id)
                                .update({
                              'attendance': true,
                              'attendance2': true,
                            });
                            setState(() {
                              selectedStudents.add(student['name'] as String);
                            });
                            Navigator.of(context).pop();
                          } else {
                            print(
                                'Error: Student document is missing "name" field.');
                          }
                        },
                        child: Card(
                          elevation: 2.0,
                          color: Colors.white70,
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            title: Row(
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    existingStudents.docs[index]['name']
                                        as String,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.red, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Generate PDF
  Future<void> _generatePdf(
      Set<String> presentStudents, Set<String> allStudents) async {
    Set<String> absentStudents = allStudents.difference(presentStudents);

    // Convert presentStudents and absentStudents sets to sorted lists
    List<String> sortedPresentStudents = presentStudents.toList()..sort();
    List<String> sortedAbsentStudents = absentStudents.toList()..sort();

    final pdf = pw.Document();

    final font =
        pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"));
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Students Attendance Report',
                style: pw.TextStyle(
                    font: font, fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Present List:',
                style: pw.TextStyle(
                    font: font,
                    fontSize: 18,
                    color: PdfColors.green,
                    fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              // Iterate over sortedPresentStudents list
              for (int index = 0; index < sortedPresentStudents.length; index++)
                pw.Text(
                  '${index + 1}. ${sortedPresentStudents[index]}',
                  style: pw.TextStyle(font: font),
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Absent List:',
                style: pw.TextStyle(
                    font: font,
                    fontSize: 18,
                    color: PdfColors.red,
                    fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              // Iterate over sortedAbsentStudents list
              for (int index = 0; index < sortedAbsentStudents.length; index++)
                pw.Text(
                  '${index + 1}. ${sortedAbsentStudents[index]}',
                  style: pw.TextStyle(font: font),
                ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '/data/user/0/com.example.login/files/result.pdf';

    File file = File(path);
    await file.writeAsBytes(await pdf.save());
    print('PDF file path: $path');

    OpenFile.open(file.path);
  }

  // Function to clear attendance and increment period
  Future<void> _clearAttendanceAndIncrementPeriod() async {
    // Clear the attendance details for the current period
    await _clearAttendance();

    // Increment the period and reset to 1 if it exceeds 7
    setState(() {
      currentPeriod = (currentPeriod % 7) + 1;
    });
  }

  Future<void> _storeAttendanceDateWise() async {
    // Get the current date
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);

    // Fetch present students and all students
    final studentSnapshot =
        await FirebaseFirestore.instance.collection('students').get();

    // Calculate the next period number
    period = period % 7;
    if (period == 0) {
      period += 1;
    }

    List<String> presentStudents = [];
    List<String> absentStudents = [];

    // Populate present and absent students lists
    for (DocumentSnapshot doc in studentSnapshot.docs) {
      String studentName = doc['name'] as String;
      bool isPresent = doc['attendance'] == true && doc['attendance2'] == true;

      if (isPresent) {
        presentStudents.add(studentName);
      } else {
        absentStudents.add(studentName);
      }
    }

    // Check if the document already exists for the date
    final dateDocument = await FirebaseFirestore.instance
        .collection('Attendance')
        .doc(formattedDate)
        .get();

    if (dateDocument.exists) {
      // If the document exists, update the existing period details
      await dateDocument.reference.update({
        'Period $period': {
          'PresentStudents': FieldValue.arrayUnion(presentStudents),
          'AbsentStudents': FieldValue.arrayUnion(absentStudents),
        },
      });
    } else {
      // If the document doesn't exist, create a new document with period details
      await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(formattedDate)
          .set({
        'Period $period': {
          'PresentStudents': presentStudents,
          'AbsentStudents': absentStudents,
        },
      });
    }

    // Increment the period
    period++;
  }

  // Function to clear attendance
  Future<void> _clearAttendance() async {
    // Clear the details in the "blue" collection
    await FirebaseFirestore.instance.collection('blue').get().then((snapshot) {
      for (DocumentSnapshot doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    // Update all students' attendance status
    final studentSnapshot =
        await FirebaseFirestore.instance.collection('students').get();

    // Store attendance date-wise
    await _storeAttendanceDateWise();

    for (DocumentSnapshot doc in studentSnapshot.docs) {
      await doc.reference.update({
        'attendance': false,
        'attendance2': false,
      });
    }

    // Clear the selected students set
    setState(() {
      selectedStudents.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('blue').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<String> blueMacs = snapshot.data!.docs
                .map((doc) => doc['remoteIdStr'] as String)
                .toList();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('students').snapshots(),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center();
                } else if (studentSnapshot.hasError) {
                  return Text('Error: ${studentSnapshot.error}');
                } else {
                  Set<String> presentStudents = studentSnapshot.data!.docs
                      .where((doc) =>
                          blueMacs.contains(doc['mac'] as String) &&
                          doc['attendance'] == true &&
                          doc['attendance2'] == true)
                      .map((doc) => doc['name'] as String)
                      .toSet();

                  Set<String> allStudents = studentSnapshot.data!.docs
                      .map((doc) => doc['name'] as String)
                      .toSet();

                  presentStudents.addAll(selectedStudents);

                  return Scaffold(
                    appBar: AppBar(
                      title: const Text(
                        'Student Attendance',
                        style: TextStyle(color: Colors.white),
                      ),
                      iconTheme: const IconThemeData(color: Colors.white),
                      backgroundColor: const Color.fromRGBO(37, 56, 141, 1),
                    ),
                    drawer: SDrawer(
                      initialSelectedIndex: 0,
                    ),
                    body: Stack(
                      children: [
                        ListView.builder(
                          itemCount: presentStudents.length,
                          itemBuilder: (context, index) {
                            final sortedDevices = presentStudents.toList()
                              ..sort();
                            return ListTile(
                              leading: Text(
                                '${index + 1}.',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              title: Text(
                                sortedDevices[index],
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: _clearAttendance,
                              style: ElevatedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color.fromRGBO(37, 56, 141, 1),
                                  width: 2.0,
                                ),
                                backgroundColor:
                                    const Color.fromRGBO(225, 230, 255, 1),
                              ),
                              child: const Text("Clear"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    floatingActionButton: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color.fromRGBO(37, 56, 141, 1),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: FloatingActionButton(
                            onPressed: () async {
                              _generatePdf(presentStudents, allStudents);
                            },
                            child: const Icon(Icons.picture_as_pdf),
                            backgroundColor:
                                const Color.fromRGBO(225, 230, 255, 1),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color.fromRGBO(37, 56, 141, 1),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: FloatingActionButton(
                            onPressed: () {
                              _addStudent();
                            },
                            child: const Icon(Icons.add),
                            backgroundColor:
                                const Color.fromRGBO(225, 230, 255, 1),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          }
        });
  }
}
