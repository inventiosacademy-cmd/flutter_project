import 'dart:io'; // Import ini penting untuk cek Platform (isWindows, isAndroid)
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Code Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Single Codebase Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // LOGIC PERBEDAAN TAMPILAN
    // Kita cek apakah aplikasi sedang berjalan di Windows atau tidak
    // Code ini bejalan di SATU file yang sama, tidak perlu dipisah.
    bool isWindows = false;
    try {
      isWindows = Platform.isWindows;
    } catch (e) {
      // Fallback jika dijalankan di platform yang tidak mendukung dart:io (misal Web)
      isWindows = false;
    }

    return Scaffold(
      appBar: AppBar(
        // CONTOH 1: Beda Warna AppBar
        // Jika Windows warna Biru, jika Android warna Ungu (sesuai tema)
        backgroundColor: isWindows ? Colors.blue[900] : Theme.of(context).colorScheme.inversePrimary,
        
        // CONTOH 2: Beda Warna Text
        // Jika Windows text Putih (kontras dengan biru), jika Android Hitam
        foregroundColor: isWindows ? Colors.white : Colors.black,
        
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // CONTOH 3: Beda Icon
            Icon(
              isWindows ? Icons.desktop_windows : Icons.phone_android,
              size: 100,
              color: isWindows ? Colors.blue[800] : Colors.green,
            ),
            const SizedBox(height: 20),
            
            // CONTOH 4: Beda Teks
            Text(
              isWindows ? 'Mode Desktop (Windows)' : 'Mode Mobile (Android/iOS)',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tampilan ini dibuat dari 1 file code yang sama. Flutter otomatis mendeteksi OS saat aplikasi dijalankan.',
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            const Text(
              'Tombol ditekan sebanyak:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      
      // CONTOH 5: Beda Jenis Tombol
      // Di Windows kita pakai tombol lebar dengan tulisan (FloatingActionButton.extended)
      // Di Android kita pakai tombol bulat ikon saja (FloatingActionButton biasa)
      floatingActionButton: isWindows
          ? FloatingActionButton.extended(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              icon: const Icon(Icons.add),
              label: const Text("Tambah Data (Windows Style)"),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            )
          : FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
    );
  }
}
