import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService();

  bool loading = false;
  String? error;

  List<Map<String, dynamic>> byNgo = [];

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      byNgo = await _service.byNgo();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
