class Donation {
  final String id;
  final String donorName;
  final String donorEmail;
  final num amount;
  final String currency;
  final String method;
  final String status;
  final bool isRecurring;
  final DateTime? donationDate;
  final String ngoId;

  // Populated NGO (optional)
  final Map<String, dynamic>? ngo;

  Donation({
    required this.id,
    required this.donorName,
    required this.donorEmail,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.isRecurring,
    required this.ngoId,
    this.donationDate,
    this.ngo,
  });

  factory Donation.fromJson(Map<String, dynamic> j) => Donation(
        id: (j["_id"] ?? j["id"]).toString(),
        donorName: (j["donorName"] ?? "").toString(),
        donorEmail: (j["donorEmail"] ?? "").toString(),
        amount: j["amount"] ?? 0,
        currency: (j["currency"] ?? "USD").toString(),
        method: (j["method"] ?? "").toString(),
        status: (j["status"] ?? "").toString(),
        isRecurring: (j["isRecurring"] ?? j["recurring"] ?? false) == true,
        ngoId: (j["ngoId"] is Map)
            ? (j["ngoId"]["_id"] ?? "").toString()
            : (j["ngoId"] ?? "").toString(),
        donationDate: (j["donationDate"] != null)
            ? DateTime.tryParse(j["donationDate"].toString())
            : null,
        ngo: (j["ngoId"] is Map) ? (j["ngoId"] as Map).cast<String, dynamic>() : null,
      );
}
