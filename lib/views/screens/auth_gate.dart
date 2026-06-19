import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'seller_features/seller_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthProvider, bool>(
      (provider) => provider.isAuthenticated,
    );
    final isSeller = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isSeller ?? false,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isAuthenticated
          ? isSeller
              ? const SellerDashboardScreen(key: ValueKey('seller_home'))
              : const HomeScreen(key: ValueKey('home'))
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}
