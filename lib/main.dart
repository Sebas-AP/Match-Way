import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/ruta_match_screen.dart';
import 'theme/app_colors.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Si está vacío, sube los datos
  await FirebaseService().seedDatabaseIfEmpty();

  runApp(const HacktoonApp());
}

class HacktoonApp extends StatelessWidget {
  const HacktoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruta Match Durango',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: TierraColors.crema,
        colorScheme: ColorScheme.fromSeed(seedColor: TierraColors.terracota),
        useMaterial3: true,
      ),
      home: const RutaMatchScreen(),
    );
  }
}