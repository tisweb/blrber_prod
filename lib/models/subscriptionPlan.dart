// Model for Subscription Plan

class SubscriptionPlan {
  String planName;
  num planValidDays;
  String planAvailable;
  String planAmount;
  String countryCode;
  String userType;
  String subscriptionPlanDocId;

  SubscriptionPlan({
    this.planName,
    this.planValidDays,
    this.planAvailable,
    this.planAmount,
    this.countryCode,
    this.userType,
    this.subscriptionPlanDocId,
  });
}
