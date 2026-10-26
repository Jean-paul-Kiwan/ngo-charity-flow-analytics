import '../core/api_client.dart';

class AnalyticsService {
  Future<List<Map<String, dynamic>>> byNgo() async {
    final res = await ApiClient.dio.get("/donations/analytics/by-ngo");
    final data = res.data;
    final list = (data is List) ? data : (data["data"] ?? []);
    return (list as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<List<Map<String, dynamic>>> aggregateJoin() async {
    final res = await ApiClient.dio.get("/donations/aggregate/join");
    final data = res.data;
    final list = (data is List) ? data : (data["data"] ?? []);
    return (list as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }
}
