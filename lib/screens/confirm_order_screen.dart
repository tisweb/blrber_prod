import 'package:blrber/models/product.dart';
import 'package:blrber/models/user_detail.dart';
import 'package:blrber/provider/get_current_location.dart';
import 'package:blrber/screens/post_added_result_screen.dart';

import 'package:blrber/services/api_keys.dart';
import 'package:blrber/widgets/search_place_auto_complete_widget_custom.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:search_map_place/search_map_place.dart';

import '../constants.dart';

class ConfirmOrderScreen extends StatefulWidget {
  final String userId;
  final String prodId;
  final int qty;
  const ConfirmOrderScreen({this.userId, this.prodId, this.qty, Key key})
      : super(key: key);

  @override
  _ConfirmOrderScreenState createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  List<Product> products = [];
  bool dataAvailable = false;
  FocusNode qtyFocus;
  int qty = 0;
  double productTotal = 0.0;
  String _addressLocation = '';
  String _phoneNumber = '';
  String _countryCode = "";
  List<UserDetail> userDetails = [];
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();
  TextEditingController controllerQty = TextEditingController();

  @override
  void initState() {
    super.initState();
    qty = widget.qty;
    controllerQty.text = qty.toString();
    getCurrentLocation =
        Provider.of<GetCurrentLocation>(context, listen: false);
    setState(() {
      _countryCode = getCurrentLocation.countryCode;
    });
    qtyFocus = FocusNode();
  }

  @override
  void didChangeDependencies() {
    _initialDataLoad();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    qtyFocus.dispose();
    controllerQty.dispose();

    super.dispose();
  }

  _initialDataLoad() {
    products = Provider.of<List<Product>>(context);
    userDetails = Provider.of<List<UserDetail>>(context);

    if (products.length > 0 && userDetails.length > 0) {
      products = products
          .where((e) => e.prodDocId.trim() == widget.prodId.trim())
          .toList();

      userDetails = userDetails
          .where((e) => e.userDetailDocId.trim() == widget.userId.trim())
          .toList();

      setState(() {
        dataAvailable = true;
        _addressLocation = userDetails[0].addressLocation;
        productTotal = double.parse(products[0].price) * qty;
      });
    } else {
      setState(() {
        dataAvailable = false;
      });
    }
  }

  Future<void> _createOrder() async {
    await FirebaseFirestore.instance.collection('productOrders').add({
      'buyerUserId': widget.userId.trim(),
      'sellerUserId': products[0].userDetailDocId.trim(),
      'productId': products[0].prodDocId,
      'productName': products[0].prodName,
      'productQty': qty,
      'totalEstAmount': productTotal.toString(),
      'shippingAddress': _addressLocation,
      'shippingContact': _phoneNumber,
      'OrderCreatedAt': Timestamp.now(),
      'orderStatus': "Order-Placed",
      'updateInfo': '',
      'OrderUpdatedAt': Timestamp.now(),
    }).then((value) {
      print("Order Created");
    }).catchError((error) => print("Failed to create order: $error"));
  }

  Future<void> _productStockUpdate() async {
    int _updatedStockInHand = int.parse(products[0].stockInHand) - qty;

    print("_updatedStockInHand - $_updatedStockInHand");

    await FirebaseFirestore.instance
        .collection("products")
        .doc(products[0].prodDocId)
        .update({
      'stockInHand': _updatedStockInHand.toString(),
    }).then((value) {
      print("Stock In Hand Updated in products");
    }).catchError(
            (error) => print("Failed to update stock in products: $error"));
  }

