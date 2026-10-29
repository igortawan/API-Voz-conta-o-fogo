// ============================================================================
// splash_page.dart — migrado para Django JWT (sem Firebase Auth / Firestore)
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/firebase/fcm_service.dart';
import '../../services/api/websocket_service.dart';
import '../admin/presentation/pages/admin_page.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import '../authority/presentation/pages/authority_page.dart';
import '../navigation_page.dart';
import '../presentation/pages/auth/login.page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    try {
      await FcmService.init();
    } catch (_) {}

    // Tenta restaurar sessão JWT existente
    final authCtrl = ref.read(authControllerProvider.notifier);
    final user = await authCtrl.restoreSession();
    if (!mounted) return;

    if (user != null) {
      // Conecta WebSocket agora que temos token válido
      WebSocketService.connect();
    }

    Widget destination = const LoginPage();
    if (user != null) {
      destination = _pageForRole(user.role);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Widget _pageForRole(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return const AdminPage();
      case AppConstants.roleAuthority:
        return const AuthorityPage();
      default:
        return const NavigationPage();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Voz Contra o Fogo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Protegendo a Caatinga piauiense',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'IFPI — Campus Paulistana',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
