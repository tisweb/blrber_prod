//Imports for pubspec Packages
import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:blrber/screens/gmap_screen.dart';
import 'package:blrber/screens/motor_filter_screen.dart';
import 'package:blrber/screens/search_results.dart';
import 'package:blrber/widgets/chat/to_chat.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as p;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:darq/darq.dart';

import 'package:darq/darq.dart';
import 'package:share/share.dart';
import 'package:tflite/tflite.dart';
import 'package:url_launcher/url_launcher.dart';

//Imports for Models
import '../models/product.dart';
import '../models/user_detail.dart';
import '../models/category.dart';

//Imports for Providers
import '../provider/get_current_location.dart';

//Imports for Screens
import '../screens/product_detail_screen.dart';

//Imports for Services
import '../services/foundation.dart';

//Imports for Constants
import '../constants.dart';

class UserShopScreen extends StatefulWidget {
  // static const routeName = '/user-shop';
  // final UserDetail userData;
  final String userDocId;
  UserShopScreen({Key key, this.userDocId}) : super(key: key);

  @override
  _UserShopScreenState createState() => _UserShopScreenState();
}

class _UserShopScreenState extends State<UserShopScreen> {
  /// create a Drawer key
  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey<ScaffoldState>();

  /// this function opens the drawer
  void _openDrawer() => _drawerKey.currentState.openDrawer();
  List<Product> products, productsInitial = [];
  String _currencyName = "";
  String _currencySymbol = "";
  String _selectedCategory = "";
  String _selectedSubCategory = "";
  List<SubCategory> subCategories, availableProdSC = [];
  List<UserDetail> userDetails = [];
  List<UserDetail> userData = [];
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();
  List<Category> categories, availableProdC = [];
  String _linkMessage;
  bool _isCreatingLink = false;
  var _userDocId = '';
  String userId = "";
  User user;

  @override
  void didChangeDependencies() {
    // _userDocId = ModalRoute.of(context).settings.arguments as String;
    _getProviders();
    _getProductCategories();
    super.didChangeDependencies();
  }

  void _getProviders() {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      userId = "";
    } else {
      userId = user.uid;
    }
    userDetails = Provider.of<List<UserDetail>>(context);
    productsInitial = Provider.of<List<Product>>(context);
    categories = Provider.of<List<Category>>(context);
    subCategories = Provider.of<List<SubCategory>>(context);
    getCurrentLocation = Provider.of<GetCurrentLocation>(context);
    _currencyName = getCurrentLocation.currencyCode;
    _currencySymbol = getCurrencySymbolByName(_currencyName);

