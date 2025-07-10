import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:petpal/auth-modules/login_page.dart';
import 'package:petpal/auth-modules/reg_page.dart';
import 'package:petpal/landing_page.dart';
import 'package:petpal/page-layout/pet_owner_dashboard.dart';
import 'package:petpal/page-layout/vet_dashboard.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_home_page.dart';
import 'package:petpal/vet-modules/pages/vet_appointments_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

final _logger = Logger('MyApp');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
  });


  await dotenv.load(fileName: "assets/auth.env");

  final String? cloudinaryUrl = dotenv.env['CLOUDINARY_URL'];
  final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
  final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    _logger.severe("Environment variables for Supabase are missing!");
    throw Exception("Environment variables for Supabase are missing!");
  }

  try {
    final response = await http.get(Uri.parse("https://google.com"));
  } catch (e) {
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MainApp()); 
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LandingPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegPage(),
        '/pet-owner-home': (context) => PetOwnerHomePage(),
        '/vet': (context) => VetDashboard(initialIndex: 0),
        '/pet-owner-dashboard': (context) => PetOwnerDashboard(initialIndex: 0),
        '/appointments': (context) => StaffAppointmentPage()
      },
    );
  }
}