import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home_dashboard/home_dashboard.dart';
import '../transactions/transactions_screen.dart';
import '../transfer/transfer_screen.dart';
import '../profile/profile_screen.dart';
import '../analytics/analytics_screen.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_state.dart';
import '../auth/login_screen.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/account_event.dart';
import '../../bloc/transaction_bloc.dart';
import '../../bloc/transaction_event.dart';
import '../../../core/constants/app_constants.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch data when MainNavigation starts (user is authenticated)
    context.read<AccountBloc>().add(const FetchAccountBalance(AppConstants.currentAccountId));
    context.read<TransactionBloc>().add(const FetchTransactions(AppConstants.currentAccountId));
  }

  final List<Widget> _screens = [
    const HomeDashboard(),
    const TransactionsScreen(),
    const TransferScreen(),
    const AnalyticsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is AuthSuccess && state.hasLocationWarning) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  '⚠️ Security Warning: Unrecognized Login Location Detected! Please review your recent activity.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ));
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: primaryColor,
                  unselectedItemColor: Colors.grey.shade400,
                  selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 11),
                  elevation: 0,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined, size: 26),
                      activeIcon: const Icon(Icons.home_rounded, size: 26),
                      label: AppLocalizations.of(context)!.home,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.receipt_long_outlined, size: 26),
                      activeIcon: const Icon(Icons.receipt_long_rounded, size: 26),
                      label: AppLocalizations.of(context)!.activity,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.swap_horizontal_circle_outlined, size: 30),
                      activeIcon: const Icon(Icons.swap_horizontal_circle_rounded, size: 30),
                      label: AppLocalizations.of(context)!.transfer,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.bar_chart_outlined, size: 26),
                      activeIcon: const Icon(Icons.bar_chart_rounded, size: 26),
                      label: AppLocalizations.of(context)!.insights,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline, size: 26),
                      activeIcon: const Icon(Icons.person_rounded, size: 26),
                      label: AppLocalizations.of(context)!.profile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
