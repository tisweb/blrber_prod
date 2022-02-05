// Model for Subscription Transaction Details

import 'package:cloud_firestore/cloud_firestore.dart';

class SubTransactionDetails {
  String transStatus;
  Timestamp transAt;
  String paymentGatewayName;
  String userId;
  String userName;
  String planAmount;
  String planName;
  String orderId;
  String paymentId;
  String signature;
  String code;
  String message;
  String walletName;

  SubTransactionDetails({
    this.transStatus,
    this.transAt,
    this.paymentGatewayName,
    this.userId,
    this.userName,
    this.planAmount,
    this.planName,
    this.orderId,
    this.paymentId,
    this.signature,
    this.code,
    this.message,
    this.walletName,
  });
}
