import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.account_circle, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Ahmad Zainudin Fanani', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            SizedBox(height: 8),
            Text(
              'NIM: 244107020051', 
              style: TextStyle(fontSize: 18, color: Colors.grey)
            ),
            SizedBox(height: 8),
            Text(
              'Program Studi: D4 Teknik Informatika', 
              style: TextStyle(fontSize: 18, color: Colors.grey)
            ),
          ]),
        ),
      ),
    );
  }
}