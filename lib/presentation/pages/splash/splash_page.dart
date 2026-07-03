import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_logo.dart';
import '../../../core/utils/deep_link_handler.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _showLockScreen = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  Future<void> _authenticateBiometrics() async {
    if (_isAuthenticating) return;
    
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheck && !isSupported) {
        _proceedToApp();
        return;
      }
      
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _proceedToApp();
        return;
      }

      setState(() {
        _showLockScreen = true;
        _isAuthenticating = true;
      });

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari atau wajah Anda untuk membuka Doran Pay',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() {
        _isAuthenticating = false;
      });

      if (didAuthenticate) {
        _proceedToApp();
      }
    } catch (e) {
      debugPrint('[Biometrics] Error: $e');
      setState(() {
        _isAuthenticating = false;
        _showLockScreen = true;
      });
    }
  }

  void _proceedToApp() {
    if (DeepLinkHandler.pendingTrx != null) {
      context.go('/merchant');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _authenticateBiometrics();
        } else if (state is AuthUnauthenticated) {
          setState(() {
            _showLockScreen = false;
          });
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: _showLockScreen ? _buildLockScreen() : _buildWelcomeScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Stack(
      children: [
        // Decorative circles
        Positioned(
          top: -120,
          right: -90,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -100,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              const AppLogo(size: 92, light: true),
              const SizedBox(height: 26),
              const Text(
                'Doran',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'PAY',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bayar, transfer, dan kelola uang kuliah\ndalam satu aplikasi yang aman.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  AppButton(
                    label: 'Buat Akun Baru',
                    variant: AppButtonVariant.white,
                    onPressed: () => context.push('/register'),
                  ),
                  const SizedBox(height: 11),
                  AppButton(
                    label: 'Masuk ke Akun',
                    variant: AppButtonVariant.outlineWhite,
                    onPressed: () => context.push('/login'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const AppLogo(size: 80, light: true),
            const SizedBox(height: 48),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Center(
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aplikasi Terkunci',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifikasi sidik jari atau wajah Anda untuk mengakses akun Doran Pay Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: AppColors.slate600,
                height: 1.4,
              ),
            ),
            const Spacer(),
            Column(
              children: [
                AppButton(
                  label: 'Buka dengan Biometrik',
                  variant: AppButtonVariant.white,
                  onPressed: _authenticateBiometrics,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Keluar / Ganti Akun',
                  variant: AppButtonVariant.outlineWhite,
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
