import '../events/event_models.dart';
import '../core/json_value.dart';
import '../sponsors/sponsor_models.dart';
import '../vendors/vendor_models.dart';

class AiEventRecommendationModel {
  const AiEventRecommendationModel({
    required this.score,
    required this.reasonSummary,
    required this.event,
  });

  final double score;
  final String reasonSummary;
  final EventModel event;

  factory AiEventRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AiEventRecommendationModel(
      score: doubleValue(json['score']),
      reasonSummary: stringValue(json['reasonSummary']),
      event: EventModel.fromJson(Map<String, dynamic>.from(json['event'] as Map)),
    );
  }
}

class AiVendorRecommendationModel {
  const AiVendorRecommendationModel({
    required this.score,
    required this.reasonSummary,
    required this.vendor,
  });

  final double score;
  final String reasonSummary;
  final VendorProfileModel vendor;

  factory AiVendorRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AiVendorRecommendationModel(
      score: doubleValue(json['score']),
      reasonSummary: stringValue(json['reasonSummary']),
      vendor: VendorProfileModel.fromJson(
        Map<String, dynamic>.from(json['vendor'] as Map),
      ),
    );
  }
}

class AiOpportunityRecommendationModel {
  const AiOpportunityRecommendationModel({
    required this.score,
    required this.reasonSummary,
    required this.opportunity,
  });

  final double score;
  final String reasonSummary;
  final SponsorshipOpportunityModel opportunity;

  factory AiOpportunityRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AiOpportunityRecommendationModel(
      score: doubleValue(json['score']),
      reasonSummary: stringValue(json['reasonSummary']),
      opportunity: SponsorshipOpportunityModel.fromJson(
        Map<String, dynamic>.from(json['opportunity'] as Map),
      ),
    );
  }
}

class AiPlanningAssistantResponseModel {
  const AiPlanningAssistantResponseModel({
    required this.overview,
    required this.checklist,
    required this.vendorCategories,
    required this.timelineMilestones,
    required this.sponsorshipAngles,
    required this.budgetGuidance,
    required this.operationalRisks,
  });

  final String overview;
  final List<String> checklist;
  final List<String> vendorCategories;
  final List<String> timelineMilestones;
  final List<String> sponsorshipAngles;
  final List<String> budgetGuidance;
  final List<String> operationalRisks;

  factory AiPlanningAssistantResponseModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(String key) {
      final value = json[key];
      if (value is! List) {
        return const [];
      }
      return value.map((item) => item.toString()).toList(growable: false);
    }

    return AiPlanningAssistantResponseModel(
      overview: stringValue(json['overview']),
      checklist: parseList('checklist'),
      vendorCategories: parseList('vendorCategories'),
      timelineMilestones: parseList('timelineMilestones'),
      sponsorshipAngles: parseList('sponsorshipAngles'),
      budgetGuidance: parseList('budgetGuidance'),
      operationalRisks: parseList('operationalRisks'),
    );
  }
}
