import 'package:absensi_ruangan/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/supabase_service.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => SupabaseService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<ImageService>(create: (_) => ImageService()),
      ],
      child: MaterialApp(
        title: 'AbsensiRuangan',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF2E4B9C),
            primary: Color(0xFF2E4B9C),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF2E4B9C),
            foregroundColor: Colors.white,
          ),
        ),
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final authState = snapshot.data!;
          if (authState.session != null) {
            return HomePage();
          }
        }
        return LoginPage();
      },
    );
  }
}