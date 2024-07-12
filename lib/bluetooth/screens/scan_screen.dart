import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:login/drawer.dart';
import '../widgets/result.dart';
import '../widgets/scan_result_tile.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  final user = FirebaseAuth.instance.currentUser;

  Future<void> onValidatePressed() async {
    setState(() {
      _validating = true;
    });

    // Store data for all scanned devices in Firestore
    for (var result in _scanResults) {
      // Check if the device has a non-null name and its MAC address is not null
      if (result.device.name != null && result.device.id != null) {
        // Store data for devices with non-null names and MAC addresses in Firestore
        await FirebaseFirestore.instance.collection('blue').add({
          'remoteIdStr': result.device.id.toString(),
          // You can add more fields if needed
        });

        // Update attendance fields for the matched device record in 'students' collection
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('mac', isEqualTo: result.device.id.toString())
            .get();
        querySnapshot.docs.forEach((doc) async {
          await doc.reference.update({
            'attendance': true,
          });
        });
      }
    }

    // Navigate to the "result" page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResultPage()),
    );

    setState(() {
      _validating = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        _scanResults = results;
        if (mounted) {
          setState(() {});
        }
      },
    );

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    _systemDevices = await FlutterBluePlus.systemDevices;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 40));

    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    FlutterBluePlus.stopScan();
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
        onPressed: onScanPressed,
        child: const Text("SCAN"),
        backgroundColor: const Color.fromRGBO(
            225, 230, 255, 1), // Background color of the button
        shape: RoundedRectangleBorder(
          side: const BorderSide(
              color: Color.fromRGBO(37, 56, 141, 1), width: 2), // Border color
          borderRadius:
              BorderRadius.circular(10), // Optional: for rounded corners
        ),
      );
    }
  }

  bool _validating = false;

  Widget buildValidateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5.0,
      ), // Adjust padding as needed
      child: SizedBox(
        width: double.infinity, // Set width to occupy full screen width
        child: _validating
            ? Padding(
                padding: const EdgeInsets.only(
                    left: 185, right: 185), // Add padding around the indicator
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth:
                        2, // Adjust the thickness of the progress indicator
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: onValidatePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(37, 56, 141, 1),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0), // Adjust button height
                ),
                child: const Text(
                  'Validate',
                  style: TextStyle(
                      fontSize: 18, color: Colors.white), // Adjust font size
                ),
              ),
      ),
    );
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () {},
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Student Attendance",
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          backgroundColor: const Color.fromRGBO(37, 56, 141, 1),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: const SDrawer(
          initialSelectedIndex: 1,
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
        floatingActionButtonLocation: FloatingActionButtonLocation
            .endFloat, // Set floating action button location
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10),
          child: buildValidateButton(context),
        ),
      ),
    );
  }
}
