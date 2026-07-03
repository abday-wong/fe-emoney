import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/error/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deep_link_handler.dart';
import '../../../domain/usecases/auth/register_with_otp_usecase.dart';
import '../../../injection/injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/feature_icon.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String _name = '';
  String _email = '';
  String _pw = '';
  String _confirmPw = '';
  bool _showPw = false;
  bool _showConfirmPw = false;
  bool _agree = true;
  bool _loading = false;
  bool _gLoading = false;

  bool get _valid => _name.length > 1 && _email.contains('@') && _pw.length >= 6 && _confirmPw.isNotEmpty && _agree;

  Future<void> _loginWithGoogle() async {
    setState(() => _gLoading = true);
    try {
      debugPrint('[Auth] Google sign-in: memulai...');
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[Auth] Google sign-in: dibatalkan user');
        setState(() => _gLoading = false);
        return;
      }
      debugPrint('[Auth] Google sign-in: akun dipilih → ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('[Auth] Firebase sign-in OK → uid=${userCredential.user?.uid}');

      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null && mounted) {
        context.read<AuthBloc>().add(AuthLoginWithFirebase(idToken));
      }
    } catch (e) {
      debugPrint('[Auth] Google sign-in ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi Google gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _gLoading = false);
    }
  }

  Future<void> _register() async {
    if (_pw != _confirmPw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok.'), backgroundColor: AppColors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      // 1. Buat akun di Firebase
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _pw,
      );
      await credential.user?.updateDisplayName(_name);

      // 2. Ambil Firebase ID Token lalu kirim ke backend
      final idToken = await credential.user?.getIdToken();
      if (idToken == null) throw Exception('Gagal mendapatkan token Firebase');

      await sl<RegisterWithOtpUsecase>()(idToken);

      // 3. Backend sudah buat user + kirim OTP ke email → ke halaman verifikasi
      if (mounted) context.go('/verify-email');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registrasi gagal.'), backgroundColor: AppColors.red),
        );
      }
    } on ServerFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
        );
      }
    } on NetworkFailure catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada koneksi internet.'), backgroundColor: AppColors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthNeedsVerification) {
          if (state.user.totpEnabled) {
            context.go('/2fa/totp');
          } else {
            context.go('/2fa/smtp');
          }
        } else if (state is AuthAuthenticated) {
          if (DeepLinkHandler.pendingTrx != null) {
            context.go('/merchant');
          } else {
            context.go('/home');
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(DkgIcons.arrowLeft, color: AppColors.ink),
                  onPressed: () => context.go('/'),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 10, 26, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Buat akun',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -0.4,
                           )),
                      const SizedBox(height: 6),
                      const Text('Daftar gratis dalam 1 menit',
                          style: TextStyle(fontSize: 14.5, color: AppColors.slate500)),
                      const SizedBox(height: 22),
                      // Google sign in button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final loading = state is AuthLoading || _gLoading;
                          return GestureDetector(
                            onTap: loading ? null : _loginWithGoogle,
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line, width: 1.5),
                                boxShadow: AppColors.shadowSoft,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: loading
                                    ? const [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                          ),
                                        ),
                                        SizedBox(width: 11),
                                        Text('Menghubungkan…',
                                            style: TextStyle(
                                              fontFamily: 'PlusJakartaSans',
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                            )),
                                      ]
                                    : const [
                                        _GoogleIcon(),
                                        SizedBox(width: 11),
                                        Text('Daftar dengan Google',
                                            style: TextStyle(
                                              fontFamily: 'PlusJakartaSans',
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink,
                                            )),
                                      ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(children: [
                        const Expanded(child: Divider(color: AppColors.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Text('atau isi data manual',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate400,
                              )),
                        ),
                        const Expanded(child: Divider(color: AppColors.line)),
                      ]),
                      const SizedBox(height: 20),
                    AppField(
                      label: 'Nama lengkap',
                      value: _name,
                      onChanged: (v) => setState(() => _name = v),
                      placeholder: 'Nama Lengkap',
                      prefixIcon: const Icon(DkgIcons.user, size: 20),
                    ),
                    const SizedBox(height: 14),
                    AppField(
                      label: 'Email',
                      value: _email,
                      onChanged: (v) => setState(() => _email = v),
                      placeholder: 'nama@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(DkgIcons.mail, size: 20),
                    ),
                    const SizedBox(height: 14),
                    AppField(
                      label: 'Kata sandi',
                      value: _pw,
                      onChanged: (v) => setState(() => _pw = v),
                      obscureText: !_showPw,
                      placeholder: 'Min. 6 karakter',
                      prefixIcon: const Icon(DkgIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_showPw ? DkgIcons.eyeOff : DkgIcons.eye,
                            size: 20, color: AppColors.slate400),
                        onPressed: () => setState(() => _showPw = !_showPw),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppField(
                      label: 'Konfirmasi kata sandi',
                      value: _confirmPw,
                      onChanged: (v) => setState(() => _confirmPw = v),
                      obscureText: !_showConfirmPw,
                      placeholder: 'Ulangi kata sandi',
                      prefixIcon: const Icon(DkgIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirmPw ? DkgIcons.eyeOff : DkgIcons.eye,
                            size: 20, color: AppColors.slate400),
                        onPressed: () => setState(() => _showConfirmPw = !_showConfirmPw),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => setState(() => _agree = !_agree),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _agree ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: _agree ? AppColors.primary : AppColors.line,
                                width: 1.6,
                              ),
                            ),
                            child: _agree
                                ? const Icon(DkgIcons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 13,
                                  color: AppColors.slate500,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(text: 'Saya setuju dengan '),
                                  TextSpan(
                                    text: 'Syarat & Ketentuan',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: ' dan '),
                                  TextSpan(
                                    text: 'Kebijakan Privasi',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Daftar',
                      onPressed: _valid ? _register : null,
                      isLoading: _loading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah punya akun? ',
                            style: TextStyle(fontSize: 14, color: AppColors.ink)),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text('Masuk',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 21,
      height: 21,
      child: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.red),
      ),
    );
  }
}
