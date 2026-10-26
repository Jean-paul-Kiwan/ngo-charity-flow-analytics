import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/donation_service.dart';

class DonationProvider extends ChangeNotifier {
  final DonationService _service = DonationService();

  bool loading = false;
  String? error;

  List<Donation> donations = [];

  // Filters (match website)
  String statusFilter = "";   // "" => Any
  String methodFilter = "";   // "" => Any
  bool? recurringFilter;      // null => Any

  Future<void> fetchPopulated() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // Website shows NGO name in table, easiest is populated endpoint
      final list = await _service.populatedAll();

      donations = list.where((d) {
        final okStatus = statusFilter.isEmpty || d.status == statusFilter;
        final okMethod = methodFilter.isEmpty || d.method == methodFilter;
        final okRec = recurringFilter == null || d.isRecurring == recurringFilter;
        return okStatus && okMethod && okRec;
      }).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setStatus(String v) {
    statusFilter = v;
    notifyListeners();
  }

  void setMethod(String v) {
    methodFilter = v;
    notifyListeners();
  }

  void setRecurring(bool? v) {
    recurringFilter = v;
    notifyListeners();
  }

  Future<void> clearFilters() async {
    statusFilter = "";
    methodFilter = "";
    recurringFilter = null;
    await fetchPopulated();
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _service.create(body);
    await fetchPopulated();
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await _service.update(id, body);
    await fetchPopulated();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await fetchPopulated();
  }
}
