
import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';
import 'pages/ngos_page.dart';
import 'pages/donations_page.dart';
import 'pages/analytics_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("NGO Charity Flow Analytics"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Dashboard"),
              Tab(text: "NGOs"),
              Tab(text: "Donations"),
              Tab(text: "Analytics"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DashboardPage(),
            NgosPage(),
            DonationsPage(),
            AnalyticsPage(),
          ],
        ),
      ),
    );
  }
}
