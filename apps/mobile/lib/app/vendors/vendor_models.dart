import '../core/json_value.dart';

class VendorServiceModel {
  const VendorServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.pricingModel,
  });

  final String id;
  final String name;
  final String description;
  final String basePrice;
  final String pricingModel;

  factory VendorServiceModel.fromJson(Map<String, dynamic> json) {
    return VendorServiceModel(
      id: stringValue(json['id']),
      name: stringValue(json['name']),
      description: stringValue(json['description']),
      basePrice: stringValue(json['basePrice']),
      pricingModel: stringValue(json['pricingModel']),
    );
  }
}

class VendorPackageModel {
  const VendorPackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  final String id;
  final String name;
  final String description;
  final String price;

  factory VendorPackageModel.fromJson(Map<String, dynamic> json) {
    return VendorPackageModel(
      id: stringValue(json['id']),
      name: stringValue(json['name']),
      description: stringValue(json['description']),
      price: stringValue(json['price']),
    );
  }
}

class VendorBookingPreferenceModel {
  const VendorBookingPreferenceModel({
    required this.allowDirectBooking,
    required this.allowRequestBooking,
  });

  final bool allowDirectBooking;
  final bool allowRequestBooking;

  factory VendorBookingPreferenceModel.fromJson(Map<String, dynamic> json) {
    return VendorBookingPreferenceModel(
      allowDirectBooking: boolValue(json['allowDirectBooking']),
      allowRequestBooking: boolValue(
        json['allowRequestBooking'],
        fallback: true,
      ),
    );
  }
}

class VendorProfileModel {
  const VendorProfileModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    required this.category,
    required this.serviceArea,
    required this.verified,
    required this.ratingAverage,
    required this.services,
    required this.packages,
    required this.bookingPreference,
  });

  final String id;
  final String userId;
  final String businessName;
  final String description;
  final String category;
  final String serviceArea;
  final bool verified;
  final String ratingAverage;
  final List<VendorServiceModel> services;
  final List<VendorPackageModel> packages;
  final VendorBookingPreferenceModel? bookingPreference;

  factory VendorProfileModel.fromJson(Map<String, dynamic> json) {
    return VendorProfileModel(
      id: stringValue(json['id']),
      userId: stringValue(json['userId']),
      businessName: stringValue(json['businessName']),
      description: stringValue(json['description']),
      category: stringValue(json['category']),
      serviceArea: stringValue(json['serviceArea']),
      verified: boolValue(json['verified']),
      ratingAverage: stringValue(json['ratingAverage'], fallback: '0.00'),
      services: (json['services'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) => VendorServiceModel.fromJson(Map<String, dynamic>.from(entry)))
          .toList(growable: false),
      packages: (json['packages'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) => VendorPackageModel.fromJson(Map<String, dynamic>.from(entry)))
          .toList(growable: false),
      bookingPreference: json['bookingPreference'] == null
          ? null
          : VendorBookingPreferenceModel.fromJson(
              Map<String, dynamic>.from(json['bookingPreference'] as Map),
            ),
    );
  }
}

class VendorRequestEventSummaryModel {
  const VendorRequestEventSummaryModel({
    required this.id,
    required this.title,
    required this.city,
    required this.venue,
    required this.startAt,
    required this.endAt,
  });

  final String id;
  final String title;
  final String city;
  final String venue;
  final DateTime startAt;
  final DateTime endAt;

  factory VendorRequestEventSummaryModel.fromJson(Map<String, dynamic> json) {
    return VendorRequestEventSummaryModel(
      id: stringValue(json['id']),
      title: stringValue(json['title']),
      city: stringValue(json['city']),
      venue: stringValue(json['venue']),
      startAt: DateTime.parse(stringValue(json['startAt'])).toLocal(),
      endAt: DateTime.parse(stringValue(json['endAt'])).toLocal(),
    );
  }
}

class VendorRequestVendorSummaryModel {
  const VendorRequestVendorSummaryModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.category,
    required this.serviceArea,
    required this.verified,
  });

  final String id;
  final String userId;
  final String businessName;
  final String category;
  final String serviceArea;
  final bool verified;

  factory VendorRequestVendorSummaryModel.fromJson(Map<String, dynamic> json) {
    return VendorRequestVendorSummaryModel(
      id: stringValue(json['id']),
      userId: stringValue(json['userId']),
      businessName: stringValue(json['businessName']),
      category: stringValue(json['category']),
      serviceArea: stringValue(json['serviceArea']),
      verified: boolValue(json['verified']),
    );
  }
}

class VendorRequestModel {
  const VendorRequestModel({
    required this.id,
    required this.event,
    required this.organizerId,
    required this.vendor,
    required this.status,
    required this.message,
    required this.proposedBudget,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final VendorRequestEventSummaryModel event;
  final String organizerId;
  final VendorRequestVendorSummaryModel vendor;
  final String status;
  final String message;
  final String proposedBudget;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory VendorRequestModel.fromJson(Map<String, dynamic> json) {
    return VendorRequestModel(
      id: stringValue(json['id']),
      event: VendorRequestEventSummaryModel.fromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      organizerId: stringValue(json['organizerId']),
      vendor: VendorRequestVendorSummaryModel.fromJson(
        Map<String, dynamic>.from(json['vendor'] as Map),
      ),
      status: stringValue(json['status']),
      message: stringValue(json['message']),
      proposedBudget: stringValue(json['proposedBudget']),
      createdAt: DateTime.parse(stringValue(json['createdAt'])).toLocal(),
      updatedAt: DateTime.parse(stringValue(json['updatedAt'])).toLocal(),
    );
  }
}

class VendorProfileUpsertRequest {
  const VendorProfileUpsertRequest({
    required this.businessName,
    required this.description,
    required this.category,
    required this.serviceArea,
    required this.allowDirectBooking,
    required this.allowRequestBooking,
  });

  final String businessName;
  final String description;
  final String category;
  final String serviceArea;
  final bool allowDirectBooking;
  final bool allowRequestBooking;

  Map<String, dynamic> get profileJson => {
        'businessName': businessName,
        'description': description,
        'category': category,
        'serviceArea': serviceArea,
      };

  Map<String, dynamic> get bookingPreferenceJson => {
        'allowDirectBooking': allowDirectBooking,
        'allowRequestBooking': allowRequestBooking,
      };
}

class VendorServiceCreateRequest {
  const VendorServiceCreateRequest({
    required this.name,
    required this.description,
    required this.basePrice,
    required this.pricingModel,
  });

  final String name;
  final String description;
  final String basePrice;
  final String pricingModel;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'pricingModel': pricingModel,
    };
  }
}

class VendorPackageCreateRequest {
  const VendorPackageCreateRequest({
    required this.name,
    required this.description,
    required this.price,
  });

  final String name;
  final String description;
  final String price;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
    };
  }
}

class VendorRequestCreateRequest {
  const VendorRequestCreateRequest({
    required this.eventId,
    required this.message,
    required this.proposedBudget,
    required this.directBookingPreferred,
  });

  final String eventId;
  final String message;
  final String proposedBudget;
  final bool directBookingPreferred;

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'message': message,
      'proposedBudget': proposedBudget,
      'directBookingPreferred': directBookingPreferred,
    };
  }
}
