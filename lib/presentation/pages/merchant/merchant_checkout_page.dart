import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deep_link_handler.dart';
import '../../blocs/account/account_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/otp_bloc.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/code_input.dart';
import '../../widgets/feature_icon.dart';

const _orange = Color(0xFFFF6A2B);

class MerchantCheckoutPage extends StatefulWidget {
  const MerchantCheckoutPage({super.key});

  @override
  State<MerchantCheckoutPage> createState() => _MerchantCheckoutPageState();
}

class _MerchantCheckoutPageState extends State<MerchantCheckoutPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isProcessing = false;
  bool _hasCodeError = false;

  @override
  void initState() {
    super.initState();
    context.read<AccountBloc>().add(AccountLoadRequested());
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    context.read<OtpBloc>().add(OtpSendEmail());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP dikirim ke email kamu', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _processPaymentRedirect(double amount, String recipient, String trxId, String callback) async {
    final callbackUri = Uri.parse(
      '$callback?status=success'
      '&trx_id=$trxId'
      '&amount=${amount.toInt()}'
      '&recipient_email=${Uri.encodeComponent(recipient)}'
    );

    debugPrint('[Checkout] Success callback redirect: $callbackUri');
    // Clear deep link state
    DeepLinkHandler.pendingTrx = null;

    try {
      await launchUrl(callbackUri, mode: LaunchMode.externalApplication);
      if (mounted) context.go('/home');
    } catch (e) {
      try {
        await launchUrl(callbackUri, mode: LaunchMode.platformDefault);
        if (mounted) context.go('/home');
      } catch (err) {
        debugPrint('[Checkout] Failed to launch callback: $err');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Redirect gagal. Buka: $callbackUri')),
          );
          context.go('/home');
        }
      }
    }
  }

  void _processPaymentCancelRedirect(String trxId, String callback, String errorMsg) async {
    final callbackUri = Uri.parse(
      '$callback?status=failed'
      '&trx_id=$trxId'
      '&error=${Uri.encodeComponent(errorMsg)}'
    );

    debugPrint('[Checkout] Failure callback redirect: $callbackUri');
    // Clear deep link state
    DeepLinkHandler.pendingTrx = null;

    try {
      await launchUrl(callbackUri, mode: LaunchMode.externalApplication);
      if (mounted) context.go('/home');
    } catch (e) {
      try {
        await launchUrl(callbackUri, mode: LaunchMode.platformDefault);
        if (mounted) context.go('/home');
      } catch (err) {
        debugPrint('[Checkout] Failed to launch callback: $err');
        if (mounted) context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trx = DeepLinkHandler.pendingTrx;

    if (trx == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FeatureIcon(icon: Icons.storefront_outlined, tone: 'orange', size: 80, iconSize: 40),
                const SizedBox(height: 20),
                const Text(
                  'Tidak Ada Pembayaran Aktif',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan lakukan transaksi dari aplikasi E-Commerce terlebih dahulu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.slate500),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Kembali Ke Beranda',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<OtpBloc, OtpState>(
          listener: (context, state) {
            if (state is OtpSent) {
              setState(() {
                _otpSent = true;
              });
            } else if (state is OtpError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.red),
              );
            }
          },
        ),
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentLoading) {
              setState(() => _isProcessing = true);
            } else if (state is PaymentTransferSuccess) {
              setState(() => _isProcessing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pembayaran Berhasil!'), backgroundColor: AppColors.green),
              );
              _processPaymentRedirect(trx.amount, trx.recipient, trx.trxId, trx.callback);
            } else if (state is PaymentInvalidOtp) {
              setState(() {
                _isProcessing = false;
                _hasCodeError = true;
                _otpController.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.red),
              );
            } else if (state is PaymentError) {
              setState(() => _isProcessing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.red),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          bool isTotp = false;
          if (authState is AuthAuthenticated) {
            isTotp = authState.user.totpEnabled;
          }

          return Scaffold(
            backgroundColor: AppColors.bg,
            body: BlocBuilder<AccountBloc, AccountState>(
              builder: (context, accountState) {
                double balance = 0.0;
                bool isLoadingAccount = accountState is AccountLoading || accountState is AccountInitial;

                if (accountState is AccountLoaded) {
                  balance = accountState.account.balance;
                }

                final isBalanceSufficient = balance >= trx.amount;

                return Column(
                  children: [
                    // TokoBelanja header
                    Container(
                      color: _orange,
                      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 6, 16, 14),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              _processPaymentCancelRedirect(trx.trxId, trx.callback, 'Payment cancelled by user.');
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Pembayaran Merchant',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_outlined, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  trx.recipient.split('@').first.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Details card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppColors.shadowSoft,
                                border: Border.all(color: AppColors.line2),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pesanan #${trx.trxId}',
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF1E9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 22, color: _orange)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'E-Commerce Payment',
                                              style: TextStyle(
                                                fontFamily: 'PlusJakartaSans',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            Text('Penerima: ${trx.recipient}',
                                                style: const TextStyle(fontSize: 12.5, color: AppColors.slate400)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24, color: AppColors.line2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Nominal',
                                          style: TextStyle(fontSize: 14, color: AppColors.slate500, fontFamily: 'PlusJakartaSans')),
                                      Text(
                                        CurrencyFormatter.format(trx.amount),
                                        style: const TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: _orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Wallet Balance check card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppColors.shadowSoft,
                                border: Border.all(color: AppColors.line2),
                              ),
                              child: Row(
                                children: [
                                  const AppLogo(size: 34),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Doran Pay',
                                            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                        isLoadingAccount
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                              )
                                            : Text(
                                                'Saldo: ${CurrencyFormatter.format(balance)}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isBalanceSufficient ? AppColors.green : AppColors.red,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (!isBalanceSufficient && !isLoadingAccount) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.red.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.error_outline, color: AppColors.red, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Saldo Anda tidak mencukupi untuk melakukan pembayaran ini.',
                                        style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                            if (isBalanceSufficient) ...[
                              // Security 2FA Verification section
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'Verifikasi Keamanan (2FA)',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate400,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: AppColors.shadowSoft,
                                  border: Border.all(color: AppColors.line2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isTotp) ...[
                                      const Text(
                                        'Masukkan Kode Google Authenticator:',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink),
                                      ),
                                      const SizedBox(height: 12),
                                      CodeInput(
                                        value: _otpController.text,
                                        onChanged: (v) => setState(() {
                                          _otpController.text = v;
                                          _hasCodeError = false;
                                        }),
                                        hasError: _hasCodeError,
                                      ),
                                    ] else ...[
                                      const Text(
                                        'Masukkan Kode OTP Email:',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CodeInput(
                                              value: _otpController.text,
                                              onChanged: (v) => setState(() {
                                                _otpController.text = v;
                                                _hasCodeError = false;
                                              }),
                                              hasError: _hasCodeError,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton(
                                            onPressed: _sendEmailOtp,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: Text(
                                              _otpSent ? 'Kirim Ulang' : 'Minta OTP',
                                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    // Pay action bar
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: AppColors.line2)),
                      ),
                      padding: EdgeInsets.fromLTRB(16, 12, 24, MediaQuery.of(context).padding.bottom + 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                      _processPaymentCancelRedirect(trx.trxId, trx.callback, 'Payment declined by user.');
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: AppColors.line),
                              ),
                              child: const Text('Batalkan', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Konfirmasi Bayar',
                              isLoading: _isProcessing,
                              onPressed: (isBalanceSufficient && _otpController.text.length == 6 && !_isProcessing)
                                  ? () {
                                      context.read<PaymentBloc>().add(PaymentTransferRequested(
                                            amount: trx.amount,
                                            description: 'Pembayaran E-Commerce #${trx.trxId}',
                                            otpCode: _otpController.text,
                                            otpType: isTotp ? AppConstants.otpTypeTotp : AppConstants.otpTypeEmail,
                                          ));
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
