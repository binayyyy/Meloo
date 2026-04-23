import '../core/json_value.dart';

class EventCategoryModel {
  const EventCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory EventCategoryModel.fromJson(Map<String, dynamic> json) {
    return EventCategoryModel(
      id: stringValue(json['id']),
      name: stringValue(json['name']),
      slug: stringValue(json['slug']),
    );
  }
}

class EventModel {
  const EventModel({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.category,
    required this.venue,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.vendorMatchRadiusKm,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.visibility,
    required this.coverImageUrl,
  });

  final String id;
  final String organizerId;
  final String title;
  final String description;
  final EventCategoryModel category;
  final String venue;
  final String city;
  final double? latitude;
  final double? longitude;
  final double? vendorMatchRadiusKm;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String visibility;
  final String? coverImageUrl;

  bool get isPubliclyVisible => status == 'published' && visibility == 'public';

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: stringValue(json['id']),
      organizerId: stringValue(json['organizerId']),
      title: stringValue(json['title']),
      description: stringValue(json['description']),
      category: EventCategoryModel.fromJson(
        Map<String, dynamic>.from(json['category'] as Map),
      ),
      venue: stringValue(json['venue']),
      city: stringValue(json['city']),
      latitude: nullableDoubleValue(json['latitude']),
      longitude: nullableDoubleValue(json['longitude']),
      vendorMatchRadiusKm: nullableDoubleValue(json['vendorMatchRadiusKm']),
      startAt: DateTime.parse(stringValue(json['startAt'])).toLocal(),
      endAt: DateTime.parse(stringValue(json['endAt'])).toLocal(),
      status: stringValue(json['status']),
      visibility: stringValue(json['visibility']),
      coverImageUrl: nullableStringValue(json['coverImageUrl']),
    );
  }
}

class TicketTypeModel {
  const TicketTypeModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.remaining,
    required this.saleStartAt,
    required this.saleEndAt,
  });

  final String id;
  final String eventId;
  final String name;
  final String price;
  final int quantity;
  final int remaining;
  final DateTime saleStartAt;
  final DateTime saleEndAt;

  bool get isFree => double.tryParse(price) == 0;

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      id: stringValue(json['id']),
      eventId: stringValue(json['eventId']),
      name: stringValue(json['name']),
      price: stringValue(json['price']),
      quantity: intValue(json['quantity']),
      remaining: intValue(json['remaining']),
      saleStartAt: DateTime.parse(stringValue(json['saleStartAt'])).toLocal(),
      saleEndAt: DateTime.parse(stringValue(json['saleEndAt'])).toLocal(),
    );
  }
}

class RegistrationEventSummaryModel {
  const RegistrationEventSummaryModel({
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

  factory RegistrationEventSummaryModel.fromJson(Map<String, dynamic> json) {
    return RegistrationEventSummaryModel(
      id: stringValue(json['id']),
      title: stringValue(json['title']),
      city: stringValue(json['city']),
      venue: stringValue(json['venue']),
      startAt: DateTime.parse(stringValue(json['startAt'])).toLocal(),
      endAt: DateTime.parse(stringValue(json['endAt'])).toLocal(),
    );
  }
}

class RegistrationModel {
  const RegistrationModel({
    required this.id,
    required this.event,
    required this.ticketType,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final RegistrationEventSummaryModel event;
  final TicketTypeModel ticketType;
  final int quantity;
  final String status;
  final DateTime createdAt;

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: stringValue(json['id']),
      event: RegistrationEventSummaryModel.fromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      ticketType: TicketTypeModel.fromJson(
        Map<String, dynamic>.from(json['ticketType'] as Map),
      ),
      quantity: intValue(json['quantity']),
      status: stringValue(json['status']),
      createdAt: DateTime.parse(stringValue(json['createdAt'])).toLocal(),
    );
  }
}

class EventCreateRequest {
  const EventCreateRequest({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.venue,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.vendorMatchRadiusKm,
    required this.startAt,
    required this.endAt,
    required this.publishImmediately,
    this.coverImageUrl,
  });

  final String title;
  final String description;
  final String categoryId;
  final String venue;
  final String city;
  final double? latitude;
  final double? longitude;
  final double? vendorMatchRadiusKm;
  final DateTime startAt;
  final DateTime endAt;
  final bool publishImmediately;
  final String? coverImageUrl;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'venue': venue,
      'city': city,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (vendorMatchRadiusKm != null) 'vendorMatchRadiusKm': vendorMatchRadiusKm,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'status': publishImmediately ? 'published' : 'draft',
      'visibility': 'public',
      if (coverImageUrl != null && coverImageUrl!.isNotEmpty)
        'coverImageUrl': coverImageUrl,
    };
  }
}

class TicketTypeCreateRequest {
  const TicketTypeCreateRequest({
    required this.name,
    required this.price,
    required this.quantity,
    required this.saleStartAt,
    required this.saleEndAt,
  });

  final String name;
  final String price;
  final int quantity;
  final DateTime saleStartAt;
  final DateTime saleEndAt;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'saleStartAt': saleStartAt.toUtc().toIso8601String(),
      'saleEndAt': saleEndAt.toUtc().toIso8601String(),
    };
  }
}
