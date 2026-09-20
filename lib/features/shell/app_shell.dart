import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/cubits/nav_cubit.dart';
import 'package:gearguard/features/archive/archive_page.dart';
import 'package:gearguard/features/attendance/attendance_page.dart';
import 'package:gearguard/features/dashboard/dashboard_page.dart';
import 'package:gearguard/features/employees/employees_page.dart';
import 'package:gearguard/features/scanner/scanner_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<NavCubit>().state;
    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          DashboardPage(),
          AttendancePage(),
          ScannerPage(),
          EmployeesPage(),
          ArchivePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) =>
            context.read<NavCubit>().go(AppTab.values[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available_rounded),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_strong_outlined),
            selectedIcon: Icon(Icons.center_focus_strong_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Archive',
          ),
        ],
      ),
    );
  }
}
