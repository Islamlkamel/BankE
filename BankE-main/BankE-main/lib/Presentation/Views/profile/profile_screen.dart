import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/login_screen.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/account_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../bloc/language/language_bloc.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../support/support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          title: Text(AppLocalizations.of(context)!.profile, style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 20),
              _buildOptionsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state is AccountLoading) {
            return const AppLoadingView();
          } else if (state is AccountLoaded) {
            return Column(
              children: [
                GestureDetector(
                  onTap: () => _handleProfilePictureUpdate(context),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Theme.of(context).primaryColor),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  state.account.accountHolderName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Account: ${state.account.id}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            );
          } else if (state is AccountError) {
            return AppErrorView(message: state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOptionsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildOptionTile(
            context,
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Password, FaceID, Biometrics',
            onTap: () {},
          ),
          _buildOptionTile(
            context,
            icon: Icons.language,
            title: AppLocalizations.of(context)!.language,
            subtitle: 'English / العربية',
            onTap: () {
              final currentLanguage = context.read<LanguageBloc>().state.locale.languageCode;
              if (currentLanguage == 'ar') {
                context.read<LanguageBloc>().add(ChangeLanguageEvent('en'));
              } else {
                context.read<LanguageBloc>().add(ChangeLanguageEvent('ar'));
              }
            },
          ),
          _buildOptionTile(
            context,
            icon: Icons.settings,
            title: AppLocalizations.of(context)!.settings,
            subtitle: 'Dark / Light Theme (Tap to toggle)',
            onTap: () {
              final currentTheme = context.read<ThemeBloc>().state.themeMode;
              final nextTheme = currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              context.read<ThemeBloc>().add(ChangeThemeEvent(nextTheme));
            },
          ),
          _buildOptionTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQ, Contact Us, Live Chat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ElevatedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutEvent());
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.logout, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor),
        ),

        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Theme.of(context).textTheme.titleLarge?.color
          )
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  void _handleProfilePictureUpdate(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Camera Permission'),
          content: const Text('Contro Bank needs access to your camera to capture and upload a new profile picture. Do you allow access?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Deny', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close permission dialog
                _simulateFileUpload(context);
              },
              child: const Text('Allow & Upload'),
            ),
          ],
        );
      },
    );
  }

  void _simulateFileUpload(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture successfully uploaded!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}
