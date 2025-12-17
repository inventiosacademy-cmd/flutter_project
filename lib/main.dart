import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/prov_auth.dart';
import 'providers/prov_karyawan.dart';
import 'screens/layar_login.dart';
import 'screens/layar_utama.dart';
import 'theme/tema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
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
