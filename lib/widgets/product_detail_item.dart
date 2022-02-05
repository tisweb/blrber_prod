//Imports for pubspec Packages
import 'package:badges/badges.dart';
import 'package:blrber/screens/place_order_screen.dart';
import 'package:blrber/screens/tabs_screen.dart';
import 'package:blrber/screens/user_shop_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

//Imports for pubspec Constants
import '../constants.dart';

//Imports for pubspec Models
import '../models/product.dart';
import '../models/user_detail.dart';

//Imports for pubspec Screens
import '../screens/gmap_screen.dart';
import '../screens/photos.dart';
import '../screens/product_detail_screen.dart';
import '../screens/view_full_specs.dart';
import '../screens/view_photos.dart';

//Imports for pubspec Widgets
import '../widgets/chat/to_chat.dart';

class ProductDetailItem extends StatefulWidget {
  final String productDocId;

  ProductDetailItem({this.productDocId});

  @override
  _ProductDetailItemState createState() => _ProductDetailItemState();
}

class _ProductDetailItemState extends State<ProductDetailItem> {
  bool _catCar = false;
  bool dataAvailable = false;

  String userId = "";
  bool isFavorite = false;
  List<CtmSpecialInfo> ctmSpecialInfos = [];
  List<Product> allProducts = [];
  List<ProdImages> prodImages = [];
  List<UserDetail> userDetails = [];
  List<ProdImages> prodImagesE, prodImagesI = [];
  List<Product> products, similarlisting = [];
  List<FavoriteProd> favoriteProd = [];
  User user;
  String _linkMessage;
  bool _isCreatingLink = false;

