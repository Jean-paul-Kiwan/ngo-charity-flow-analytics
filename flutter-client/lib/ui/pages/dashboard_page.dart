import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/donation_provider.dart';
import '../../providers/ngo_provider.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final donationsP = context.watch<DonationProvider>();
    final ngosP = context.watch<NgoProvider>();

    final donations = donationsP.donations;
    final ngosCount = ngosP.ngos.length;

    final totalCount = donations.length;

    // Total amount (sum of amounts)
    final totalAmount = donations.fold<num>(0, (sum, d) => sum + d.amount);

    // Recent donations (sort by date desc)
    final recent = [...donations]
      ..sort((a, b) {
        final da = a.donationDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.donationDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

    final recentTop = recent.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Dashboard", style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                tooltip: "Refresh",
                onPressed: () async {
                  await context.read<NgoProvider>().fetch();
                  await context.read<DonationProvider>().fetchPopulated();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards row (like website)
          Row(
            children: [
              Expanded(child: StatCard(title: "Total Donations (count)", value: "$totalCount")),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: "Total Donations (amount)", value: totalAmount.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: "NGOs", value: "$ngosCount")),
            ],
          ),

          const SizedBox(height: 16),
          Text("Recent Donations (with NGO)", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _RecentDonationsTable(
                loading: donationsP.loading,
                error: donationsP.error,
                rows: recentTop,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentDonationsTable extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<dynamic> rows; // Donation list

  const _RecentDonationsTable({
    required this.loading,
    required this.error,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text("Error: $error", style: const TextStyle(color: Colors.red)),
      );
    }

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No donations yet."),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Date")),
          DataColumn(label: Text("Donor")),
          DataColumn(label: Text("Amount")),
          DataColumn(label: Text("Method")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("NGO")),
        ],
        rows: rows.map((d) {
          final dateStr = d.donationDate?.toIso8601String().split("T").first ?? "-";
          final ngoName = d.ngo?["name"]?.toString() ?? d.ngoId;
          return DataRow(cells: [
            DataCell(Text(dateStr)),
            DataCell(Text(d.donorName)),
            DataCell(Text("${d.amount} ${d.currency}")),
            DataCell(Text(d.method)),
            DataCell(Text(d.status)),
            DataCell(Text(ngoName)),
          ]);
        }).toList(),
      ),
    );
  }
}
