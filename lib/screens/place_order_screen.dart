import 'package:blrber/models/product.dart';
import 'package:blrber/models/user_detail.dart';
import 'package:blrber/provider/get_current_location.dart';
import 'package:blrber/screens/confirm_order_screen.dart';
import 'package:blrber/screens/edit_profile.dart';
import 'package:blrber/screens/tabs_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../constants.dart';

class PlaceOrderScreen extends StatefulWidget {
  final String userId;
  final String prodId;
  const PlaceOrderScreen({this.userId, this.prodId, Key key}) : super(key: key);

  @override
  _PlaceOrderScreenState createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  List<Product> products = [];
  bool dataAvailable = false;
  FocusNode qtyFocus;
  int qty = 0;
  double productTotal = 0.0;
  List<UserDetail> userDetails = [];
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();
  TextEditingController controllerQty = TextEditingController();

  @override
  void initState() {
    super.initState();
    controllerQty.text = qty.toString();
    getCurrentLocation =
        Provider.of<GetCurrentLocation>(context, listen: false);
    setState(() {});
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
      });
    } else {
      setState(() {
        dataAvailable = false;
      });
    }
  }

  void showAlertDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text("Start Order?"),
            content: Text("Please update your profile with contact info!"),
            actions: <Widget>[
              CupertinoDialogAction(
                  textStyle: TextStyle(color: CupertinoColors.systemRed),
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel")),
              CupertinoDialogAction(
                  textStyle: TextStyle(color: CupertinoColors.activeBlue),
                  isDefaultAction: true,
                  onPressed: () async {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) {
                            return EditProfile();
                          },
                          fullscreenDialog: true),
                    );
                  },
                  child: Text("Update Profile")),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return dataAvailable
        ? Scaffold(
            appBar: AppBar(
              title: Text("Place Order"),
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
                  children: [
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
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  text: "Stock In Hand",
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
                                      text: products[0].stockInHand,
                                      style:
                                          TextStyle(color: Colors.orange[900]),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text(
                          "Your Orders",
                          style: const TextStyle(
                            color: bDisabledColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
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
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                qtyFocus.unfocus();
                                if (qty > 0) {
                                  setState(() {
                                    qty = qty - 1;
                                    productTotal =
                                        qty * double.parse(products[0].price);
                                    controllerQty.text = qty.toString();
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.remove,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Container(
                              height: 20,
                              width: 50,
                              child: TextFormField(
                                controller: controllerQty,
                                focusNode: qtyFocus,
                                readOnly: true,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            IconButton(
                              onPressed: () {
                                qtyFocus.unfocus();
                                if (qty < int.parse(products[0].stockInHand)) {
                                  setState(() {
                                    qty = qty + 1;
                                    productTotal =
                                        qty * double.parse(products[0].price);
                                    controllerQty.text = qty.toString();
                                  });
                                } else {
                                  Fluttertoast.showToast(
                                      msg:
                                          "Only ${products[0].stockInHand} qty can be ordered!");
                                }
                              },
                              icon: Icon(
                                Icons.add,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                            "Total Price",
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
                          Text("Total Estimation"),
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
                    Divider(),
                    SizedBox(
                      height: 50,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (qty == 0) {
                          Fluttertoast.showToast(
                              msg: 'Min order is 1',
                              gravity: ToastGravity.TOP_RIGHT);
                        } else {
                          if (userDetails[0].isProfileUpdated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) {
                                    return ConfirmOrderScreen(
                                        userId: userDetails[0]
                                            .userDetailDocId
                                            .trim(),
                                        prodId: products[0].prodDocId,
                                        qty: qty);
                                  },
                                  fullscreenDialog: true),
                            );
                          } else {
                            showAlertDialog(context);
                          }
                        }
                      },
                      icon: Icon(Icons.shop_2),
                      label: Text("Start Order"),
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
