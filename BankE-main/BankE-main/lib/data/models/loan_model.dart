enum LoanStatus { pending, approved, rejected, active, closed }

class LoanModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String purpose;
  final int durationMonths;
  final String? pdfFileName; // nullable — backend may return null
  final String? fileUrl;     // full download URL constructed from base URL
  final LoanStatus status;
  final DateTime? appliedAt;
  final double? monthlyPayment;

  const LoanModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.purpose,
    required this.durationMonths,
    this.pdfFileName,
    this.fileUrl,
    this.status = LoanStatus.pending,
    this.appliedAt,
    this.monthlyPayment,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    // Backend returns 'pdfFileName' field (from LoanResponse DTO)
    final rawFile = json['pdfFileName'] as String?;
    return LoanModel(
      id: json['id'].toString(),
      userId: (json['userId'] ?? '').toString(),
      userName: json['userName'] ?? json['user']?['fullName'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      purpose: json['purpose'] ?? '',
      durationMonths: json['termMonths'] ?? 0,
      pdfFileName: rawFile,
      fileUrl: rawFile != null && rawFile.isNotEmpty
          ? '/api/loans/${json['id']}/download'
          : null,
      status: _mapStatus(json['status']?.toString() ?? 'Pending'),
      appliedAt: json['appliedAt'] != null
          ? DateTime.tryParse(json['appliedAt'])
          : null,
      monthlyPayment: json['monthlyPayment'] != null
          ? (json['monthlyPayment'] as num).toDouble()
          : null,
    );
  }

  LoanModel copyWith({LoanStatus? status}) {
    return LoanModel(
      id: id,
      userId: userId,
      userName: userName,
      amount: amount,
      purpose: purpose,
      durationMonths: durationMonths,
      pdfFileName: pdfFileName,
      fileUrl: fileUrl,
      status: status ?? this.status,
      appliedAt: appliedAt,
      monthlyPayment: monthlyPayment,
    );
  }

  static LoanStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return LoanStatus.approved;
      case 'rejected': return LoanStatus.rejected;
      case 'active': return LoanStatus.active;
      case 'closed': return LoanStatus.closed;
      default: return LoanStatus.pending;
    }
  }
}
