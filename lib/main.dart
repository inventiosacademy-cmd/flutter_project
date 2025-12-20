import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/prov_auth.dart';
import 'providers/prov_karyawan.dart';
import 'providers/prov_evaluasi.dart';
import 'screens/layar_login.dart';
import 'screens/layar_utama.dart';
import 'theme/tema.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable offline persistence
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, 
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
    );
  } catch (e) {
    debugPrint("Firestore persistence error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => EvaluasiProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Initialize EvaluasiProvider when user is logged in
          if (auth.isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<EvaluasiProvider>(context, listen: false).init();
            });
          }
          return MaterialApp(
            title: 'HR Dashboard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: auth.isLoggedIn ? const MainScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}

