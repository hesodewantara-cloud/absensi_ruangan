import 'package:absensi_ruangan/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'services/supabase_service.dart';
import 'services/location_service.dart';
import 'services/auth_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<SupabaseService>(create: (_) => SupabaseService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<ImageService>(create: (_) => ImageService()),
      ],
      child: MaterialApp(
        title: 'AbsensiRuangan',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E4B9C),
            primary: const Color(0xFF2E4B9C),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2E4B9C),
            foregroundColor: Colors.white,
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Cek jika stream memiliki data dan sesi tidak null
        if (snapshot.hasData && snapshot.data!.session != null) {
          // Jika user sudah login, tampilkan halaman utama
          return const MainPage();
        }
        // Jika tidak, tampilkan halaman login
        return const LoginPage();
      },
    );
  }
}