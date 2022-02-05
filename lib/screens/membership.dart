import 'package:blrber/models/paymentGatewayInfo.dart';
import 'package:blrber/models/subscriptionPlan.dart';
import 'package:blrber/models/subscriptionTransactionDetails.dart';
import 'package:blrber/models/userSubDetails.dart';
import 'package:blrber/models/user_detail.dart';
import 'package:blrber/provider/get_current_location.dart';
import 'package:blrber/screens/trans_msg_screen.dart';
import 'package:blrber/services/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class Membership extends StatefulWidget {
  final String userId;
  Membership({this.userId});

  @override
  _MembershipState createState() => _MembershipState();
}

class _MembershipState extends State<Membership> {
  Razorpay _razorpay;

  List<UserDetail> userDetails = [];
  List<PaymentGatewayInfo> paymentGatewayInfos = [];
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();
  List<SubscriptionPlan> subscriptionPlans = [];
  List<UserSubDetails> userSubDetailsList = [];
  SubTransactionDetails subTransactionDetails = SubTransactionDetails();
  UserSubDetails userSubDetails = UserSubDetails();
  SubscriptionPlan selectedSubscriptionPlan = SubscriptionPlan();

  String _countryCode = "";
  String _planAmount = "";
  int _planAmountInt = 0;
  String _currencyName = "";
  String _currencySymbol = "";

  bool dataAvailable = false;
  var _userType = "";
  var _isUserSame = true;

  String subTransStatus = "";

