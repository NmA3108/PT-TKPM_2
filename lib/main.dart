import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/providers/auth_provider.dart';
import 'controllers/providers/cart_provider.dart';
import 'services/auth_service.dart';
import 'services/product_detail_service.dart';
import 'views/screens/auth_gate.dart';
import 'views/screens/account_settings_screen.dart';
import 'views/screens/cart_screen.dart';
import 'views/screens/chatbot_screen.dart';
import 'views/screens/filter_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/order_tracking_screen.dart';

const realtimeDatabaseUrl =
    'https://tmdt-e5958-default-rtdb.asia-southeast1.firebasedatabase.app/';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: realtimeDatabaseUrl,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(ProductDetailService()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB);
    const secondary = Color(0xFF14B8A6);
    const background = Color(0xFFF5F7FB);
    const surface = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF111827);
    const textSecondary = Color(0xFF6B7280);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TMDT',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: background,
          foregroundColor: textPrimary,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
          prefixIconColor: textSecondary,
          suffixIconColor: textSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: textPrimary,
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF3F4F6),
          selectedColor: primary.withOpacity(0.14),
          labelStyle: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
          headlineSmall: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.18,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          titleSmall: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
          bodySmall: TextStyle(
            color: textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
          labelLarge: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          labelMedium: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/category': (context) => const FilterScreen(),
        '/cart': (context) => const CartScreen(),
        '/me': (context) => const AccountSettingsScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/order-tracking': (context) => const OrderTrackingScreen(),
      },
      home: const AuthGate(),
    );
  }
}