  @override
  Widget build(BuildContext context) {
    return dataAvailable
        ? Scaffold(
            appBar: AppBar(
              title: Text("Confirm Order"),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      child: const Text(
                        "Shipping Address",
                        style: const TextStyle(
                          color: bDisabledColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Divider(),
                    Container(
                      height: MediaQuery.of(context).size.height / 6,
                      child: Row(
                        children: [
                          Flexible(
                            child: _addressLocation == '' ||
                                    _addressLocation == null
                                ? Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : TextButton(
                                    onPressed: () {
                                      showModalBottomSheet<void>(
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (BuildContext context) {
                                          // return StatefulBuilder(builder:
                                          //     (BuildContext context,
                                          //         StateSetter
                                          //             setState /*You can rename this!*/) {
                                          return Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                2,
                                            child: SingleChildScrollView(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    // mainAxisSize:
                                                    //     MainAxisSize.min,
                                                    children: <Widget>[
                                                      const Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: const Text(
                                                            'Select Location'),
                                                      ),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child:
                                                            SearchPlaceAutoCompleteWidgetCustom(
                                                          apiKey: placeApiKey,
                                                          components:
                                                              _countryCode,
                                                          placeType:
                                                              PlaceType.address,
                                                          onSelected:
                                                              (place) async {
                                                            setState(() {
                                                              _addressLocation =
                                                                  '';
                                                            });

                                                            try {
                                                              await getCurrentLocation
                                                                  .getselectedPosition(
                                                                      place);

                                                              setState(() {
                                                                _addressLocation =
                                                                    getCurrentLocation
                                                                        .addressLocation;
                                                              });
                                                            } on PlatformException catch (e) {
                                                              Fluttertoast.showToast(
                                                                  msg:
                                                                      'Please try again!',
                                                                  gravity:
                                                                      ToastGravity
                                                                          .TOP_RIGHT);
                                                              print(
                                                                  "Error on confirm order screen PlatformException- $e");
                                                            } catch (e) {
                                                              Fluttertoast.showToast(
                                                                  msg:
                                                                      'Please try again!',
                                                                  gravity:
                                                                      ToastGravity
                                                                          .TOP_RIGHT);
                                                              print(
                                                                  "Error on confirm order screen - $e");
                                                            }
                                                            setState(() {});
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: TextButton.icon(
                                                          onPressed: () async {
                                                            setState(() {
                                                              _addressLocation =
                                                                  '';
                                                            });

                                                            await getCurrentLocation
                                                                .getCurrentPosition();
                                                            setState(() {
                                                              _addressLocation =
                                                                  getCurrentLocation
                                                                      .addressLocation;
                                                            });
                                                          },
                                                          icon: const Icon(Icons
                                                              .my_location),
                                                          label: const Text(
                                                              "Current Location"),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child:
                                                            Text('New Address'),
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          _addressLocation,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                          // });
                                        },
                                      );
                                    },
                                    child: Text(
                                      _addressLocation,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                          )
                        ],
                      ),
                    ),
                    Divider(),
                    TextField(
                      // initialValue: userDetails[0].phoneNumber,
                      key: ValueKey('phoneNumber'),
                      // onEditingComplete: () => focusNode.nextFocus(),
                      keyboardType: TextInputType.phone,

                      decoration: const InputDecoration(
                          labelText: 'Shipping Phone Number'),
                      onChanged: (value) {
                        setState(() {
                          _phoneNumber = value;
                        });
                      },
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height / 6,
                      child: Row(
                        children: [
                          ClipRRect(
                            child: CachedNetworkImage(
                              height: MediaQuery.of(context).size.height / 8,
                              width: MediaQuery.of(context).size.width / 4,
                              fit: BoxFit.cover,
                              imageUrl: products[0].imageUrlFeatured,
                              placeholder: (context, url) => Container(
                                height: 0,
                                width: 0,
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: products[0].prodName,
                                  style: const TextStyle(
                                    color: bDisabledColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  text: products[0].currencySymbol,
                                  style: const TextStyle(
                                    color: bDisabledColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: ' ',
                                    ),
                                    TextSpan(
                                      text: products[0].price,
                                    ),
                                    const TextSpan(
                                      text: '  ',
                                    ),
                                    const TextSpan(
                                      text: 'X',
                                    ),
                                    const TextSpan(
                                      text: '  ',
                                    ),
                                    TextSpan(
                                      text: qty.toString(),
                                    ),
                                    const TextSpan(
                                      text: '  ',
                                    ),
                                    const TextSpan(
                                      text: '=',
                                    ),
                                    const TextSpan(
                                      text: '  ',
                                    ),
                                    TextSpan(
                                      text: productTotal.toString(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Payment Details:",
                      style: const TextStyle(
                        color: bDisabledColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Shipping Fee",
                            style: const TextStyle(
                              color: bDisabledColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Vendor's Option",
                            style: const TextStyle(
                              color: bDisabledColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Product Price",
                            style: const TextStyle(
                              color: bDisabledColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              text: products[0].currencySymbol,
                              style: const TextStyle(
                                color: bDisabledColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                const TextSpan(
                                  text: ' ',
                                ),
                                TextSpan(
                                  text: productTotal.toString(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Divider(),
                    Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Estimation",
                            style: const TextStyle(
                              color: bDisabledColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              text: products[0].currencySymbol,
                              style: const TextStyle(
                                color: bDisabledColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                const TextSpan(
                                  text: ' ',
                                ),
                                TextSpan(
                                  text: productTotal.toString(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Divider(),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (qty == 0) {
                              Fluttertoast.showToast(
                                  msg: 'Min order is 1',
                                  gravity: ToastGravity.TOP_RIGHT);
                            } else if (_phoneNumber == '') {
                              Fluttertoast.showToast(
                                  msg: 'Enter Phone Number!',
                                  gravity: ToastGravity.TOP_RIGHT);
                            } else if (_phoneNumber.length != 10) {
                              Fluttertoast.showToast(
                                msg: 'Phone Number must be 10 Digits!',
                                gravity: ToastGravity.TOP_RIGHT,
                              );
                            } else if (_addressLocation == '' ||
                                _addressLocation == null) {
                              Fluttertoast.showToast(
                                msg: 'Select Shipping address!',
                                gravity: ToastGravity.TOP_RIGHT,
                              );
                            } else {
                              await _createOrder();
                              await _productStockUpdate();
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) {
                                      return PostAddedResultScreen(
                                        editPost: "true",
                                        displayType: "O",
                                      );
                                    },
                                    fullscreenDialog: true),
                              );
                            }
                          },
                          icon: Icon(Icons.shop_2),
                          label: Text("Confirm Order"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Container(
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
  }
}
