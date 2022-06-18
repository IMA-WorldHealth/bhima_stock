import 'package:bhima_collect/screens/depot.dart';
import 'package:bhima_collect/screens/home.dart';
import 'package:bhima_collect/screens/settings.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            // This will be applied to the "back" icon
            iconTheme: IconThemeData(color: Colors.blue[800]),
            // This will be applied to the action icon buttons that locates on the right side
            actionsIconTheme: IconThemeData(color: Colors.blue[800]),
            centerTitle: true,
            titleTextStyle: const TextStyle(color: Colors.blue)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/depots': (context) => const ConfigureDepotPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
