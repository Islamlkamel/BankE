class AdminTransactionModel {
  final int id;
  final String senderName;
  final String receiverName;
  final double amount;
  final String transactionType;
  final String status;
  final String description;
  final DateTime createdAt;

  AdminTransactionModel({
    required this.id,
    required this.senderName,
    required this.receiverName,
    required this.amount,
    required this.transactionType,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  factory AdminTransactionModel.fromJson(Map<String, dynamic> json) {
    return AdminTransactionModel(
      id: json['id'] ?? 0,
      senderName: json['senderName'] ?? '',
      receiverName: json['receiverName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      transactionType: json['transactionType'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class AdminTransactionListModel {
  final List<AdminTransactionModel> transactions;
  final int totalCount;
  final int totalPages;
  final int currentPage;

  AdminTransactionListModel({
    required this.transactions,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
  });

  factory AdminTransactionListModel.fromJson(Map<String, dynamic> json) {
    var list = json['transactions'] as List? ?? [];
    List<AdminTransactionModel> transactionList = list.map((i) => AdminTransactionModel.fromJson(i)).toList();

    return AdminTransactionListModel(
      transactions: transactionList,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
    );
  }
}
