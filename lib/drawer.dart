import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:login/bluetooth/widgets/result.dart';
import 'bluetooth/screens/scan_screen.dart';
import 'student/attendancerecord.dart';
import 'student/studentadd.dart';
import 'student/studentdetails.dart';

class SDrawer extends StatefulWidget {
  final int initialSelectedIndex;

  const SDrawer({Key? key, required this.initialSelectedIndex})
      : super(key: key);

  @override
  _SDrawerState createState() => _SDrawerState();
}

class _SDrawerState extends State<SDrawer> {
  final user = FirebaseAuth.instance.currentUser;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16.0,
      child: Container(
        color: Colors.white, // Change the color here
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(37, 56, 141,
                    1), // Change the color of the drawer header to blue
              ),
              accountName: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                        'Loading...'); // Placeholder until data is loaded
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.hasData && snapshot.data!.exists) {
                    return Text(snapshot.data!['name']);
                  } else {
                    return const Text(
                        'Teacher'); // Fallback if name is not available
                  }
                },
              ),
              accountEmail: Text('${user?.email ?? ""}'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images.png'),
              ),
            ),
            ListTile(
              title: const Text('Attendance'),
              leading: const Icon(Icons.list_alt),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ResultPage()),
                );
              },
              selected: _selectedIndex == 0,
              selectedTileColor:
                  Colors.blue.withOpacity(0.2), // Highlight color
            ),
            const Divider(
              height: 0.1,
            ),
            ListTile(
              title: const Text('Scan Student'),
              leading: const Icon(Icons.search),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanScreen()),
                );
              },
              selected: _selectedIndex == 1,
              selectedTileColor:
                  Colors.blue.withOpacity(0.2), // Highlight color
            ),
            const Divider(
              height: 0.1,
            ),
            ListTile(
              title: const Text('Students List'),
              leading: const Icon(Icons.list),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Detail()),
                );
              },
              selected: _selectedIndex == 2,
              selectedTileColor:
                  Colors.blue.withOpacity(0.2), // Highlight color
            ),
            const Divider(
              height: 0.1,
            ),
            ListTile(
              title: const Text('Add Student'),
              leading: const Icon(Icons.add),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Sample()),
                );
              },
              selected: _selectedIndex == 3,
              selectedTileColor:
                  Colors.blue.withOpacity(0.2), // Highlight color
            ),
            const Divider(
              height: 0.1,
            ),
            ListTile(
              title: const Text('Record'),
              leading: const Icon(Icons.assignment),
              onTap: () => {
                setState(() {
                  _selectedIndex = 4;
                }),
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AttendanceRecord()),
                )
              },
              selected: _selectedIndex == 4,
              selectedTileColor: Colors.blue.withOpacity(0.2),
            ),
            const Divider(
              height: 0.1,
            ),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.exit_to_app),
              onTap: () => signOut(),
            ),
            const Divider(
              height: 0.1,
            ),
          ],
        ),
      ),
    );
  }
}