  @override
  void initState() {
    super.initState();
    getCurrentLocation =
        Provider.of<GetCurrentLocation>(context, listen: false);
    _currencyName = getCurrentLocation.currencyCode;
    _currencySymbol = getCurrencySymbolByName(_currencyName);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  @override
  void didChangeDependencies() {
    _initialDataLoad();
    super.didChangeDependencies();
  }

  _initialDataLoad() {
    getCurrentLocation = Provider.of<GetCurrentLocation>(context);
    userDetails = Provider.of<List<UserDetail>>(context);
    userSubDetailsList = Provider.of<List<UserSubDetails>>(context);
    paymentGatewayInfos = Provider.of<List<PaymentGatewayInfo>>(context);
    subscriptionPlans = Provider.of<List<SubscriptionPlan>>(context);

    if (_countryCode.isEmpty) {
      _countryCode = getCurrentLocation.countryCode;
    }

    if (userDetails.length > 0 &&
        paymentGatewayInfos.length > 0 &&
        subscriptionPlans.length > 0 &&
        userSubDetailsList.length > 0) {
      userDetails = userDetails
          .where((e) => e.userDetailDocId == widget.userId.trim())
          .toList();
      userSubDetailsList = userSubDetailsList
          .where((e) => e.userId == widget.userId.trim())
          .toList();
      paymentGatewayInfos = paymentGatewayInfos
          .where((e) =>
              e.countryCode == _countryCode && e.gatewayAvailable == "Yes")
          .toList();
      subscriptionPlans = subscriptionPlans
          .where((e) => e.countryCode == _countryCode)
          .toList();

      if (userDetails.length > 0 &&
          paymentGatewayInfos.length > 0 &&
          subscriptionPlans.length > 0) {
        subscriptionPlans.sort((a, b) {
          var aUserType = a.userType;
          var bUserType = b.userType;
          return bUserType.compareTo(aUserType);
        });
        setState(() {
          dataAvailable = true;
        });
      }
    } else {
      setState(() {
        dataAvailable = false;
      });
    }
  }

  Future<void> _addSubTransactionDetails(
      SubTransactionDetails subTransactionDetails) async {
    await FirebaseFirestore.instance.collection('subTransactionDetails').add({
      'transStatus': subTransactionDetails.transStatus,
      'transAt': subTransactionDetails.transAt,
      'paymentGatewayName': subTransactionDetails.paymentGatewayName,
      'userId': subTransactionDetails.userId,
      'userName': subTransactionDetails.userName,
      'planName': subTransactionDetails.planName,
      'planAmount': subTransactionDetails.planAmount,
      'orderId': subTransactionDetails.orderId,
      'paymentId': subTransactionDetails.paymentId,
      'signature': subTransactionDetails.signature,
      'code': subTransactionDetails.code,
      'message': subTransactionDetails.message,
      'walletName': subTransactionDetails.walletName,
    }).then((value) {
      print("Subscription Transaction Added");
    }).catchError(
        (error) => print("Failed to add Subscription Transaction: $error"));
  }

  Future<void> _updateUserSubDetails(UserSubDetails userSubDetails) async {
    await FirebaseFirestore.instance
        .collection('userSubDetails')
        .doc(userSubDetails.userId)
        .update({
      'renewedAt': userSubDetails.renewedAt,
      'postNoOfDays': userSubDetails.postNoOfDays,
      'planValidDays': userSubDetails.planValidDays,
      'paidStatus': userSubDetails.paidStatus,
      'planName': userSubDetails.planName,
    }).then((value) {
      print("UserSubDetails updated");
    }).catchError((error) => print("Failed to update UserSubDetails: $error"));
  }

  Future<void> _updateProductSubscription(
      String userID, String subscription) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    await FirebaseFirestore.instance
        .collection('products')
        .where("userDetailDocId", isEqualTo: userSubDetails.userId)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        batch.update(document.reference, {
          'subscription': subscription,
        });
      });
      return batch.commit().then((value) {
        print("Products subscription updated");
      }).catchError(
          (error) => print("Failed to commit Products subscription: $error"));
    }).catchError(
            (error) => print("Failed to update Products subscription: $error"));
  }

  void openCheckout() async {
    var options = {
      'key': paymentGatewayInfos[0].gatewayKey,
      'amount': _planAmountInt,
      'name': userDetails[0].userName,
      'description': selectedSubscriptionPlan.planName,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': userDetails[0].phoneNumber,
        'email': userDetails[0].email
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  // Future _addTransHistory() async {
  //   await FirebaseFirestore.instance.collection('transHistory').add({
  //     'userName': userName,
  //     'email': userEmail,
  //     'userImageUrl': '',
  //     'displayName': displayName,
  //     'providerId': providerId,
  //     'addressLocation': '',
  //     'countryCode': '',
  //     'buyingCountryCode': '',
  //     'latitude': 0.0,
  //     'longitude': 0.0,
  //     'phoneNumber': '',
  //     'alternateNumber': '',
  //     'userType': '',
  //     'licenceNumber': '',
  //     'companyName': '',
  //     'companyLogoUrl': '',
  //   }).catchError((error) {
  //     print("Failed to add user: $error");
  //   });
  // }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (response.paymentId != null) {
      setState(() {
        subTransStatus = "Start";
      });
      // Fluttertoast.showToast(
      //     msg: "SUCCESS: " + response.paymentId,
      //     toastLength: Toast.LENGTH_SHORT);

      // Navigator.of(context).pop();
      subTransactionDetails.transStatus = "SUCCESS";
      subTransactionDetails.transAt = Timestamp.now();
      subTransactionDetails.paymentGatewayName = "Razorpay";
      subTransactionDetails.userId = userDetails[0].userDetailDocId;
      subTransactionDetails.userName = userDetails[0].userName;
      subTransactionDetails.orderId =
          response.orderId == null ? "" : response.orderId;
      subTransactionDetails.paymentId = response.paymentId;
      subTransactionDetails.planName = selectedSubscriptionPlan.planName;
      subTransactionDetails.planAmount = selectedSubscriptionPlan.planAmount;
      subTransactionDetails.signature =
          response.signature == null ? "" : response.signature;
      ;
      subTransactionDetails.code = "";
      subTransactionDetails.message = "";
      subTransactionDetails.walletName = "";
      _addSubTransactionDetails(subTransactionDetails).then(
        (value) {
          userSubDetails.userId = userDetails[0].userDetailDocId;
          userSubDetails.renewedAt = Timestamp.now();
          userSubDetails.postNoOfDays = 1;
          userSubDetails.planValidDays = selectedSubscriptionPlan.planValidDays;
          userSubDetails.paidStatus = "Paid";
          userSubDetails.planName = selectedSubscriptionPlan.planName;

          _updateUserSubDetails(userSubDetails).then(
            (value) {
              _updateProductSubscription(userDetails[0].userDetailDocId, "Paid")
                  .then((value) {
                setState(() {
                  subTransStatus = "Complete";
                });
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) {
                        return TransMsgScreen(
                            msg: "SUCCESS", paymentId: response.paymentId);
                      },
                      fullscreenDialog: true),
                );
              });
            },
          );
        },
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (response.message != null) {
      // Fluttertoast.showToast(
      //     msg: "ERROR: " + response.code.toString() + " - " + response.message,
      //     toastLength: Toast.LENGTH_SHORT);
      setState(() {
        subTransStatus = "Start";
      });
      subTransactionDetails.transStatus = "ERROR";
      subTransactionDetails.transAt = Timestamp.now();
      subTransactionDetails.paymentGatewayName = "Razorpay";
      subTransactionDetails.userId = userDetails[0].userDetailDocId;
      subTransactionDetails.userName = userDetails[0].userName;
      subTransactionDetails.planName = selectedSubscriptionPlan.planName;
      subTransactionDetails.planAmount = selectedSubscriptionPlan.planAmount;
      subTransactionDetails.orderId = "";
      subTransactionDetails.paymentId = "";
      subTransactionDetails.signature = "";
      subTransactionDetails.code = response.code.toString();
      subTransactionDetails.message = response.message;
      subTransactionDetails.walletName = "";
      _addSubTransactionDetails(subTransactionDetails).then((value) {
        setState(() {
          subTransStatus = "Complete";
        });
        Fluttertoast.showToast(
          msg: "Transcation Cancelled!! Please choose your plan",
          toastLength: Toast.LENGTH_SHORT,
        );
      });
      // Fluttertoast.showToast(
      //   msg: "Transcation Cancelled!! Please choose your plan",
      //   toastLength: Toast.LENGTH_SHORT,
      // );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (response.walletName != null) {
      setState(() {
        subTransStatus = "Start";
      });
      subTransactionDetails.transStatus = "ERROR";
      subTransactionDetails.transAt = Timestamp.now();
      subTransactionDetails.paymentGatewayName = "Razorpay";
      subTransactionDetails.userId = userDetails[0].userDetailDocId;
      subTransactionDetails.userName = userDetails[0].userName;
      subTransactionDetails.planName = selectedSubscriptionPlan.planName;
      subTransactionDetails.planAmount = selectedSubscriptionPlan.planAmount;
      subTransactionDetails.orderId = "";
      subTransactionDetails.paymentId = "";
      subTransactionDetails.signature = "";
      subTransactionDetails.code = "";
      subTransactionDetails.message = "";
      subTransactionDetails.walletName = response.walletName;
      _addSubTransactionDetails(subTransactionDetails).then((value) {
        setState(() {
          subTransStatus = "Complete";
        });
        Fluttertoast.showToast(
          msg: "EXTERNAL_WALLET: " + response.walletName,
          toastLength: Toast.LENGTH_SHORT,
        );
      });
    }
  }

  void showAlertDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text("Choolse plan!!"),
            content: Text("Please select desired plan!!"),
            actions: <Widget>[
              CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("OK")),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Membership"),
        centerTitle: true,
      ),
      body: dataAvailable
          ? Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                RichText(
                  text: TextSpan(
                    text: "Your Subscription : ",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: "${userSubDetailsList[0].paidStatus}",
                        style: TextStyle(
                            color: userSubDetailsList[0].paidStatus == "Unpaid"
                                ? Colors.red
                                : Colors.green),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                if (userSubDetailsList[0].paidStatus != "Unpaid")
                  Container(
                    child: Center(
                      child: Text(
                          "Plan valid days : ${userSubDetailsList[0].postNoOfDays} / ${userSubDetailsList[0].planValidDays}"),
                    ),
                  ),
                SizedBox(
                  height: 20,
                ),
                if (userSubDetailsList[0].paidStatus != "Free")
                  Container(
                    child: Text(
                      "Choose your plan",
                      style: TextStyle(fontSize: 20, color: Colors.blueGrey),
                    ),
                  ),
                userSubDetailsList[0].paidStatus == "Unpaid"
                    ? Container(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: subscriptionPlans.length,
                          itemBuilder: (BuildContext context, int i) {
                            if (_userType != subscriptionPlans[i].userType) {
                              _userType = subscriptionPlans[i].userType;
                              _isUserSame = false;
                            } else {
                              _isUserSame = true;
                            }
                            return subscriptionPlans[i].planName != "Free"
                                ? Column(
                                    children: [
                                      // if (!_isUserSame)
                                      //   Align(
                                      //     alignment: Alignment.topLeft,
                                      //     child: Container(
                                      //       child: Text(
                                      //           subscriptionPlans[i].userType),
                                      //     ),
                                      //   ),
                                      RadioListTile(
                                        isThreeLine: false,
                                        // subtitle: Text(subscriptionPlans[i]
                                        //             .userType ==
                                        //         "Dealer"
                                        //     ? "Post unlimited Ads for ${subscriptionPlans[i].planValidDays} days!\n"
                                        //         "Get Organized eShop!!"
                                        //     : "Post your Ad for ${subscriptionPlans[i].planValidDays} days!"),
                                        subtitle: Text(
                                            "Post unlimited Ads for ${subscriptionPlans[i].planValidDays} days!"),
                                        title: Text(
                                            "${subscriptionPlans[i].planName} - ${_currencySymbol} ${subscriptionPlans[i].planAmount}"),
                                        value: subscriptionPlans[i].planAmount,
                                        groupValue: _planAmount,
                                        onChanged: (value) {
                                          setState(() {
                                            _planAmount = value;
                                            _planAmountInt =
                                                int.parse(value) * 100;
                                            selectedSubscriptionPlan =
                                                subscriptionPlans[i];
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                : Container(
                                    height: 0,
                                    width: 0,
                                  );
                          },
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            child: Center(
                              child: Text(
                                  "Your plan : ${userSubDetailsList[0].planName} "),
                            ),
                          ),
                        ],
                      ),
                if (userSubDetailsList[0].paidStatus == "Unpaid")
                  Container(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_planAmount == "") {
                          showAlertDialog(context);
                        } else {
                          if (paymentGatewayInfos.length > 0) {
                            openCheckout();
                          } else {
                            Fluttertoast.showToast(
                              msg:
                                  "Oops: Something went wrong with payment gateway. Please contact support!",
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          }
                        }
                      },
                      child: Text(_planAmount == ""
                          ? "Choose plan"
                          : "Pay ${_currencySymbol} ${_planAmount}"),
                    ),
                  ),
                if (subTransStatus == "Start")
                  Center(
                    child: CircularProgressIndicator(),
                  )
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
