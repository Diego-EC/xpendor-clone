import 'package:flutter/material.dart';
import 'package:xpendor_clone/screens/expense_list_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // Importante
import 'firebase_options.dart'; // El archivo que generamos antes

void main() async {
  // 1. Necesario para que Flutter no intente arrancar antes de tiempo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos Firebase con la configuración específica de la plataforma (Android o Web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Lanzamos la App
  runApp(const XpendorCloneApp());
}

class XpendorCloneApp extends StatelessWidget {
  const XpendorCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xpendor Clone',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true, // Esto le da un aspecto más moderno (Material 3)
      ),
      home: const ExpenseListScreen(),
    );
  }
}

