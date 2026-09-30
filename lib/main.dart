import 'package:flutter/material.dart';
import 'package:flutter_learn/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dipfznhmoluwjlwyriwt.supabase.co',
    // ignore: deprecated_member_use
    anonKey: 'sb_publishable_tn7-c4srA4Vn4HfxOAUm-A_KBjRNFUk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sales Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}