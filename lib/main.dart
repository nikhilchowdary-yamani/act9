import 'package:flutter/material.dart';
import 'helper.dart';
import 'screen/folder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database and prepopulate data
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;
  await dbHelper.prepopulateData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const FoldersScreen(),
    );
  }
}