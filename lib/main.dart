import 'package:firebase_core/firebase_core.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rougecodes/providers/navigation_provider.dart';
import 'package:rougecodes/providers/session_provider.dart';
import 'package:rougecodes/views/authentication/login.dart';
import 'package:rougecodes/views/home/home.dart';
import 'core/firebase_options.dart';
import 'providers/batch_provider.dart';
import 'layout/main_layout.dart';
import 'views/welcome.dart';
import 'providers/student_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorSchemeLight = SeedColorScheme.fromSeeds(
      brightness: Brightness.light,
      primaryKey: const Color(0xff7CFF00),
      variant: FlexSchemeVariant.rainbow,
    );
    final colorSchemeDark = SeedColorScheme.fromSeeds(
      brightness: Brightness.dark,
      primaryKey: const Color(0xff7CFF00),
      variant: FlexSchemeVariant.rainbow,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RougeCodes',
        theme: ThemeData(
          colorScheme: colorSchemeLight,
          useMaterial3: true,
          brightness: Brightness.light,
          textTheme: GoogleFonts.outfitTextTheme(),
        ),
        darkTheme: ThemeData(
          colorScheme: colorSchemeDark,
          useMaterial3: true,
          brightness: Brightness.dark,
          textTheme: GoogleFonts.outfitTextTheme().apply(
            bodyColor: Colors.white,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const AuthCheck(),
        routes: {
          '/welcome': (context) => const Welcome(),
          '/login': (context) => const Login(),
          '/main_layout': (context) => const MainLayout(),
          '/home': (context) => const Home(),
        },
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (session.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session.isAuthenticated && session.profile != null) {
          return const MainLayout();
        }

        return const Welcome();
      },
    );
  }
}
