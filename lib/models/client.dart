class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String area;
  final String packageId;
  final String packageName;
  final DateTime connectionDate;
  final String status;
  final double totalBill;
  final double totalPaid;
  final double remaining;
  final DateTime createdAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.packageId,
    required this.packageName,
    required this.connectionDate,
    required this.status,
    required this.totalBill,
    required this.totalPaid,
    required this.remaining,
    required this.createdAt,
  });
}
