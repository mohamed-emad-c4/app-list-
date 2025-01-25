import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/app_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Installed Apps List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
       
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      home: PermissionScreen(),
    );
  }
}

class PermissionScreen extends StatefulWidget {
  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  String _permissionStatus = 'غير معروف';

  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    setState(() {
      _permissionStatus = status.isGranted ? 'تم منح الإذن' : 'تم رفض الإذن';
    });

    if (status.isGranted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AppHomeScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(_permissionStatus),
      ),
    );
  }
}
