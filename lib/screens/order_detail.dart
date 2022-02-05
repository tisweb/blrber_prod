import 'package:blrber/models/product.dart';
import 'package:blrber/models/product_order.dart';
import 'package:blrber/models/user_detail.dart';
import 'package:blrber/widgets/chat/to_chat.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

class OrderDetail extends StatefulWidget {
  final productOrderId;
  final displayType;
  const OrderDetail({
    Key key,
    this.productOrderId,
    this.displayType,
  }) : super(key: key);

  @override
  _OrderDetailState createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  List<ProductOrder> productOrders = [];
  List<Product> products = [];
  List<UserDetail> sellerDetails = [];
  List<UserDetail> buyerDetails = [];

  bool dataAvailable = false;

  String _updateInfo = "";
  String _orderStatusString = "";

  List<DropdownMenuItem<String>> _orderStatus = [];

  @override
  void didChangeDependencies() {
    _initialDataLoad();
    super.didChangeDependencies();
  }

  _initialDataLoad() {
    productOrders = Provider.of<List<ProductOrder>>(context);
    products = Provider.of<List<Product>>(context);
    sellerDetails = Provider.of<List<UserDetail>>(context);
    buyerDetails = Provider.of<List<UserDetail>>(context);

    // Menu Items for Product Conditions

    List<OrderStatus> orderStatuss = Provider.of<List<OrderStatus>>(context);
    _orderStatus = [];

    if (orderStatuss.length > 0) {
      for (OrderStatus orderStatus in orderStatuss) {
        _orderStatus.add(
          DropdownMenuItem(
            value: orderStatus.orderStatus,
            child: Text(orderStatus.orderStatus),
          ),
        );
      }
    }

    if (productOrders.length > 0 &&
        products.length > 0 &&
        sellerDetails.length > 0 &&
        buyerDetails.length > 0) {
      productOrders = productOrders
          .where(
              (e) => e.productOrderDocId.trim() == widget.productOrderId.trim())
          .toList();

      if (productOrders.length > 0) {
        _updateInfo = productOrders[0].updateInfo;
        _orderStatusString = productOrders[0].orderStatus;

        sellerDetails = sellerDetails
            .where((e) =>
                e.userDetailDocId.trim() ==
                productOrders[0].sellerUserId.trim())
            .toList();
        buyerDetails = buyerDetails
            .where((e) =>
                e.userDetailDocId.trim() == productOrders[0].buyerUserId.trim())
            .toList();
        products = products
            .where(
                (e) => e.prodDocId.trim() == productOrders[0].productId.trim())
            .toList();
        if (products.length > 0 &&
            sellerDetails.length > 0 &&
            buyerDetails.length > 0) {
          setState(() {
            dataAvailable = true;
          });
        } else {
          setState(() {
            dataAvailable = false;
          });
        }
      }
    }
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Order Detail"),
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back),
          )),
      body: dataAvailable
          ? SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                                        text: productOrders[0]
                                            .productQty
                                            .toString(),
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
                                        text: productOrders[0]
                                            .totalEstAmount
                                            .toString(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            child: Text(
                              "Order Status",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                          ),
                          Container(
                            child: Text(productOrders[0].orderStatus),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      if (productOrders[0].updateInfo.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              child: Text(
                                "Order Update Info",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                            ),
                            Container(
                              child: Text(productOrders[0].updateInfo),
                            ),
                          ],
                        ),
                      if (productOrders[0].updateInfo.isNotEmpty)
                        SizedBox(
                          height: 10,
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            child: Text(
                              "Order Created At",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                          ),
                          Container(
                            child: Text(getDateTime(
                                productOrders[0].OrderCreatedAt.toDate())),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            child: Text(
                              "Order Updated At",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                          ),
                          Container(
                            child: Text(getDateTime(
                                productOrders[0].OrderUpdatedAt.toDate())),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Divider(),
                      SizedBox(
                        height: 10,
                      ),
                      if (widget.displayType == "RO")
                        Wrap(
                          spacing: 10.0,
                          children: [
                            Container(
                              child: Text(
                                "Buyer Information",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  child: Text(
                                    "Name",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                ),
                                Container(
                                  child: Text(buyerDetails[0].displayName),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  child: Text(
                                    "Address",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                          ],
                        ),
                      if (widget.displayType == "RO")
                        Container(
                          child: Flexible(
                            child: Text(
                              buyerDetails[0].addressLocation,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (widget.displayType == "RO")
                        Wrap(
                          spacing: 10.0,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if (buyerDetails[0].phoneNumber != null &&
                                    buyerDetails[0].phoneNumber != "")
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.green, // background
                                      onPrimary: Colors.white, // foreground
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _makePhoneCall(
                                            'tel:${buyerDetails[0].phoneNumber}');
                                      });
                                    },
                                    icon: Icon(Icons.call),
                                    label: Text(
                                      "Call",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.orange[700], // background
                                    onPrimary: Colors.white, // foreground
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) {
                                            return ToChat(
                                                userIdFrom: sellerDetails[0]
                                                    .userDetailDocId
                                                    .trim(),
                                                userIdTo: buyerDetails[0]
                                                    .userDetailDocId
                                                    .trim(),
                                                prodName: products[0].prodName);
                                          },
                                          fullscreenDialog: true),
                                    );
                                  },
                                  icon: Icon(Icons.chat),
                                  label: Text(
                                    "Chat",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      if (widget.displayType == "OP")
                        Wrap(
                          spacing: 10.0,
                          children: [
                            Container(
                              child: Text(
                                "Seller Information",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  child: Text(
                                    "Compnay Name",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                ),
                                Container(
                                  child: Text(sellerDetails[0].companyName),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width / 2,
                              child: Text(
                                "Address",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      if (widget.displayType == "OP")
                        Container(
                          child: Flexible(
                            child: Text(
                              sellerDetails[0].addressLocation,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (widget.displayType == "OP")
                        Wrap(
                          spacing: 10.0,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if (sellerDetails[0].phoneNumber != null &&
                                    sellerDetails[0].phoneNumber != "")
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.green, // background
                                      onPrimary: Colors.white, // foreground
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _makePhoneCall(
                                            'tel:${sellerDetails[0].phoneNumber}');
                                      });
                                    },
                                    icon: Icon(Icons.call),
                                    label: Text(
                                      "Call",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.orange[700], // background
                                    onPrimary: Colors.white, // foreground
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) {
                                            return ToChat(
                                                userIdFrom: buyerDetails[0]
                                                    .userDetailDocId
                                                    .trim(),
                                                userIdTo: sellerDetails[0]
                                                    .userDetailDocId
                                                    .trim(),
                                                prodName: products[0].prodName);
                                          },
                                          fullscreenDialog: true),
                                    );
                                  },
                                  icon: Icon(Icons.chat),
                                  label: Text(
                                    "Chat",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(),
                          ],
                        ),
                      if (_orderStatus.length > 0 && widget.displayType == "RO")
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width / 2,
                              child: Text(
                                "Status Update Information",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              color: bScaffoldBackgroundColor,
                              child: DropdownButtonFormField<String>(
                                items: _orderStatus,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _orderStatusString = value;
                                  });
                                },
                                onSaved: (value) {
                                  productOrders[0].orderStatus = value;
                                },
                                validator: (value) {
                                  return null;
                                },
                                value: productOrders[0].orderStatus,
                              ),
                            ),
                            TextFormField(
                              initialValue: _updateInfo,
                              key: ValueKey('updateInfo'),
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                  labelText: 'Update Information'),
                              onChanged: (value) {
                                setState(() {
                                  _updateInfo = value;
                                });
                              },
                            ),
                            if (_orderStatusString.isNotEmpty ||
                                _updateInfo.isNotEmpty)
                              Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await updateOrderStatus(
                                        _orderStatusString,
                                        _updateInfo,
                                        productOrders[0].productOrderDocId);
                                  },
                                  child: Text('Update Status'),
                                ),
                              )
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  String getDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime).toString();
  }

  Future<void> updateOrderStatus(
      String orderStatus, String updateInfo, String productOrderId) async {
    await FirebaseFirestore.instance
        .collection('productOrders')
        .doc(productOrderId)
        .update({
      'orderStatus': orderStatus,
      'updateInfo': updateInfo,
      'OrderUpdatedAt': Timestamp.now(),
    }).then((value) {
      print("Order Updated");
      Fluttertoast.showToast(msg: "Order Status Updated!");
    }).catchError((error) => print("Failed to update order: $error"));
  }
}
