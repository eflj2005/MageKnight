import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/pantalla_juego.dart';

/// Punto de entrada de la aplicación Mage Knight Flutter.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación forzada a horizontal para mejor experiencia del mapa
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Pantalla completa inmersiva (ocultar barra de estado y navegación)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MageKnightApp());
}

/// Widget raíz de la aplicación.
class MageKnightApp extends StatelessWidget {
  const MageKnightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mage Knight',
      debugShowCheckedModeBanner: false,

      // Tema oscuro medieval
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B1FA2),       // Púrpura mágico
          secondary: Color(0xFFFFD700),     // Dorado medieval
          surface: Color(0xFF1B0035),       // Fondo de cards
          error: Color(0xFFB71C1C),         // Rojo combate
        ),
        textTheme: GoogleFonts.cinzelTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF12002B),
          titleTextStyle: GoogleFonts.cinzel(
            color: const Color(0xFFFFD700),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1B2838),
          contentTextStyle: GoogleFonts.cinzel(color: Colors.white),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF4A148C),
          labelStyle: GoogleFonts.cinzel(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
        ),
      ),

      // Pantalla inicial: mapa del juego
      home: const PantallaJuego(),
    );
  }
}

