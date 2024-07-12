import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/drawer.dart';

class Sample extends StatefulWidget {
  const Sample({Key? key}) : super(key: key);

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final macController = TextEditingController();
  final batchNoController = TextEditingController();
  final registerNumberController = TextEditingController();
  bool isLoading = false;

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Data stored successfully.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Student",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromRGBO(37, 56, 141, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const SDrawer(
        initialSelectedIndex: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(30.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(30.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: macController,
                      decoration: const InputDecoration(
                        labelText: 'Mac Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: batchNoController,
                      decoration: const InputDecoration(
                        labelText: 'Batch No',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: registerNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Register Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });
                          User? user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            CollectionReference studentsRef = FirebaseFirestore
                                .instance
                                .collection('students');

                            // Check if email already exists
                            QuerySnapshot querySnapshot = await studentsRef
                                .where('email', isEqualTo: emailController.text)
                                .get();

                            if (querySnapshot.docs.isNotEmpty) {
                              // If email already exists, show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email already exists'),
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                              return;
                            }

                            // If email doesn't exist, add the student
                            await studentsRef.add({
                              'userId': user.uid,
                              'name': nameController.text,
                              'email': emailController.text,
                              'mac': macController.text,
                              'batchNo': batchNoController.text,
                              'registerNumber':
                                  int.parse(registerNumberController.text),
                              'attendance':
                                  false, // Set attendance default value
                              'attendance2':
                                  false, // New field with default value
                            });

                            nameController.clear();
                            emailController.clear();
                            macController.clear();
                            batchNoController.clear();
                            registerNumberController.clear();

                            setState(() {
                              isLoading = false;
                            });

                            await _showSuccessDialog();
                          } else {
                            print('User is not signed in.');
                          }
                        },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromRGBO(37, 56, 141, 1),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Add Student',
                          style: TextStyle(color: Colors.white, fontSize: 17.5),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
