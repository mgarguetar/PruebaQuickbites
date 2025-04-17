import 'package:flutter/material.dart';
import 'package:quickbites_prueba/auth/register.dart';
//import 'package:quickbites_prueba/screens/waiter/HomePage_waiter.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:quickbites_prueba/screens/waiter/SeleccionMesaScreen.dart';
import 'firebase_options.dart';
//import 'package:quickbites_prueba/screens/admin/Additem.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Register(), // You can switch to AddItemScreen() or HomePageWaiter() as needed
    );
  }
}
