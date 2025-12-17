class AgentModel {
  final int id;
  final int advertisementId;
  final int? userId;
  final String name;
  final String? email;
  final String? phone;
  final DateTime registrationDate;
  final String status;
  final int totalReferrals;
  final double commissionEarned;

  AgentModel({
    required this.id,
    required this.advertisementId,
    this.userId,
    required this.name,
    this.email,
    this.phone,
    required this.registrationDate,
    required this.status,
    required this.totalReferrals,
    required this.commissionEarned,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] as int,
      advertisementId: json['advertisement_id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      registrationDate: DateTime.parse(json['registration_date'] as String),
      status: json['status'] as String? ?? 'active',
      totalReferrals: json['total_referrals'] as int? ?? 0,
      commissionEarned: (json['commission_earned'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advertisement_id': advertisementId,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'registration_date': registrationDate.toIso8601String(),
      'status': status,
      'total_referrals': totalReferrals,
      'commission_earned': commissionEarned,
    };
  }
}

