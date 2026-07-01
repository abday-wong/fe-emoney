import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_bloc_observer.dart';
import 'injection/injection_container.dart' as di;

import 'core/utils/deep_link_handler.dart';
import 'data/datasources/local/secure_storage_datasource.dart';
import 'injection/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = const AppBlocObserver();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize dependency injection
  await di.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const DompetKampusApp());
}

class DompetKampusApp extends StatefulWidget {
  const DompetKampusApp({super.key});

  @override
  State<DompetKampusApp> createState() => _DompetKampusAppState();
}

class _DompetKampusAppState extends State<DompetKampusApp> {
  @override
  void initState() {
    super.initState();
    // Initialize DeepLinkHandler
    DeepLinkHandler.init(
      onPaymentLinkReceived: (trx) async {
        final hasToken = await sl<SecureStorageDatasource>().getToken() != null;
        if (hasToken) {
          // If already logged in, navigate immediately to merchant checkout
          AppRouter.router.go('/merchant');
        } else {
          debugPrint('[DeepLink] User is not authenticated. Storing pending transaction.');
        }
      },
    );
  }

  @override
  void dispose() {
    DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dompet Kampus Global',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}

