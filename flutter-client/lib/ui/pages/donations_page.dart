import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../providers/donation_provider.dart';
import '../../providers/ngo_provider.dart';
import '../../models/donation.dart';

class DonationsPage extends StatelessWidget {
  const DonationsPage({super.key});

  static const statuses = ["pending", "completed", "failed", "refunded"];
  static const methods = ["cash", "card", "bank_transfer", "crypto"];
  static const currencies = ["USD", "EUR", "LBP"];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DonationProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Donations", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text("Create, filter, edit, delete donations. (Saved in MongoDB)"),
          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () => _showCreateDonationDialog(context),
            icon: const Icon(Icons.add),
            label: const Text("Add Donation"),
          ),

          const SizedBox(height: 12),

          // Filters card (status + method + recurring) + Apply/Clear
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                runSpacing: 12,
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("Filters", style: TextStyle(fontWeight: FontWeight.w600)),

                  _FilterDropdown(
                    label: "Status",
                    child: DropdownButton<String>(
                      value: p.statusFilter.isEmpty ? "__any__" : p.statusFilter,
                      items: [
                        const DropdownMenuItem(value: "__any__", child: Text("Any")),
                        ...statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        context.read<DonationProvider>().setStatus(v == "__any__" ? "" : v);
                      },
                    ),
                  ),

                  _FilterDropdown(
                    label: "Method",
                    child: DropdownButton<String>(
                      value: p.methodFilter.isEmpty ? "__any__" : p.methodFilter,
                      items: [
                        const DropdownMenuItem(value: "__any__", child: Text("Any")),
                        ...methods.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        context.read<DonationProvider>().setMethod(v == "__any__" ? "" : v);
                      },
                    ),
                  ),

                  _FilterDropdown(
                    label: "Recurring",
                    child: DropdownButton<String>(
                      value: p.recurringFilter == null
                          ? "__any__"
                          : (p.recurringFilter == true ? "yes" : "no"),
                      items: const [
                        DropdownMenuItem(value: "__any__", child: Text("(any)")),
                        DropdownMenuItem(value: "yes", child: Text("Yes (recurring)")),
                        DropdownMenuItem(value: "no", child: Text("No (one-time)")),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        context.read<DonationProvider>().setRecurring(
                              v == "__any__" ? null : (v == "yes"),
                            );
                      },
                    ),
                  ),

                  FilledButton(
                    onPressed: p.loading ? null : () => context.read<DonationProvider>().fetchPopulated(),
                    child: const Text("Apply"),
                  ),
                  OutlinedButton(
                    onPressed: p.loading ? null : () => context.read<DonationProvider>().clearFilters(),
                    child: const Text("Clear"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _DonationsTable(
                provider: p,
                onEdit: (d) => _showEditDonationDialog(context, d),
                onDelete: (d) => _confirmDelete(context, d),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- TABLE ACTIONS -----------------

  Future<void> _confirmDelete(BuildContext context, Donation d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Donation"),
        content: Text("Delete donation from '${d.donorName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (ok == true) {
      try {
        await context.read<DonationProvider>().delete(d.id);
        Fluttertoast.showToast(msg: "Deleted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Delete failed: $e");
      }
    }
  }

  // ----------------- CREATE MODAL (like website) -----------------
  Future<void> _showCreateDonationDialog(BuildContext context) async {
    final ngoProvider = context.read<NgoProvider>();
    if (ngoProvider.ngos.isEmpty && !ngoProvider.loading) {
      await ngoProvider.fetch();
    }

    final donorNameCtrl = TextEditingController();
    final donorEmailCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    final metaSourceCtrl = TextEditingController(text: "website");
    final metaPlatformCtrl = TextEditingController(text: "flutter");
    final metaNoteCtrl = TextEditingController();

    String currency = "USD";
    String method = "card";
    String status = "completed";
    bool isRecurring = false;

    String? ngoId = ngoProvider.ngos.isNotEmpty ? ngoProvider.ngos.first.id : null;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Create Donation"),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 650,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: donorNameCtrl, decoration: const InputDecoration(labelText: "Donor name")),
                  const SizedBox(height: 10),
                  TextField(controller: donorEmailCtrl, decoration: const InputDecoration(labelText: "Donor email")),
                  const SizedBox(height: 10),

                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount (max 100000)"),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: currency,
                    decoration: const InputDecoration(labelText: "Currency"),
                    items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => currency = v ?? currency),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: "Method"),
                    items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => method = v ?? method),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: "Status"),
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => status = v ?? status),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: isRecurring ? "yes" : "no",
                    decoration: const InputDecoration(labelText: "Recurring?"),
                    items: const [
                      DropdownMenuItem(value: "no", child: Text("No (one-time)")),
                      DropdownMenuItem(value: "yes", child: Text("Yes (monthly/recurring)")),
                    ],
                    onChanged: (v) => setState(() => isRecurring = (v == "yes")),
                  ),
                  const SizedBox(height: 10),

                  TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: "Tags (comma)")),
                  const SizedBox(height: 10),

                  TextField(controller: metaSourceCtrl, decoration: const InputDecoration(labelText: "Meta source")),
                  const SizedBox(height: 10),

                  TextField(controller: metaPlatformCtrl, decoration: const InputDecoration(labelText: "Meta platform")),
                  const SizedBox(height: 10),

                  TextField(controller: metaNoteCtrl, decoration: const InputDecoration(labelText: "Meta note")),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: ngoId,
                    decoration: const InputDecoration(labelText: "NGO"),
                    items: ngoProvider.ngos
                        .map((n) => DropdownMenuItem(value: n.id, child: Text("${n.name} (${n.category})")))
                        .toList(),
                    onChanged: (v) => setState(() => ngoId = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                donorNameCtrl.clear();
                donorEmailCtrl.clear();
                amountCtrl.clear();
                tagsCtrl.clear();
                metaNoteCtrl.clear();
                Fluttertoast.showToast(msg: "Reset");
              },
              child: const Text("Reset"),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
            FilledButton(
              onPressed: () async {
                try {
                  final amount = num.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (amount <= 0) {
                    Fluttertoast.showToast(msg: "Amount must be > 0");
                    return;
                  }
                  if (amount > 100000) {
                    Fluttertoast.showToast(msg: "Max amount is 100000");
                    return;
                  }
                  if (ngoId == null) {
                    Fluttertoast.showToast(msg: "Select an NGO");
                    return;
                  }

                  final tags = tagsCtrl.text
                      .split(",")
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  await context.read<DonationProvider>().create({
                    "donorName": donorNameCtrl.text.trim(),
                    "donorEmail": donorEmailCtrl.text.trim(),
                    "amount": amount,
                    "currency": currency,
                    "method": method,
                    "status": status,
                    "donationDate": DateTime.now().toIso8601String(),
                    "isRecurring": isRecurring,
                    "tags": tags,
                    "receiptUrls": [],
                    "meta": {
                      "source": metaSourceCtrl.text.trim(),
                      "platform": metaPlatformCtrl.text.trim(),
                      "note": metaNoteCtrl.text.trim(),
                    },
                    "allocation": [
                      {"sector": "general", "percentage": 100}
                    ],
                    "ngoId": ngoId,
                  });

                  Fluttertoast.showToast(msg: "Created");
                  Navigator.pop(ctx);
                } catch (e) {
                  Fluttertoast.showToast(msg: "Create failed: $e");
                }
              },
              child: const Text("Create Donation"),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- EDIT MODAL (like website) -----------------
  Future<void> _showEditDonationDialog(BuildContext context, Donation d) async {
    final amountCtrl = TextEditingController(text: d.amount.toString());
    final tagsCtrl = TextEditingController(text: "");
    final metaNoteCtrl = TextEditingController(text: "");

    String status = d.status;
    String method = d.method;
    bool isRecurring = d.isRecurring;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Edit Donation"),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: "Status"),
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => status = v ?? status),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount"),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: "Method"),
                    items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => method = v ?? method),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: isRecurring ? "yes" : "no",
                    decoration: const InputDecoration(labelText: "Recurring"),
                    items: const [
                      DropdownMenuItem(value: "no", child: Text("No (one-time)")),
                      DropdownMenuItem(value: "yes", child: Text("Yes (recurring)")),
                    ],
                    onChanged: (v) => setState(() => isRecurring = (v == "yes")),
                  ),
                  const SizedBox(height: 10),

                  TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: "Tags (comma)")),
                  const SizedBox(height: 10),

                  TextField(controller: metaNoteCtrl, decoration: const InputDecoration(labelText: "Meta note")),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            FilledButton(
              onPressed: () async {
                try {
                  final amount = num.tryParse(amountCtrl.text.trim()) ?? d.amount;

                  final tags = tagsCtrl.text
                      .split(",")
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  await context.read<DonationProvider>().update(d.id, {
                    "status": status,
                    "amount": amount,
                    "method": method,
                    "isRecurring": isRecurring,
                    if (tags.isNotEmpty) "tags": tags,
                    "meta": {
                      "note": metaNoteCtrl.text.trim(),
                    }
                  });

                  Fluttertoast.showToast(msg: "Saved");
                  Navigator.pop(ctx);
                } catch (e) {
                  Fluttertoast.showToast(msg: "Save failed: $e");
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationsTable extends StatelessWidget {
  final DonationProvider provider;
  final void Function(Donation d) onEdit;
  final void Function(Donation d) onDelete;

  const _DonationsTable({
    required this.provider,
    required this.onEdit,
    required this.onDelete,
  });

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

    final list = provider.donations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Donations List", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("No donations found."),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Donor")),
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Amount")),
                DataColumn(label: Text("Method")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Recurring")),
                DataColumn(label: Text("NGO")),
                DataColumn(label: Text("Actions")),
              ],
              rows: list.map((d) {
                final ngoName = d.ngo?["name"]?.toString() ?? d.ngoId;
                final dateStr = d.donationDate?.toIso8601String().split("T").first ?? "-";
                return DataRow(cells: [
                  DataCell(Text(dateStr)),
                  DataCell(Text(d.donorName)),
                  DataCell(Text(d.donorEmail)),
                  DataCell(Text("${d.amount} ${d.currency}")),
                  DataCell(Text(d.method)),
                  DataCell(Text(d.status)),
                  DataCell(Text(d.isRecurring ? "Yes" : "No")),
                  DataCell(Text(ngoName)),
                  DataCell(Row(
                    children: [
                      TextButton(onPressed: () => onEdit(d), child: const Text("Edit")),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => onDelete(d), child: const Text("Delete")),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterDropdown({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label: "),
        const SizedBox(width: 6),
        child,
      ],
    );
  }
}
