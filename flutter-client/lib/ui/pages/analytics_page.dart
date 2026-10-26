import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_config.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/ngo_provider.dart';
import '../widgets/stat_card.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AnalyticsProvider>();
    final ngosP = context.watch<NgoProvider>();
    final dP = context.watch<DonationProvider>();

    final totalNgo = ngosP.ngos.length;
    final totalCount = dP.donations.length;
    final totalAmount = dP.donations.fold<num>(0, (sum, d) => sum + d.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Analytics", style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.parse("$baseUrl/donations/export/csv");
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.download),
                label: const Text("Export Donations CSV"),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: "Refresh",
                onPressed: () async {
                  await context.read<AnalyticsProvider>().fetch();
                  await context.read<NgoProvider>().fetch();
                  await context.read<DonationProvider>().fetchPopulated();
                },
                icon: const Icon(Icons.refresh),
              )
            ],
          ),

          const SizedBox(height: 12),

          // Stat cards (like website)
          Row(
            children: [
              Expanded(child: StatCard(title: "Total NGOs", value: "$totalNgo")),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: "Total Donations (count)", value: "$totalCount")),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: "Total Donations (amount)", value: totalAmount.toStringAsFixed(2))),
            ],
          ),

          const SizedBox(height: 16),
          Text("Donations by NGO", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _ByNgoTable(provider: a),
            ),
          ),
        ],
      ),
    );
  }
}

class _ByNgoTable extends StatelessWidget {
  final AnalyticsProvider provider;
  const _ByNgoTable({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text("Error: ${provider.error}", style: const TextStyle(color: Colors.red)),
      );
    }

    final rows = provider.byNgo;
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No analytics data."),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("NGO")),
          DataColumn(label: Text("Total Amount")),
          DataColumn(label: Text("Donations Count")),
        ],
        rows: rows.map((r) {
          final ngoName = (r["ngoName"] ?? r["name"] ?? "").toString();
          final total = (r["totalDonations"] ?? r["totalAmount"] ?? 0).toString();
          final count = (r["count"] ?? 0).toString();
          return DataRow(cells: [
            DataCell(Text(ngoName)),
            DataCell(Text(total)),
            DataCell(Text(count)),
          ]);
        }).toList(),
      ),
    );
  }
}
