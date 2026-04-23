import '../core/json_value.dart';

class SponsorProfileModel {
  const SponsorProfileModel({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.description,
    required this.industries,
    required this.logoUrl,
    required this.websiteUrl,
    required this.verificationDocumentUrl,
    required this.verified,
  });

  final String id;
  final String userId;
  final String companyName;
  final String description;
  final String industries;
  final String? logoUrl;
  final String? websiteUrl;
  final String? verificationDocumentUrl;
  final bool verified;

  factory SponsorProfileModel.fromJson(Map<String, dynamic> json) {
    return SponsorProfileModel(
      id: stringValue(json['id']),
      userId: stringValue(json['userId']),
      companyName: stringValue(json['companyName']),
      description: stringValue(json['description']),
      industries: stringValue(json['industries']),
      logoUrl: nullableStringValue(json['logoUrl']),
      websiteUrl: nullableStringValue(json['websiteUrl']),
      verificationDocumentUrl:
          nullableStringValue(json['verificationDocumentUrl']),
      verified: boolValue(json['verified']),
    );
  }
}

class SponsorshipOpportunityEventSummaryModel {
  const SponsorshipOpportunityEventSummaryModel({
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

  factory SponsorshipOpportunityEventSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SponsorshipOpportunityEventSummaryModel(
      id: stringValue(json['id']),
      title: stringValue(json['title']),
      city: stringValue(json['city']),
      venue: stringValue(json['venue']),
      startAt: DateTime.parse(stringValue(json['startAt'])).toLocal(),
      endAt: DateTime.parse(stringValue(json['endAt'])).toLocal(),
    );
  }
}

class SponsorshipOpportunityModel {
  const SponsorshipOpportunityModel({
    required this.id,
    required this.event,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.requiredAmount,
    required this.targetAudience,
    required this.benefitsOffered,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final SponsorshipOpportunityEventSummaryModel event;
  final String organizerId;
  final String title;
  final String description;
  final String requiredAmount;
  final String targetAudience;
  final String benefitsOffered;
  final String status;
  final DateTime createdAt;

  bool get isOpen => status == 'open';

  factory SponsorshipOpportunityModel.fromJson(Map<String, dynamic> json) {
    return SponsorshipOpportunityModel(
      id: stringValue(json['id']),
      event: SponsorshipOpportunityEventSummaryModel.fromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      organizerId: stringValue(json['organizerId']),
      title: stringValue(json['title']),
      description: stringValue(json['description']),
      requiredAmount: stringValue(json['requiredAmount']),
      targetAudience: stringValue(json['targetAudience']),
      benefitsOffered: stringValue(json['benefitsOffered']),
      status: stringValue(json['status']),
      createdAt: DateTime.parse(stringValue(json['createdAt'])).toLocal(),
    );
  }
}

class SponsorshipInterestModel {
  const SponsorshipInterestModel({
    required this.id,
    required this.sponsor,
    required this.opportunity,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final SponsorProfileModel sponsor;
  final SponsorshipOpportunityModel opportunity;
  final String status;
  final String message;
  final DateTime createdAt;

  factory SponsorshipInterestModel.fromJson(Map<String, dynamic> json) {
    return SponsorshipInterestModel(
      id: stringValue(json['id']),
      sponsor: SponsorProfileModel.fromJson(
        Map<String, dynamic>.from(json['sponsor'] as Map),
      ),
      opportunity: SponsorshipOpportunityModel.fromJson(
        Map<String, dynamic>.from(json['opportunity'] as Map),
      ),
      status: stringValue(json['status']),
      message: stringValue(json['message']),
      createdAt: DateTime.parse(stringValue(json['createdAt'])).toLocal(),
    );
  }
}

class SponsorProfileUpsertRequest {
  const SponsorProfileUpsertRequest({
    required this.companyName,
    required this.description,
    required this.industries,
    required this.logoUrl,
    required this.websiteUrl,
    required this.verificationDocumentUrl,
  });

  final String companyName;
  final String description;
  final String industries;
  final String? logoUrl;
  final String? websiteUrl;
  final String? verificationDocumentUrl;

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'description': description,
      'industries': industries,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
      'verificationDocumentUrl': verificationDocumentUrl,
    };
  }
}

class SponsorshipOpportunityCreateRequest {
  const SponsorshipOpportunityCreateRequest({
    required this.eventId,
    required this.title,
    required this.description,
    required this.requiredAmount,
    required this.targetAudience,
    required this.benefitsOffered,
    required this.status,
  });

  final String eventId;
  final String title;
  final String description;
  final String requiredAmount;
  final String targetAudience;
  final String benefitsOffered;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'requiredAmount': requiredAmount,
      'targetAudience': targetAudience,
      'benefitsOffered': benefitsOffered,
      'status': status,
    };
  }
}

class SponsorshipInterestCreateRequest {
  const SponsorshipInterestCreateRequest({
    required this.message,
  });

  final String message;

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}
