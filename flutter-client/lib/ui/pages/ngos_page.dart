import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../providers/ngo_provider.dart';
import '../../models/ngo.dart';

class NgosPage extends StatefulWidget {
  const NgosPage({super.key});

  @override
  State<NgosPage> createState() => _NgosPageState();
}

class _NgosPageState extends State<NgosPage> {
  static const categories = [
    "health",
    "education",
    "food",
    "shelter",
    "environment",
    "emergency",
  ];

  String createCategory = "health";

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NgoProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("NGOs", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),

          // ✅ Create NGO section (category dropdown + Create NGO button)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                runSpacing: 12,
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("Create NGO", style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    value: createCategory,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => createCategory = v);
                    },
                  ),
                  FilledButton(
                    onPressed: p.loading
                        ? null
                        : () async {
                            try {
                              await context.read<NgoProvider>().createQuickNgo(category: createCategory);
                              Fluttertoast.showToast(msg: "NGO created");
                            } catch (e) {
                              Fluttertoast.showToast(msg: "Create failed: $e");
                            }
                          },
                    child: const Text("Create NGO"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Filters section (Category + Verified + Apply/Clear)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                runSpacing: 12,
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("Search / Filters", style: TextStyle(fontWeight: FontWeight.w600)),

                  // Category filter (Any + categories)
                  _FilterDropdown(
                    label: "Category",
                    child: DropdownButton<String>(
                      value: p.categoryFilter.isEmpty ? "__any__" : p.categoryFilter,
                      items: [
                        const DropdownMenuItem(value: "__any__", child: Text("(Any)")),
                        ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        context.read<NgoProvider>().setCategory(v == "__any__" ? "" : v);
                      },
                    ),
                  ),

                  // Verified filter (any/true/false)
                  _FilterDropdown(
                    label: "Verified",
                    child: DropdownButton<String>(
                      value: p.verifiedFilter == null
                          ? "__any__"
                          : (p.verifiedFilter == true ? "true" : "false"),
                      items: const [
                        DropdownMenuItem(value: "__any__", child: Text("(any)")),
                        DropdownMenuItem(value: "true", child: Text("true")),
                        DropdownMenuItem(value: "false", child: Text("false")),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        context.read<NgoProvider>().setVerified(
                              v == "__any__" ? null : (v == "true"),
                            );
                      },
                    ),
                  ),

                  FilledButton(
                    onPressed: p.loading
                        ? null
                        : () async {
                            await context.read<NgoProvider>().fetch();
                          },
                    child: const Text("Apply"),
                  ),
                  OutlinedButton(
                    onPressed: p.loading
                        ? null
                        : () async {
                            await context.read<NgoProvider>().clearFilters();
                          },
                    child: const Text("Clear"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ NGO List table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _NgoListBlock(provider: p),
            ),
          ),
        ],
      ),
    );
  }
}

class _NgoListBlock extends StatelessWidget {
  final NgoProvider provider;
  const _NgoListBlock({required this.provider});

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

    final ngos = provider.ngos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("NGO List", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        if (ngos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("No NGOs found."),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Country")),
                DataColumn(label: Text("Category")),
                DataColumn(label: Text("Verified")),
                DataColumn(label: Text("Actions")),
              ],
              rows: ngos.map((n) {
                return DataRow(
                  cells: [
                    DataCell(Text(n.name)),
                    DataCell(Text(n.country)),
                    DataCell(Text(n.category)),
                    DataCell(Text(n.isVerified ? "true" : "false")),
                    DataCell(
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _showEditNgoDialog(context, n),
                            child: const Text("Edit"),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _confirmDelete(context, n),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Ngo ngo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete NGO"),
        content: Text("Delete '${ngo.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (ok == true) {
      try {
        await context.read<NgoProvider>().deleteNgo(ngo.id);
        Fluttertoast.showToast(msg: "Deleted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Delete failed: $e");
      }
    }
  }

  Future<void> _showEditNgoDialog(BuildContext context, Ngo ngo) async {
    final nameCtrl = TextEditingController(text: ngo.name);
    final countryCtrl = TextEditingController(text: ngo.country);

    String category = ngo.category;
    bool verified = ngo.isVerified;

    // Website dialog contains extra fields (tags/contact).
    // Your Ngo model doesn’t include them, but backend supports them.
    final tagsCtrl = TextEditingController(text: "");
    final emailCtrl = TextEditingController(text: "");
    final phoneCtrl = TextEditingController(text: "");

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Edit NGO"),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: countryCtrl,
                    decoration: const InputDecoration(labelText: "Country"),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: const [
                      DropdownMenuItem(value: "health", child: Text("health")),
                      DropdownMenuItem(value: "education", child: Text("education")),
                      DropdownMenuItem(value: "food", child: Text("food")),
                      DropdownMenuItem(value: "shelter", child: Text("shelter")),
                      DropdownMenuItem(value: "environment", child: Text("environment")),
                      DropdownMenuItem(value: "emergency", child: Text("emergency")),
                    ],
                    onChanged: (v) => setState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: verified ? "true" : "false",
                    decoration: const InputDecoration(labelText: "Verified"),
                    items: const [
                      DropdownMenuItem(value: "true", child: Text("true")),
                      DropdownMenuItem(value: "false", child: Text("false")),
                    ],
                    onChanged: (v) => setState(() => verified = (v == "true")),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: tagsCtrl,
                    decoration: const InputDecoration(labelText: "Tags (comma separated)"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Contact email"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: "Contact phone"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            FilledButton(
              onPressed: () async {
                try {
                  final tags = tagsCtrl.text
                      .split(",")
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  await context.read<NgoProvider>().updateNgo(ngo.id, {
                    "name": nameCtrl.text.trim(),
                    "country": countryCtrl.text.trim(),
                    "category": category,
                    "isVerified": verified,
                    if (tags.isNotEmpty) "tags": tags,
                    "contact": {
                      if (emailCtrl.text.trim().isNotEmpty) "email": emailCtrl.text.trim(),
                      if (phoneCtrl.text.trim().isNotEmpty) "phone": phoneCtrl.text.trim(),
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
