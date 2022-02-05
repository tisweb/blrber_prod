// Model for Subscription Transaction Details

import 'package:cloud_firestore/cloud_firestore.dart';

class UserSubDetails {
  String userId;
  Timestamp renewedAt;
  num postNoOfDays;
  num planValidDays;
  String paidStatus;
  String planName;
  String userCountryCode;

  UserSubDetails({
    this.userId,
    this.renewedAt,
    this.postNoOfDays,
    this.planValidDays,
    this.paidStatus,
    this.planName,
    this.userCountryCode,
  });
}