  Future<void> _socialShare(BuildContext context, String prodDocId) async {
    await _createDynamicLink(true, prodDocId);
    final RenderBox box = context.findRenderObject();
    final String text = _linkMessage;
    Share.share(text,
        subject: text,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }

  Future<void> _createDynamicLink(bool short, String prodDocID) async {
    setState(() {
      _isCreatingLink = true;
    });

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://blrberprod.page.link',
      link: Uri.parse('https://blrber.com/?view=product-detail&id=$prodDocID'),
      androidParameters: AndroidParameters(
        packageName: 'com.blrber.blrber',
        minimumVersion: 0,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      // iosParameters: IosParameters(
      //   bundleId: 'com.google.FirebaseCppDynamicLinksTestApp.dev',
      //   minimumVersion: '0',
      // ),
    );

    Uri url;
    if (short) {
      final ShortDynamicLink shortLink = await parameters.buildShortLink();
      url = shortLink.shortUrl;
    } else {
      url = await parameters.buildUrl();
    }

    setState(() {
      _linkMessage = url.toString();
      _isCreatingLink = false;
    });
  }

  Future<void> _manageFavorite(String prodId, bool isFav, String userId) async {
    final _firestore = FirebaseFirestore.instance.collection('favoriteProd');
    WriteBatch batch = FirebaseFirestore.instance.batch();
    if (isFav) {
      return _firestore.add({
        'prodDocId': prodId,
        'isFavorite': isFav,
        'userId': userId,
      });
    } else {
      return _firestore
          .where('prodDocId', isEqualTo: prodId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((document) {
          batch.delete(document.reference);
        });
        return batch.commit();
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _initialDataLoad();
    super.didChangeDependencies();
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _initialDataLoad() {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      userId = "";
    } else {
      userId = user.uid;
    }
    allProducts = Provider.of<List<Product>>(context);

    prodImages = Provider.of<List<ProdImages>>(context);
    userDetails = Provider.of<List<UserDetail>>(context);
    favoriteProd = Provider.of<List<FavoriteProd>>(context);

    if (allProducts.length > 0 &&
        userDetails.length > 0 &&
        prodImages.length > 0) {
      products = allProducts
          .where((e) => e.prodDocId.trim() == widget.productDocId.trim())
          .toList();
      similarlisting = allProducts
          .where(
            (e) =>
                (e.prodName
                    .trim()
                    .toLowerCase()
                    .contains(products[0].prodName.trim().toLowerCase())) ||
                (e.model
                    .trim()
                    .toLowerCase()
                    .contains(products[0].model.trim().toLowerCase())) ||
                (e.make
                    .trim()
                    .toLowerCase()
                    .contains(products[0].make.trim().toLowerCase())) ||
                (e.subCatType
                    .trim()
                    .toLowerCase()
                    .contains(products[0].subCatType.trim().toLowerCase())),
          )
          .toList();

      // similarlisting = similarlisting
      //     .where((e) =>
      //         e.prodDocId != products[0].prodDocId &&
      //         e.make != "Others" &&
      //         e.model != "Others")
      //     .toList();
      similarlisting = similarlisting
          .where((e) => e.prodDocId != products[0].prodDocId)
          .toList();

      userDetails = userDetails
          .where((e) =>
              e.userDetailDocId.trim() == products[0].userDetailDocId.trim())
          .toList();

      prodImages = prodImages
          .where((e) => e.prodDocId.trim() == widget.productDocId.trim())
          .toList();

      prodImagesE = prodImages.where((e) => e.imageType.trim() == "E").toList();

      prodImagesI = prodImages.where((e) => e.imageType.trim() == "I").toList();

      prodImages = prodImagesE + prodImagesI;
      _catCar = false;

      ctmSpecialInfos = [];
      if (products[0].catName.trim() == 'Vehicle' &&
          !products[0].subCatType.contains('Accessories')) {
        ctmSpecialInfos = Provider.of<List<CtmSpecialInfo>>(context);
        if (ctmSpecialInfos.length > 0) {
          if (products[0].subCatType == 'Cars' ||
              products[0].subCatType == 'Trucks' ||
              products[0].subCatType == 'Caravans') {
            _catCar = true;
          }

          ctmSpecialInfos = ctmSpecialInfos
              .where((e) => e.prodDocId.trim() == widget.productDocId.trim())
              .toList();
        } else {
          ctmSpecialInfos = [];
        }
      }
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
            title: Text("Login"),
            content: Text("Please login to continue!"),
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
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) {
                            return TabsScreen(4);
                          },
                          fullscreenDialog: true),
                    );
                  },
                  child: Text("Log In")),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return dataAvailable
        ? CustomScrollView(
            slivers: [
              SliverAppBar(
                elevation: 0.0,
                backgroundColor: bBackgroundColor,
                expandedHeight: 200,
                floating: true,
                pinned: true,
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    var top = constraints.biggest.height;
                    return FlexibleSpaceBar(
                      background: prodImages.length > 0
                          ? Stack(
                              children: [
                                CarouselSlider.builder(
                                  itemCount: prodImages.length,
                                  options: CarouselOptions(
                                    height: MediaQuery.of(context).size.height,
                                    // autoPlay: false,
                                    // aspectRatio: 2.0,
                                    // enlargeCenterPage: true,
                                    viewportFraction: 1.0,
                                    enlargeCenterPage: false,
                                  ),
                                  itemBuilder: (context, index, realIdx) {
                                    return Container(
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) {
                                                    return ViewPhotos(
                                                      imageIndex: index,
                                                      imageList: prodImages,
                                                      pageTitle: 'Gallery',
                                                    );
                                                  },
                                                  fullscreenDialog: true),
                                            );
                                          },
                                          child: Image.network(
                                            prodImages[index].imageUrl,
                                            fit: BoxFit.cover,
                                            // width: MediaQuery.of(context)
                                            //     .size
                                            //     .width,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: MediaQuery.of(context).size.width - 50,
                                  child: Badge(
                                    badgeContent: Text(
                                      prodImages.length.toString(),
                                      style: const TextStyle(
                                          color: bBackgroundColor),
                                    ),
                                    badgeColor: bPrimaryColor,
                                  ),
                                )
                              ],
                            )
                          : const Text(
                              'Image Loading',
                              style: const TextStyle(color: Colors.black),
                            ),
                      title: AnimatedOpacity(
                          duration: Duration(milliseconds: 300),
                          opacity: top < 90.0 ? 1.0 : 0.0,
                          // opacity: 1.0,
                          child: Text(
                            products[0].prodName,
                            style: TextStyle(fontSize: 20.0, color: bGrey800),
                          )),
                      centerTitle: true,
                    );
                  },
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(50),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: bGrey800,
                      ),
                      onPressed: () {
                        return Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: bBackgroundColor,
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: products[0].prodName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  WidgetSpan(
                                    child: IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () async {
                                        await _socialShare(
                                            context, products[0].prodDocId);
                                      },
                                    ),
                                    alignment: PlaceholderAlignment.middle,
                                  ),
                                  const WidgetSpan(
                                    child: const SizedBox(
                                      width: 20,
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        (favoriteProd.any((prod) =>
                                                prod.prodDocId ==
                                                    products[0].prodDocId &&
                                                prod.userId == userId))
                                            ? Icons.favorite
                                            : Icons.favorite_outline,
                                        color: Colors.redAccent,
                                        size: 27,
                                      ),
                                      color: Colors.redAccent,
                                      onPressed: () {
                                        if ((favoriteProd.any((prod) =>
                                            prod.prodDocId ==
                                                products[0].prodDocId &&
                                            prod.userId == userId))) {
                                          isFavorite = false;
                                        } else {
                                          isFavorite = true;
                                        }
                                        if (user == null) {
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //       builder: (_) {
                                          //         // return AuthScreen();
                                          //         print('userId 1 - $userId');
                                          //         return AuthScreenNew();
                                          //         setState(() {});
                                          //       },
                                          //       fullscreenDialog: true),
                                          // );
                                          // ScaffoldMessenger.of(context)
                                          //     .showSnackBar(
                                          //   SnackBar(
                                          //     content: Text(
                                          //         'Please login to add items in Favorites!'),
                                          //   ),
                                          // );
                                          showAlertDialog(context);
                                        } else {
                                          // if (userId.isEmpty ||
                                          //     userId == null) {
                                          //   // return AuthScreen();
                                          //   print('userId 2 - $userId');
                                          //   return AuthScreenNew();
                                          // }

                                          _manageFavorite(products[0].prodDocId,
                                              isFavorite, userId);
                                        }
                                      },
                                    ),
                                    alignment: PlaceholderAlignment.middle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'Status : ',
                                style: const TextStyle(
                                  color: bDisabledColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: products[0].status,
                                    style: TextStyle(
                                      color: products[0].status == 'Verified'
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            RichText(
                              text: const WidgetSpan(
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                            ),
                            Flexible(
                              flex: 1,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) {
                                          return GMapScreen(
                                            lat: products[0].latitude,
                                            long: products[0].longitude,
                                            addressLocation:
                                                products[0].addressLocation,
                                          );
                                        },
                                        fullscreenDialog: true),
                                  );
                                },
                                child: Text(
                                  products[0].addressLocation,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: bBlueColor),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                text: products[0].currencySymbol,
                                style: const TextStyle(
                                  color: Colors.black,
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
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                text: "Stock In Hand",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  const TextSpan(
                                    text: '  ',
                                  ),
                                  TextSpan(
                                    text: products[0].stockInHand,
                                    style: TextStyle(
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      userId.trim() != products[0].userDetailDocId.trim()
                          ? Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0, right: 15.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.blue, // background
                                      onPrimary: Colors.white, // foreground
                                    ),
                                    onPressed: () {
                                      if (user == null) {
                                        showAlertDialog(context);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) {
                                                return PlaceOrderScreen(
                                                    userId: userId.trim(),
                                                    prodId:
                                                        products[0].prodDocId);
                                              },
                                              fullscreenDialog: true),
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.shop),
                                    label: Text(
                                      "Place Order",
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
                                      if (user == null) {
                                        showAlertDialog(context);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) {
                                                return ToChat(
                                                    userIdFrom: userId.trim(),
                                                    userIdTo: products[0]
                                                        .userDetailDocId
                                                        .trim(),
                                                    prodName:
                                                        products[0].prodName);
                                              },
                                              fullscreenDialog: true),
                                        );
                                      }
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
                                  if (userDetails[0].phoneNumber != null &&
                                      userDetails[0].phoneNumber != "")
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.green, // background
                                        onPrimary: Colors.white, // foreground
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _makePhoneCall(
                                              'tel:${userDetails[0].phoneNumber}');
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
                                ],
                              ),
                            )
                          : Container(
                              child: Text('This Ad is created by You!!'),
                            ),
                      const SizedBox(
                        height: 2,
                      ),
                      // userId.trim() != products[0].userDetailDocId.trim()
                      //     ? Container(
                      //         padding: const EdgeInsets.only(
                      //             left: 15.0, right: 15.0),
                      //         child: Row(
                      //           mainAxisAlignment:
                      //               MainAxisAlignment.spaceEvenly,
                      //           children: [
                      //             ElevatedButton.icon(
                      //               onPressed: () {
                      //                 if (user == null) {
                      //                   showAlertDialog(context);
                      //                 } else {
                      //                   Navigator.push(
                      //                     context,
                      //                     MaterialPageRoute(
                      //                         builder: (_) {
                      //                           return ToChat(
                      //                               userIdFrom: userId.trim(),
                      //                               userIdTo: products[0]
                      //                                   .userDetailDocId
                      //                                   .trim(),
                      //                               prodName:
                      //                                   products[0].prodName);
                      //                         },
                      //                         fullscreenDialog: true),
                      //                   );
                      //                 }
                      //               },
                      //               icon: Icon(Icons.shop),
                      //               label: Text("Place Order"),
                      //             ),
                      //           ],
                      //         ),
                      //       )
                      //     : Container(
                      //         child: Text('This Ad is created by You!!'),
                      //       ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      const Divider(
                        thickness: 7,
                      ),

                      ///
                      if (products[0].catName == "Vehicle" ||
                          products[0].catName == "Electronics" ||
                          products[0].catName == "Home Appliances")
                        Column(
                          children: [
                            const SizedBox(
                              height: 7,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0, right: 15.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: RichText(
                                        text: const TextSpan(
                                          text: 'Make',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          2.5,
                                      child: RichText(
                                        text: TextSpan(
                                          text: products[0].make,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 7,
                            ),
                            const Divider(
                              thickness: 2,
                            ),
                            const SizedBox(
                              height: 7,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0, right: 15.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: RichText(
                                        text: const TextSpan(
                                          text: 'Model',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          2.5,
                                      child: RichText(
                                        text: TextSpan(
                                          text: products[0].model,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Divider(
                              thickness: 7,
                            ),
                          ],
                        ),

                      /////
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'About this product',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width - 30,
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: products[0].prodDes,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (products[0].sellerNotes != null)
                        Container(
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: Row(
                            children: [
                              RichText(
                                text: const TextSpan(
                                  text: 'Seller\'s ' 'Notes',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (products[0].sellerNotes != null)
                        Container(
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: Row(
                            children: [
                              Flexible(
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 30,
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: products[0].sellerNotes,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (products[0].sellerNotes != null)
                        const SizedBox(
                          height: 10,
                        ),
                      const Divider(
                        thickness: 7,
                      ),
                      if (prodImagesE.length > 0)
                        Container(
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  text:
                                      _catCar ? 'Exterior ' : 'Product Images ',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: '(',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text: '${prodImagesE.length}',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const TextSpan(
                                      text: ')',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (prodImagesE.length > 0)
                        const SizedBox(
                          height: 5,
                        ),
                      if (prodImagesE.length > 0)
                        Container(
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: Container(
                            height: 100,
                            child: GestureDetector(
                              child: ListView.builder(
                                  itemCount: prodImagesE.length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 100,
                                      child: Image.network(
                                        prodImagesE[index].imageUrl,
                                        fit: BoxFit.cover,
                                        // width: MediaQuery.of(context).size.width,
                                      ),
                                    );
                                  }),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) {
                                        return Photos(
                                          imageList: prodImages,
                                        );
                                      },
                                      fullscreenDialog: true),
                                );
                              },
                            ),
                          ),
                        ),
                      if (prodImagesE.length > 0)
                        const SizedBox(
                          height: 10,
                        ),
                      if (prodImagesE.length > 0)
                        const Divider(
                          thickness: 7,
                        ),
                      if (prodImagesI.length > 0)
                        Container(
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: 'Interior ',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: '(',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text: '${prodImagesI.length}',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const TextSpan(
                                      text: ')',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (prodImagesI.length > 0)
                        const SizedBox(
                          height: 5,
                        ),
                      if (prodImagesI.length > 0)
                        Container(
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: Container(
                            height: 100,
                            child: ListView.builder(
                                itemCount: prodImagesI.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 100,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) {
                                                return Photos(
                                                  imageList: prodImages,
                                                );
                                              },
                                              fullscreenDialog: true),
                                        );
                                      },
                                      child: Image.network(
                                        prodImagesI[index].imageUrl,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      if (prodImagesI.length > 0)
                        const SizedBox(
                          height: 10,
                        ),
                      if (prodImagesI.length > 0)
                        const Divider(
                          thickness: 7,
                        ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'Product Condition ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2,
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'Status',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2.5,
                                child: RichText(
                                  text: TextSpan(
                                    text: products[0].prodCondition,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        thickness: 7,
                      ),

                      ///
                      const SizedBox(
                        height: 7,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2,
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'Type of Ad',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2.5,
                                child: RichText(
                                  text: TextSpan(
                                    text: products[0].typeOfAd,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        thickness: 7,
                      ),

                      ///

                      const SizedBox(
                        height: 7,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2,
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'For Sale By',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2.5,
                                child: RichText(
                                  text: TextSpan(
                                    text: products[0].forSaleBy,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        thickness: 7,
                      ),

                      ///
                      if (ctmSpecialInfos.length > 0)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0, right: 15.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: RichText(
                                      text: TextSpan(
                                        text: _catCar
                                            ? 'Vehicle Specs'
                                            : 'Product Specs',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            if (_catCar)
                              Container(
                                padding: const EdgeInsets.only(
                                    left: 15.0, right: 15.0),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                2,
                                        child: RichText(
                                          text: const TextSpan(
                                            text: 'VIN',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                2.5,
                                        child: RichText(
                                          text: TextSpan(
                                            text: ctmSpecialInfos[0].vin,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_catCar)
                              const SizedBox(
                                height: 7,
                              ),
                          ],
                        ),

                      const SizedBox(
                        height: 7,
                      ),
                      if (ctmSpecialInfos.length > 0)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0, right: 15.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: RichText(
                                        text: const TextSpan(
                                          text: 'Exterior Color',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          2.5,
                                      child: RichText(
                                        text: TextSpan(
                                          text:
                                              ctmSpecialInfos[0].exteriorColor,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 7,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0, right: 15.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: RichText(
                                        text: const TextSpan(
                                          text: 'Mileage',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          2.5,
                                      child: RichText(
                                        text: TextSpan(
                                          text: ctmSpecialInfos[0].mileage,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 7,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0, right: 15.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: RichText(
                                        text: const TextSpan(
                                          text: 'Fuel Type',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          2.5,
                                      child: RichText(
                                        text: TextSpan(
                                          text: ctmSpecialInfos[0].fuelType,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            _catCar
                                ? Container(
                                    padding: const EdgeInsets.only(
                                        left: 15.0, right: 15.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                                ViewFullSpecs.routeName,
                                                arguments: ctmSpecialInfos);
                                          },
                                          child: const Text(
                                            'View full specs',
                                            style: TextStyle(color: bBlueColor),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                : Container(
                                    height: 0,
                                    width: 0,
                                  ),
                            const Divider(
                              thickness: 7,
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'User',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 3,
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: bBackgroundColor,
                                    image: DecorationImage(
                                      image: userDetails[0].userImageUrl != ""
                                          ? NetworkImage(
                                              userDetails[0].userImageUrl)
                                          : AssetImage(
                                              'assets/images/default_user_image.png'),
                                    ),
                                  ),
                                ),
                                // CircleAvatar(
                                //   radius: 25,
                                //   child: ClipOval(
                                //     // borderRadius: BorderRadius.circular(50),
                                //     child: userDetails[0].userImageUrl != ""
                                //         ? Image.network(
                                //             userDetails[0].userImageUrl,
                                //             fit: BoxFit.cover,
                                //           )
                                //         : Image.asset(
                                //             'assets/images/default_user_image.png',
                                //             fit: BoxFit.cover,
                                //           ),
                                //   ),
                                // ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2.5,
                                child: Column(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) {
                                                return UserShopScreen(
                                                    userDocId: userDetails[0]
                                                        .userDetailDocId);
                                              },
                                              fullscreenDialog: true),
                                        );
                                        // Navigator.of(context).pushNamed(
                                        //     UserShopScreen.routeName,
                                        //     arguments:
                                        //         userDetails[0].userDetailDocId);
                                      },
                                      child: Text(
                                        userDetails[0].userType !=
                                                "Private Seller"
                                            ? userDetails[0].companyName
                                            : userDetails[0].displayName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),

                                      // RichText(
                                      //   text: TextSpan(
                                      //     text: userDetails[0].userName,
                                      //     style: const TextStyle(
                                      //       color: Colors.blue,
                                      //       fontSize: 15,
                                      //       fontWeight: FontWeight.normal,
                                      //     ),
                                      //   ),
                                      // ),
                                    ),
                                    Text(userDetails[0].userType)
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        thickness: 7,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'Delivery And Payment ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Row(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width / 2,
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Delivery',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2.5,
                                child: RichText(
                                  text: TextSpan(
                                    text: products[0].deliveryInfo,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        thickness: 7,
                      ),
                      if (similarlisting.length > 0)
                        Container(
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: Row(
                            children: [
                              RichText(
                                text: const TextSpan(
                                  text: 'Explore similar listings',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(
                        height: 5,
                      ),
                      if (similarlisting.length > 0)
                        Container(
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: Container(
                            height: 100,
                            child: ListView.builder(
                                itemCount: similarlisting.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 100,
                                    padding: EdgeInsets.only(right: 5),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                            ProductDetailScreen.routeName,
                                            arguments: similarlisting[index]
                                                .prodDocId);
                                      },
                                      child: Image.network(
                                        similarlisting[index].imageUrlFeatured,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        thickness: 7,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Container(
            child: const Center(
              child: CupertinoActivityIndicator(),
            ),
          );
  }
}
