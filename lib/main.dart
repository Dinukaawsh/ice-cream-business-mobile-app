import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";

import "config/brand.dart";
import "screens/home_screen.dart";
import "screens/login_screen.dart";
import "services/api_service.dart";
import "widgets/auth_ui.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  final api = ApiService();
  await api.loadToken();
  runApp(ScooplyApp(api: api));
}

class ScooplyApp extends StatefulWidget {
  const ScooplyApp({super.key, required this.api});

  final ApiService api;

  @override
  State<ScooplyApp> createState() => _ScooplyAppState();
}

class _ScooplyAppState extends State<ScooplyApp> {
  SessionUser? _user;
  var _booting = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final user = await widget.api.fetchMe();
      if (mounted) {
        setState(() {
          _user = user;
          _booting = false;
        });
      }
    } catch (_) {
      await widget.api.clearToken();
      if (mounted) {
        setState(() {
          _user = null;
          _booting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Brand.name,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AuthColors.primary,
          primary: AuthColors.primary,
          surface: AuthColors.frost,
        ),
        scaffoldBackgroundColor: AuthColors.frost,
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      home: _booting
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _user == null
              ? LoginScreen(api: widget.api)
              : HomeScreen(api: widget.api, user: _user!),
    );
  }
}
