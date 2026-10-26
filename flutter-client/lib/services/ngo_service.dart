import '../core/api_client.dart';
import '../models/ngo.dart';

class NgoService {
  Future<List<Ngo>> list({String? country, String? category, bool? isVerified, String? name}) async {
    final res = await ApiClient.dio.get("/ngos", queryParameters: {
      if (name != null && name.isNotEmpty) "name": name,
      if (country != null && country.isNotEmpty) "country": country,
      if (category != null && category.isNotEmpty) "category": category,
      if (isVerified != null) "isVerified": isVerified,
    });

    final data = res.data;
    final list = (data is List) ? data : (data["items"] ?? data["data"] ?? []);
    return (list as List).map((e) => Ngo.fromJson(e)).toList();
  }

  Future<Ngo> create(Map<String, dynamic> body) async {
    final res = await ApiClient.dio.post("/ngos", data: body);
    return Ngo.fromJson(res.data);
  }

  Future<Ngo> update(String id, Map<String, dynamic> body) async {
    final res = await ApiClient.dio.put("/ngos/$id", data: body);
    return Ngo.fromJson(res.data);
  }

  Future<void> delete(String id) async {
    await ApiClient.dio.delete("/ngos/$id");
  }
}
