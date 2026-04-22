import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import '../providers/session_provider.dart';
import '../views/home/home.dart';
import '../views/students/students.dart';
import '../views/users/user_dashboard_page.dart';
import '../views/welcome.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access the dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SessionProvider, NavigationProvider>(
      builder: (context, session, navigation, _) {
        if (session.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = session.profile;
        if (!session.isAuthenticated || profile == null) {
          return const Welcome();
        }

        final pages = profile.isAdmin
            ? const [Home(), StudentsPage()]
            : const [UserDashboardPage()];
        final destinations = profile.isAdmin
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Batches',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_alt_rounded),
                  label: 'Students',
                ),
              ]
            : const [
                NavigationDestination(
                  icon: Icon(Icons.school_rounded),
                  label: 'My Learning',
                ),
              ];

        final selectedIndex = navigation.selectedIndex >= pages.length
            ? 0
            : navigation.selectedIndex;

        final showBottomNavigation = profile.isAdmin;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            toolbarHeight: 76,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            title: Text(
              profile.isAdmin ? 'RougeCodes Admin' : 'RougeCodes',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  final confirmed = await _confirmLogout(context);
                  if (!confirmed) {
                    return;
                  }
                  navigation.reset();
                  await session.logout();
                },
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(selectedIndex),
              child: pages[selectedIndex],
            ),
          ),
          bottomNavigationBar: showBottomNavigation
              ? NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: navigation.select,
                  destinations: destinations,
                )
              : null,
        );
      },
    );
  }
}
