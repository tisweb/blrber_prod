// Model for Payment Gateway Information

class PaymentGatewayInfo {
  String gatewayName;
  String gatewayKeyType;
  String gatewayKey;
  String gatewayUserName;
  String gatewayAvailable;
  String countryCode;
  String paymentGatewayInfoDocId;

  PaymentGatewayInfo({
    this.gatewayName,
    this.gatewayKeyType,
    this.gatewayKey,
    this.gatewayUserName,
    this.gatewayAvailable,
    this.countryCode,
    this.paymentGatewayInfoDocId,
  });
}
