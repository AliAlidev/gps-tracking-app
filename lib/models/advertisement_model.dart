class AdvertisementModel {
  final int id;
  final String title;
  final String? description;
  final String? productImage;
  final String? qrCode;
  final int maxAgents;
  final int registeredAgentsCount;
  final double commissionPercentage;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;

  AdvertisementModel({
    required this.id,
    required this.title,
    this.description,
    this.productImage,
    this.qrCode,
    required this.maxAgents,
    required this.registeredAgentsCount,
    required this.commissionPercentage,
    this.validFrom,
    this.validUntil,
    required this.isActive,
  });

  int get remainingSlots => max(0, maxAgents - registeredAgentsCount);

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      productImage: json['product_image'] as String?,
      qrCode: json['qr_code'] as String?,
      maxAgents: json['max_agents'] as int? ?? 0,
      registeredAgentsCount: json['registered_agents_count'] as int? ?? 0,
      commissionPercentage: (json['commission_percentage'] as num?)?.toDouble() ?? 0.0,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'product_image': productImage,
      'qr_code': qrCode,
      'max_agents': maxAgents,
      'registered_agents_count': registeredAgentsCount,
      'commission_percentage': commissionPercentage,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

