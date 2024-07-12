import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../bluetooth/screens/scan_screen.dart';
import '../drawer.dart';

class AttendanceRecord extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(
          'Attendance Record',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromRGBO(37, 56, 141, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const SDrawer(
        initialSelectedIndex: 4,
      ), // Add SDrawer as the drawer widget
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Attendance').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No attendance records found.'),
            );
          }

          List<String> dates =
              snapshot.data!.docs.map((doc) => doc.id).toList();

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (BuildContext context, int index) {
              String date = dates[index];
              final periods =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceDetails(
                        date: date,
                        periods: periods,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AttendanceDetails extends StatelessWidget {
  final String date;
  final Map<String, dynamic> periods;

  const AttendanceDetails({
    required this.date,
    required this.periods,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Attendance => $date',
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: const Color.fromRGBO(37, 56, 141, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: periods.length,
        itemBuilder: (context, index) {
          String period = periods.keys.toList()[index];
          Map<String, dynamic> periodData = periods[period];
          List<dynamic> presentStudents =
              periodData.containsKey('PresentStudents')
                  ? periodData['PresentStudents']
                  : [];
          List<dynamic> absentStudents =
              periodData.containsKey('AbsentStudents')
                  ? periodData['AbsentStudents']
                  : [];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PeriodDetails(
                    period: period,
                    presentStudents: presentStudents,
                    absentStudents: absentStudents,
                  ),
                ),
              );
            },
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  '$period',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PeriodDetails extends StatelessWidget {
  final String period;
  final List<dynamic> presentStudents;
  final List<dynamic> absentStudents;

  const PeriodDetails({
    required this.period,
    required this.presentStudents,
    required this.absentStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Students Attendance',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: const Color.fromRGBO(37, 56, 141, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanScreen()),
                  );
                },
              ),
              const SizedBox(
                  width: 16), // Adjust the width according to your preference
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
            title: Text(
              'Present Students',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          ...presentStudents.asMap().entries.map((entry) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                title: Text('${entry.key + 1}. ${entry.value}'),
              )),
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
            title: Text(
              'Absent Students',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          ...absentStudents.asMap().entries.map((entry) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                title: Text('${entry.key + 1}. ${entry.value}'),
              )),
        ],
      ),
    );
  }
}
