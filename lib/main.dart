import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:bhima_collect/providers/current_depot_provider.dart';
import 'package:bhima_collect/providers/entry_movement.dart';
import 'package:bhima_collect/providers/exit_movement.dart';
import 'package:bhima_collect/screens/depot.dart';
import 'package:bhima_collect/screens/home.dart';
import 'package:bhima_collect/screens/settings.dart';
import 'package:bhima_collect/screens/splash_screen.dart';
import 'package:bhima_collect/screens/stock_entry.dart';
import 'package:bhima_collect/screens/stock_entry_integration.dart';
import 'package:bhima_collect/screens/stock_exit.dart';
import 'package:bhima_collect/screens/stock_list.dart';
import 'package:bhima_collect/screens/stock_loss.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CurrentDepotProvider()),
      ChangeNotifierProvider(create: (_) => EntryMovement()),
      ChangeNotifierProvider(create: (_) => ExitMovement()),
    ],
    child: const MainScreen(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 1000,
      splash: const SplashScreen(),
      nextScreen: const HomePage(),
      splashTransition: SplashTransition.fadeTransition,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MyAppState();
}

class _MyAppState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr', 'FR'),
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            // This will be applied to the "back" icon
            iconTheme: IconThemeData(color: Colors.blue[800]),
            // This will be applied to the action icon buttons that locates on the right side
            actionsIconTheme: IconThemeData(color: Colors.blue[800]),
            centerTitle: true,
            titleTextStyle: const TextStyle(color: Colors.blue)),
      ),
      home: const MyApp(),
      // initialRoute: '/',
      routes: {
        '/home': (context) => const HomePage(),
        '/depots': (context) => const ConfigureDepotPage(),
        '/settings': (context) => const SettingsPage(),
        '/stock': (context) => const StockListPage(),
        '/stock_entry': (context) => const StockEntryPage(),
        '/stock_exit': (context) => const StockExitPage(),
        '/stock_integration': (context) => const StockEntryIntegration(),
        '/stock_loss': (context) => const StockLossPage(),
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
