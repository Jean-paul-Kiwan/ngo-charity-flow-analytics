import 'package:flutter/material.dart';
import '../models/ngo.dart';
import '../services/ngo_service.dart';

class NgoProvider extends ChangeNotifier {
  final NgoService _service = NgoService();

  bool loading = false;
  String? error;

  List<Ngo> ngos = [];

  // Filters (match website: category + verified)
  String categoryFilter = ""; // "" means Any
  bool? verifiedFilter; // null means Any

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      ngos = await _service.list(
        category: categoryFilter.isEmpty ? null : categoryFilter,
        isVerified: verifiedFilter,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setCategory(String value) {
    categoryFilter = value;
    notifyListeners();
  }

  void setVerified(bool? value) {
    verifiedFilter = value;
    notifyListeners();
  }

  Future<void> clearFilters() async {
    categoryFilter = "";
    verifiedFilter = null;
    await fetch();
  }

  Future<void> createQuickNgo({required String category}) async {
    // Website UI shows only a category dropdown + "Create NGO" button.
    // But API requires name/country/... so we create a sensible default.
    final now = DateTime.now().millisecondsSinceEpoch;

    await _service.create({
      "name": "New NGO $now",
      "country": "Lebanon",
      "category": category,
      "isVerified": false,
      "foundedAt": "1990-01-01",
      "tags": ["auto-created"],
      "contact": {"email": "demo4@example.invalid", "phone": "+961000000"},
    });

    await fetch();
  }

  Future<void> updateNgo(String id, Map<String, dynamic> body) async {
    await _service.update(id, body);
    await fetch();
  }

  Future<void> deleteNgo(String id) async {
    await _service.delete(id);
    await fetch();
  }
}
