// Model for Company Detail table

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductOrder {
  String buyerUserId;
  String sellerUserId;
  String productId;
  String productName;
  int productQty;
  String totalEstAmount;
  String shippingAddress;
  String shippingContact;
  Timestamp OrderCreatedAt;
  String orderStatus;
  String updateInfo;
  Timestamp OrderUpdatedAt;
  String productOrderDocId;

  ProductOrder({
    this.buyerUserId,
    this.sellerUserId,
    this.productId,
    this.productName,
    this.productQty,
    this.totalEstAmount,
    this.shippingAddress,
    this.shippingContact,
    this.OrderCreatedAt,
    this.orderStatus,
    this.updateInfo,
    this.OrderUpdatedAt,
    this.productOrderDocId,
  });
}

// Model to store product condition
class OrderStatus {
  String orderStatus;

  OrderStatus({
    this.orderStatus,
  });
}
