import '../core/api_client.dart';
import '../models/donation.dart';

class DonationService {
  Future<List<Donation>> list({
    String? status,
    String? method,
    String? ngoId,
    num? minAmount,
    num? maxAmount,
    String? tag,
    bool? isRecurring,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await ApiClient.dio.get("/donations", queryParameters: {
      if (status != null && status.isNotEmpty) "status": status,
      if (method != null && method.isNotEmpty) "method": method,
      if (ngoId != null && ngoId.isNotEmpty) "ngoId": ngoId,
      if (minAmount != null) "minAmount": minAmount,
      if (maxAmount != null) "maxAmount": maxAmount,
      if (tag != null && tag.isNotEmpty) "tag": tag,
      if (isRecurring != null) "isRecurring": isRecurring,
      if (from != null) "from": from.toIso8601String(),
      if (to != null) "to": to.toIso8601String(),
    });

    final data = res.data;
    final list = (data is List) ? data : (data["items"] ?? data["data"] ?? []);
    return (list as List).map((e) => Donation.fromJson(e)).toList();
  }

  Future<List<Donation>> populatedAll() async {
    final res = await ApiClient.dio.get("/donations/populated/all");
    final data = res.data;
    final list = (data is List) ? data : (data["items"] ?? data["data"] ?? []);
    return (list as List).map((e) => Donation.fromJson(e)).toList();
  }

  Future<Donation> create(Map<String, dynamic> body) async {
    final res = await ApiClient.dio.post("/donations", data: body);
    return Donation.fromJson(res.data);
  }

  Future<Donation> update(String id, Map<String, dynamic> body) async {
    final res = await ApiClient.dio.put("/donations/$id", data: body);
    return Donation.fromJson(res.data);
  }

  Future<void> delete(String id) async {
    await ApiClient.dio.delete("/donations/$id");
  }
}
