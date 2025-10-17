import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  UserModel? _userProfile;
  String _appVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final supabaseService = context.read<SupabaseService>();
      final user = authService.currentUser;

      if (user != null) {
        final profile = await supabaseService.getUserProfile(user.id);
        if (mounted) {
          setState(() {
            _userProfile = profile;
          });
        }
      }

      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await context.read<AuthService>().signOut();
      // AuthWrapper akan menangani navigasi ke LoginPage
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (_userProfile != null)
                  _buildProfileSection(_userProfile!),

                const SizedBox(height: 24),

                _buildSettingsList(),

                const SizedBox(height: 40),

                Center(
                  child: Text(
                    _appVersion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileSection(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.name ?? 'Nama Belum Diatur',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSettingsList() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profil'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              //  Navigasi ke halaman edit profil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Halaman Edit Profil belum diimplementasikan.')),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifikasi'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
               //  Navigasi ke halaman pengaturan notifikasi
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengaturan Notifikasi belum diimplementasikan.')),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: _showLogoutConfirmationDialog,
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Keluar'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
            ),
          ],
        );
      },
    );
  }
}