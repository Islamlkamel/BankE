class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double balance;
  final bool isBlocked;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.balance,
    required this.isBlocked,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'].toString(),
      name: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phoneNumber'] ?? '',
      balance: 0.0,
      isBlocked: !(json['isActive'] ?? true),
    );
  }

  AdminUserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    double? balance,
    bool? isBlocked,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