    userData = userDetails
        .where((e) => e.userDetailDocId.trim() == widget.userDocId.trim())
        .toList();
  }

  void _getProductCategories() {
    if (productsInitial != null) {
      productsInitial = productsInitial
          .where(
            (e) =>
                e.userDetailDocId.trim() == widget.userDocId.trim() &&
                e.status == 'Verified' &&
                e.subscription != 'Unpaid' &&
                e.listingStatus == 'Available',
          )
          .toList();
    }

    availableProdC = [];
    if (productsInitial.length > 0) {
      var distinctProductsC =
          productsInitial.distinct((d) => d.catName.trim()).toList();

      if (distinctProductsC.length > 0 && categories.length > 0) {
        for (var item in distinctProductsC) {
          List<Category> category = [];

          category = categories
              .where((e) => e.catName.trim() == item.catName.trim())
              .toList();
          if (category.length > 0) {
            availableProdC.add(category[0]);
          }
        }
      }

      if (availableProdC.length > 0) {
        availableProdC.sort((a, b) {
          var aCatName = a.catName;
          var bCatName = b.catName;
          return bCatName.compareTo(aCatName);
        });
      }
    }
  }

  void _getProducts() {
    // products = Provider.of<List<Product>>(context);
    // categories = Provider.of<List<Category>>(context);
    // subCategories = Provider.of<List<SubCategory>>(context);
    // final getCurrentLocation = Provider.of<GetCurrentLocation>(context);
    // _currencyName = getCurrentLocation.currencyCode;
    // _currencySymbol = getCurrencySymbolByName(_currencyName);

    if (productsInitial != null) {
      if (_selectedCategory == "") {
        products = productsInitial;
      } else {
        if (_selectedSubCategory == "") {
          products = productsInitial
              .where(
                (e) =>
                    e.userDetailDocId.trim() == widget.userDocId.trim() &&
                    e.catName == _selectedCategory,
              )
              .toList();
        } else {
          products = productsInitial
              .where(
                (e) =>
                    e.userDetailDocId.trim() == widget.userDocId.trim() &&
                    e.catName == _selectedCategory &&
                    e.subCatType == _selectedSubCategory,
              )
              .toList();
        }
      }
    }

    for (var i = 0; i < products.length; i++) {
      double distanceD = Geolocator.distanceBetween(
              getCurrentLocation.latitude,
              getCurrentLocation.longitude,
              products[i].latitude,
              products[i].longitude) /
          1000.round();

      String distanceS;
      if (distanceD != null) {
        distanceS = distanceD.round().toString();
      } else {
        distanceS = distanceD.toString();
      }

      products[i].distance = distanceS;
    }

    products.sort((a, b) {
      var aDistance = double.parse(a.distance);
      var bDistance = double.parse(b.distance);
      return aDistance.compareTo(bDistance);
    });

    if (_selectedSubCategory == "") {
      availableProdSC = [];
      if (products.length > 0) {
        var distinctProductsSC =
            products.distinct((d) => d.subCatType.trim()).toList();

        if (distinctProductsSC.length > 0 && subCategories.length > 0) {
          for (var item in distinctProductsSC) {
            List<SubCategory> subCategory = [];

            subCategory = subCategories
                .where((e) => e.subCatType.trim() == item.subCatType.trim())
                .toList();
            if (subCategory.length > 0) {
              availableProdSC.add(subCategory[0]);
            }
          }
        }

        if (availableProdSC.length > 0) {
          availableProdSC.sort((a, b) {
            var aSubCatType = a.subCatType;
            var bSubCatType = b.subCatType;
            return bSubCatType.compareTo(aSubCatType);
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

  Future<void> _socialShare(BuildContext context, String userDocId) async {
    await _createDynamicLink(true, userDocId);
    final RenderBox box = context.findRenderObject();
    final String text = _linkMessage;
    Share.share(text,
        subject: text,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }

  Future<void> _createDynamicLink(bool short, String userDocId) async {
    setState(() {
      _isCreatingLink = true;
    });

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://blrberprod.page.link',
      link: Uri.parse('https://blrber.com/?view=UserShopScreen&id=$userDocId'),
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

  Widget _appDrawer() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userData[0].userImageUrl != null &&
                        userData[0].userImageUrl != ""
                    ? Container(
                        height: 60,
                        width: 60,
                        child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: userData[0].userImageUrl,
                          placeholder: (context, url) => Container(
                            height: 0,
                            width: 0,
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                      )
                    : Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bScaffoldBackgroundColor,
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: AssetImage(
                                  'assets/images/default_user_image.png')),
                        ),
                      ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        userData[0].userType != "Private Seller"
                            ? userData[0].companyName
                            : userData[0].displayName,
                        overflow: TextOverflow.ellipsis),
                    Text(userData[0].userType),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            ListTile(
              leading: Text(
                "Filter",
                style: TextStyle(color: bDisabledColor, fontSize: 16),
              ),
              trailing: Icon(
                CupertinoIcons.slider_horizontal_3,
                color: bPrimaryColor,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) {
                        return MotorFilterScreen(
                          catName: _selectedCategory != "" &&
                                  _selectedCategory != null
                              ? _selectedCategory
                              : "Vehicle",
                          subCatType: _selectedSubCategory != "" &&
                                  _selectedSubCategory != null
                              ? _selectedSubCategory
                              : "",
                        );
                      },
                      fullscreenDialog: true),
                );
              },
            ),
            ListTile(
              leading: Text(
                "Search",
                style: TextStyle(color: bDisabledColor, fontSize: 16),
              ),
              trailing: Icon(
                Icons.search,
                color: bPrimaryColor,
              ),
              onTap: () {
                showSearch(
                  context: context,
                  delegate: ItemsSearch(
                      products: products, currencySymbol: _currencySymbol),
                );
              },
            ),
            ListTile(
              leading: SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: Text(
                  products[0].addressLocation,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: bBlueColor),
                ),
              ),
              trailing: Icon(
                Icons.location_on_outlined,
                color: bPrimaryColor,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) {
                        return GMapScreen(
                          lat: products[0].latitude,
                          long: products[0].longitude,
                          addressLocation: products[0].addressLocation,
                        );
                      },
                      fullscreenDialog: true),
                );
              },
            ),
            if (userId.trim() != products[0].userDetailDocId.trim() &&
                userId != "")
              ListTile(
                leading: Text(
                  "Chat",
                  style: TextStyle(color: bDisabledColor, fontSize: 16),
                ),
                trailing: Icon(
                  Icons.chat,
                  color: bPrimaryColor,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) {
                          return ToChat(
                              userIdFrom: userId.trim(),
                              userIdTo: products[0].userDetailDocId.trim(),
                              prodName: 'Buyer / Seller Enquiry');
                        },
                        fullscreenDialog: true),
                  );
                },
              ),
            if (userDetails[0].phoneNumber != null &&
                userDetails[0].phoneNumber != "")
              ListTile(
                leading: Text(
                  "Call",
                  style: TextStyle(color: bDisabledColor, fontSize: 16),
                ),
                trailing: Icon(
                  Icons.call,
                  color: bPrimaryColor,
                ),
                onTap: () {
                  setState(() {
                    _makePhoneCall('tel:${userDetails[0].phoneNumber}');
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // _userDocId = ModalRoute.of(context).settings.arguments as String;
    // if (_userDocId != "" || _userDocId != null) {
    //   _getProviders();
    //   _getProductCategories();
    //   _getProducts();
    // }

    _getProducts();
    return userData.length > 0
        ? Scaffold(
            key: _drawerKey,
            appBar: AppBar(
              backgroundColor: bScaffoldBackgroundColor,
              title: userData[0].userType != 'Private Seller'
                  ? Text(
                      '${userData[0].companyName}',
                      style: TextStyle(
                        color: bDisabledColor,
                      ),
                    )
                  : Text(
                      '${userData[0].displayName}',
                      style: TextStyle(
                        color: bDisabledColor,
                      ),
                    ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.share,
                    color: bDisabledColor,
                  ),
                  onPressed: () async {
                    await _socialShare(context, userData[0].userDetailDocId);
                  },
                ),
              ],
              leading: Row(
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: bDisabledColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: bDisabledColor,
                      ),
                      onPressed: () {
                        _openDrawer();
                      },
                    ),
                  ),
                ],
              ),
            ),
            drawer: Drawer(
              child: _appDrawer(),
            ),
            body: Column(
              children: [
                // Container(
                //   padding: EdgeInsets.all(10),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.start,
                //     children: [
                //       userData[0].userImageUrl != null &&
                //               userData[0].userImageUrl != ""
                //           ? Container(
                //               height: 60,
                //               width: 60,
                //               child: CachedNetworkImage(
                //                 fit: BoxFit.cover,
                //                 imageUrl: userData[0].userImageUrl,
                //                 placeholder: (context, url) => Container(
                //                   height: 0,
                //                   width: 0,
                //                 ),
                //                 errorWidget: (context, url, error) =>
                //                     Icon(Icons.error),
                //               ),
                //             )
                //           : Container(
                //               height: 60,
                //               width: 60,
                //               decoration: BoxDecoration(
                //                 shape: BoxShape.circle,
                //                 color: bScaffoldBackgroundColor,
                //                 image: DecorationImage(
                //                     fit: BoxFit.cover,
                //                     image: AssetImage(
                //                         'assets/images/default_user_image.png')),
                //               ),
                //             ),
                //       SizedBox(
                //         width: 10,
                //       ),
                //       Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //               userData[0].userType == "Dealer"
                //                   ? userData[0].companyName
                //                   : userData[0].userName,
                //               overflow: TextOverflow.ellipsis),
                //           Row(
                //             children: [
                //               Text(userData[0].userType),
                //               SizedBox(
                //                 width: 20,
                //               ),
                //             ],
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Container(
                //     height: 40,
                //     child: Container(
                //       // height: (MediaQuery.of(context).size.height) / 30,
                //       decoration: BoxDecoration(
                //           color: bScaffoldBackgroundColor,
                //           borderRadius: BorderRadius.all(
                //             Radius.circular(10),
                //           ),
                //           boxShadow: [
                //             BoxShadow(
                //               color: Colors.grey,
                //               blurRadius: 2.0,
                //             ),
                //           ]),
                //       child: Container(
                //         child: TextButton.icon(
                //           label: Container(
                //             child: Text(
                //               "Search Product / Category ",
                //               style: TextStyle(color: bDisabledColor),
                //             ),
                //           ),
                //           // alignment: Alignment.centerLeft,
                //           onPressed: () {
                //             showSearch(
                //               context: context,
                //               delegate: ItemsSearch(
                //                   products: products,
                //                   currencySymbol: _currencySymbol),
                //             );
                //           },
                //           icon: Icon(
                //             Icons.search,
                //             color: bDisabledColor,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                Container(
                  height: (MediaQuery.of(context).size.height) / 13,
                  color: bPrimaryColor,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(
                            Icons.home,
                            color: bBackgroundColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = "";
                            });
                          },
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemExtent: 120,
                          itemCount: availableProdC.length,
                          itemBuilder: (BuildContext context, int i) {
                            return Container(
                              padding: EdgeInsets.only(left: 10),
                              child: TextButton(
                                child: Text(
                                  availableProdC[i].catName,
                                  style: TextStyle(color: bBackgroundColor),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory =
                                        availableProdC[i].catName;
                                    _selectedSubCategory = "";
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedCategory != "")
                  Container(
                    height: (MediaQuery.of(context).size.height) / 13,
                    color: bBackgroundColor,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemExtent: 130,
                      itemCount: availableProdSC.length,
                      itemBuilder: (BuildContext context, int i) {
                        return Container(
                          padding: EdgeInsets.only(left: 10),
                          child: TextButton(
                            child: Text(availableProdSC[i].subCatType),
                            onPressed: () {
                              setState(() {
                                _selectedSubCategory =
                                    availableProdSC[i].subCatType;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                products.length > 0
                    ? Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                // height: 150.00,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CarouselSlider(
                                    items: products
                                        .map((item) => Container(
                                              width: double.infinity,
                                              child: Center(
                                                  child: Image.network(
                                                      item.imageUrlFeatured)),
                                              color: Colors.white,
                                            ))
                                        .toList(),
                                    options: CarouselOptions(
                                      autoPlay: true,
                                      enlargeCenterPage: true,
                                      // enlargeStrategy:
                                      //     CenterPageEnlargeStrategy.height,
                                      viewportFraction: 1,
                                      aspectRatio: 2.0,
                                      // initialPage: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(10.0),
                                  physics: ScrollPhysics(),
                                  itemCount: products.length,
                                  itemBuilder: (BuildContext context, int j) {
                                    return Container(
                                      color: bBackgroundColor,
                                      padding: EdgeInsets.all(5),
                                      child: ListTile(
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                              ProductDetailScreen.routeName,
                                              arguments: products[j].prodDocId);
                                        },
                                        title: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                child: products[j]
                                                            .imageUrlFeatured !=
                                                        null
                                                    ? CachedNetworkImage(
                                                        fit: BoxFit.cover,
                                                        imageUrl: products[j]
                                                            .imageUrlFeatured,
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
                                                          height: 0,
                                                          width: 0,
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Icon(Icons.error),
                                                      )
                                                    // Image(
                                                    //     image: NetworkImage(
                                                    //       products[j].imageUrlFeatured,
                                                    //     ),
                                                    //     fit: BoxFit.fill,
                                                    //   )
                                                    : Container(
                                                        child: Center(
                                                          child: const Text(
                                                              'Image Loading...'),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Container(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    products[j]
                                                                .prodName
                                                                .length >
                                                            25
                                                        ? products[j]
                                                                .prodName
                                                                .substring(
                                                                    0, 25) +
                                                            '...'
                                                        : products[j].prodName,
                                                    style: TextStyle(
                                                        color: bDisabledColor,
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  RichText(
                                                    text: TextSpan(
                                                      text: _currencySymbol,
                                                      style: const TextStyle(
                                                        color: bDisabledColor,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      children: [
                                                        const TextSpan(
                                                          text: ' ',
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              products[j].price,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  RichText(
                                                    text: TextSpan(
                                                      text: 'Status : ',
                                                      style: const TextStyle(
                                                        color: bDisabledColor,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: products[j]
                                                              .status,
                                                          style: TextStyle(
                                                            color: products[j]
                                                                        .status ==
                                                                    'Verified'
                                                                ? Colors.green
                                                                : Colors.red,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 6 / 6,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        child: Center(
                          child: Text(
                              "Do not have verified products to list in the eShop!"),
                        ),
                      ),
              ],
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: bScaffoldBackgroundColor,
              title: Text(
                'eShop',
                style: TextStyle(
                  color: bDisabledColor,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: bDisabledColor,
                  )),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
  }
}

class ItemsSearch extends SearchDelegate<String> {
  String selectedItem = "";
  File pickedImage;
  String imageLabelS = '';
  String prodName;

  List<Product> products;
  String currencySymbol;

  ItemsSearch({this.products, this.currencySymbol});

  stt.SpeechToText _speech;

  bool _listeningState = false;
  String _text = '';
  double _confidence = 1.0;
  bool available = false;
  bool _isListening = false;

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    print('Listen function called!');
    available = await _speech.initialize(
      onStatus: (val) {
        print('onStatus: $val');
      },
      onError: (val) {
        print('onError: $val');
      },
    );
  }

  void _showListenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              content: Container(
                height: MediaQuery.of(context).size.height / 3,
                child: Column(
                  children: [
                    Expanded(
                      child: const Text("Name of the product"),
                    ),
                    Expanded(
                      child: AvatarGlow(
                        animate: _isListening,
                        glowColor: bPrimaryColor,
                        endRadius: 75.0,
                        duration: const Duration(milliseconds: 2000),
                        repeatPauseDuration: const Duration(milliseconds: 100),
                        repeat: true,
                        child: FloatingActionButton(
                          backgroundColor: bPrimaryColor,
                          onPressed: () async {
                            if (!_isListening) {
                              available = await _speech.initialize(
                                onStatus: (val) {
                                  print('onStatus: $val');
                                },
                                onError: (val) {
                                  print('onErrorss: $val');
                                },
                              );

                              if (available) {
                                setState(() {
                                  _isListening = true;
                                });

                                _speech.listen(
                                  onResult: (val) {
                                    _text = val.recognizedWords;

                                    _listeningState = val.finalResult;

                                    if (val.hasConfidenceRating &&
                                        val.confidence > 0) {
                                      _confidence = val.confidence;
                                    }

                                    if (_listeningState == true) {
                                      setState(() {
                                        query = _text;

                                        _isListening = false;
                                      });

                                      // Future.delayed(Duration(seconds: 1), () {
                                      Navigator.of(context).pop();

                                      Navigator.of(context).pushNamed(
                                          SearchResults.routeName,
                                          arguments: query);
                                      // });
                                    }
                                  },
                                );
                              }
                            } else {
                              setState(() {
                                _isListening = false;
                              });
                              _speech.stop();
                            }
                          },
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: Text(query))
                  ],
                ),
              ),
              actions: <Widget>[],
            );
          },
        );
      },
    );
  }

  Future<String> _pickImageS() async {
    try {
      final picker = ImagePicker();
      final imageFile = await picker.getImage(source: ImageSource.gallery);

      if (imageFile == null) {
        return null;
      }
      pickedImage = File(imageFile.path);

      if (pickedImage != null) {
        prodName = await runModelOnImageS(); // It is to run with tflite model
        // prodName = await findLabels(
        //     pickedImage); // It is to run with google ml vision model
      }
    } on PlatformException catch (e) {
      print('Image picker PlatformException error - ${e.code}');
      if (e.code.trim() == "photo_access_denied") {
        return '1';
      }
    } catch (e) {
      print('Image picker error - $e');
      return '2';
    }
    return prodName;
  }

  // Future<String> findLabels(File _image) async {
  //   List<ImageLabelInfo> _imageLabels = [];
  //   final GoogleVisionImage visionImage = GoogleVisionImage.fromFile(_image);

  //   final ImageLabeler labeler = GoogleVision.instance
  //       .imageLabeler(ImageLabelerOptions(confidenceThreshold: 0.80));

  //   final List<ImageLabel> labels = await labeler.processImage(visionImage);

  //   for (ImageLabel label in labels) {
  //     ImageLabelInfo _imageLabel = ImageLabelInfo();
  //     _imageLabel.imageLabel = label.text;
  //     _imageLabel.confidence = label.confidence;

  //     _imageLabels.add(_imageLabel);
  //   }

  //   if (_imageLabels.length > 0) {
  //     _imageLabels.sort((a, b) {
  //       var aConfidence = a.confidence;
  //       var bConfidence = b.confidence;
  //       return aConfidence.compareTo(bConfidence);
  //     });
  //   }

  //   return _imageLabels[_imageLabels.length - 1].imageLabel;
  // }

  Future<String> runModelOnImageS() async {
    var output = await Tflite.runModelOnImage(
      path: pickedImage.path,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 2,
      threshold: 0.8,
    );

    if (output.length > 0) {
      imageLabelS = output[0]["label"];

      // var imageLabelOut =
      //     imageLabelS.split(" ")[0] + " " + imageLabelS.split(" ")[1];
      var imageLabelOut = imageLabelS.split(",")[1];
      return imageLabelOut;
    } else {
      return "Not Found";
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query != "")
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = "";
          },
        )
      // : IconButton(
      //     icon: Icon(Icons.mic),
      //     onPressed: () async {
      //       var status = await p.Permission.microphone.status;
      //       print("microphone status search - $status");

      //       if (status.isGranted) {
      //         _initSpeech();

      //         _showListenDialog(context);
      //       } else {
      //         showDialog(
      //           context: context,
      //           builder: (BuildContext context) => CupertinoAlertDialog(
      //             title: Text('Microphone Permission'),
      //             content: Text('This app needs Microphone access'),
      //             actions: <Widget>[
      //               CupertinoDialogAction(
      //                 child: Text('Deny'),
      //                 onPressed: () => Navigator.of(context).pop(),
      //               ),
      //               CupertinoDialogAction(
      //                 child: Text('Settings'),
      //                 onPressed: () => openAppSettings(),
      //               ),
      //             ],
      //           ),
      //         );
      //       }
      //     },
      //   ),
      // IconButton(
      //   icon: Icon(Icons.camera_alt_outlined),
      //   onPressed: () async {
      //     var prodNameS;
      //     var status = await p.Permission.photos.status;
      //     print("photos status search - $status");

      //     prodNameS = await _pickImageS();

      //     if (prodNameS == '1') {
      //       showDialog(
      //           context: context,
      //           builder: (BuildContext context) => CupertinoAlertDialog(
      //                 title: Text('Camera Permission'),
      //                 content: Text(
      //                     'This app needs camera access to take / choose pictures'),
      //                 actions: <Widget>[
      //                   CupertinoDialogAction(
      //                     child: Text('Deny'),
      //                     onPressed: () => Navigator.of(context).pop(),
      //                   ),
      //                   CupertinoDialogAction(
      //                     child: Text('Settings'),
      //                     onPressed: () => openAppSettings(),
      //                   ),
      //                 ],
      //               ));
      //     }
      //     // var prodNameS = await _pickImageS();
      //     if (prodNameS != "Not Found" &&
      //         prodNameS != "" &&
      //         prodNameS != null) {
      //       query = prodNameS;
      //       Navigator.of(context)
      //           .pushNamed(SearchResults.routeName, arguments: query);
      //     } else {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         SnackBar(
      //           content: Text('Product Not found'),
      //         ),
      //       );
      //     }
      //   },
      // ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.home),
      onPressed: () {
        close(context, selectedItem);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final prodList = products
        .where((p) =>
            (p.prodName.toLowerCase().trim())
                .contains(selectedItem.toLowerCase().trim()) ||
            (p.catName.toLowerCase().trim())
                .contains(selectedItem.toLowerCase().trim()) ||
            (p.subCatType.toLowerCase().trim())
                .contains(selectedItem.toLowerCase().trim()) ||
            (p.prodDes.toLowerCase().trim())
                .contains(selectedItem.toLowerCase().trim()) ||
            (p.make.toLowerCase().trim())
                .contains(selectedItem.toLowerCase().trim()) ||
            (p.model.toLowerCase().trim())
                .contains(selectedItem.toLowerCase().trim()))
        .toList();

    return Scrollbar(
      child: GridView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: prodList.length,
        itemBuilder: (BuildContext context, int j) {
          return Container(
            color: bBackgroundColor,
            padding: EdgeInsets.all(5),
            child: ListTile(
              onTap: () {
                Navigator.of(context).pushNamed(ProductDetailScreen.routeName,
                    arguments: prodList[j].prodDocId);
              },
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      child: prodList[j].imageUrlFeatured != null
                          ? CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl: prodList[j].imageUrlFeatured,
                              placeholder: (context, url) => Container(
                                height: 0,
                                width: 0,
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            )
                          // Image(
                          //     image: NetworkImage(
                          //       products[j].imageUrlFeatured,
                          //     ),
                          //     fit: BoxFit.fill,
                          //   )
                          : Container(
                              child: Center(
                                child: const Text('Image Loading...'),
                              ),
                            ),
                    ),
                  ),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prodList[j].prodName.length > 25
                              ? prodList[j].prodName.substring(0, 25) + '...'
                              : prodList[j].prodName,
                          style: TextStyle(
                              color: bDisabledColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        RichText(
                          text: TextSpan(
                            text: currencySymbol,
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
                                text: prodList[j].price,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
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
                                text: prodList[j].status,
                                style: TextStyle(
                                  color: prodList[j].status == 'Verified'
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
                ],
              ),
            ),
          );
        },
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 3 / 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    print("query - ${query}");
    final myList = query.isEmpty
        ? []
        : products
            .where((p) =>
                (p.prodName.toLowerCase().trim())
                    .contains(query.toLowerCase().trim()) ||
                (p.catName.toLowerCase().trim())
                    .contains(query.toLowerCase().trim()) ||
                (p.subCatType.toLowerCase().trim())
                    .contains(query.toLowerCase().trim()) ||
                (p.prodDes.toLowerCase().trim())
                    .contains(query.toLowerCase().trim()) ||
                (p.make.toLowerCase().trim())
                    .contains(query.toLowerCase().trim()) ||
                (p.model.toLowerCase().trim())
                    .contains(query.toLowerCase().trim()))
            .toList();
    print("query 1 - ${query}");
    return myList.isEmpty
        ? Container(
            padding: EdgeInsets.only(top: 10, left: 10),
            child: Text('Search Items...'))
        : ListView.builder(
            itemCount: myList.length,
            itemBuilder: (context, index) {
              final Product listItem = myList[index];
              selectedItem = myList[0].prodName;
              return ListTile(
                title: Row(
                  children: [
                    Text(listItem.prodName),
                    SizedBox(
                      width: 20,
                    ),
                    TextButton(
                        onPressed: () {
                          selectedItem = listItem.catName;
                          showResults(context);
                        },
                        child: Text(listItem.catName))
                  ],
                ),
                onTap: () {
                  selectedItem = listItem.prodName;

                  showResults(context);
                },
              );
            },
          );
  }
}
