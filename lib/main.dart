import 'package:cleaning_schedule/screens/places/list_place_page.dart';
import 'package:cleaning_schedule/screens/workers/list_workers_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CleaningScheduleApp());
}

class CleaningScheduleApp extends StatelessWidget {
  const CleaningScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔐 Fournit l'état FirebaseAuth à toute l'application
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Cleaning Schedule',
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFFF7F9FB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
        '/listPlace': (context) => const ListPlace(),
        '/workers': (context) => const ListWorkersPage(),

        // '/detailsPlace': (context) => const DetailsPlacePage(),
},
      ),
    );
  }
}

/// Gère la navigation en fonction de l’état de connexion Firebase.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // 👇 Si l’utilisateur est connecté → HomePage, sinon → LoginPage
    if (user == null) {
      return const LoginPage();
    } else {
      return const HomePage();
    }
  }
}
