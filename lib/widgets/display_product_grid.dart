//Imports for pubspec Packages
import 'package:blrber/helpers/ad_helper.dart';
import 'package:blrber/screens/tabs_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'package:darq/darq.dart';

//Imports for Constants
import '../constants.dart';
//Imports for Models
import '../models/product.dart';
import '../models/category.dart';
import '../models/user_detail.dart';
//Imports for Provider
import '../provider/get_current_location.dart';
//Imports for Screens
import '../screens/motor_filter_screen.dart';
import '../screens/product_detail_screen.dart';

const int maxFailedLoadAttempts = 3;

class DisplayProductGrid extends StatefulWidget {
  final String inCatName;

  final String inProdCondition;
  final String inDisplayType;
  final List<String> inqueriedProdIdList;

  DisplayProductGrid({
    @required this.inCatName,
    @required this.inProdCondition,
    @required this.inDisplayType,
    this.inqueriedProdIdList,
  });

  @override
  _DisplayProductGridState createState() => _DisplayProductGridState();
}

class _DisplayProductGridState extends State<DisplayProductGrid> {
  String userId = "";

  bool isFavorite = false;
  bool _subCatTypeSelected = false;
  // Icon favoriteIcon = Icon(Icons.favorite_border);

  String _countryCode = "";

  List<Product> productsQuery = [];

  List<UserDetail> userDetails = [];
  List<Product> products = [];
  User user;

  String _subCatType = "";
  List<SubCategory> subCategories, availableProdSC = [];
  List<FavoriteProd> favoriteProd = [];
  String currCondition = "";
  bool status = false;
  String _prodCondition = "";

  GetCurrentLocation getCurrentLocation = GetCurrentLocation();
  InterstitialAd _interstitialAd;
  int _interstitialLoadAttempts = 0;
  BannerAd _inlineBannerAd;
  final _inlineAdIndex = 3;
  bool _isInlineBannerAdLoaded = false;

  int _getListViewItemIndex(int index) {
    if (index >= _inlineAdIndex && _isInlineBannerAdLoaded) {
      return index - 1;
    }
    return index;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _initialGetInfo() {
    user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      userId = "";
    } else {
      userId = user.uid;
      userDetails = Provider.of<List<UserDetail>>(context);
      if (userDetails.length > 0 && user != null) {
        var userData = userDetails
            .where((e) => e.userDetailDocId.trim() == userId.trim())
            .toList();
        if (userData.length > 0) {
          _countryCode = userData[0].buyingCountryCode;
        }
      }
    }

    products = Provider.of<List<Product>>(context);
    subCategories = Provider.of<List<SubCategory>>(context);
    favoriteProd = Provider.of<List<FavoriteProd>>(context);
    getCurrentLocation = Provider.of<GetCurrentLocation>(context);

    if (_countryCode.isEmpty) {
      _countryCode = getCurrentLocation.countryCode;
    }

    if (products != null) {
      products = products
          .where((e) =>
              e.status == 'Verified' &&
              e.subscription != 'Unpaid' &&
              e.listingStatus == 'Available' &&
              e.countryCode == _countryCode)
          .toList();
    }

    if (products != null) {
      if (widget.inDisplayType == "Category") {
        products =
            products.where((e) => e.catName == widget.inCatName).toList();
      } else if (widget.inDisplayType == "Search") {
        var singularCatName = "";

        if (widget.inCatName != "" && widget.inCatName != null) {
          singularCatName =
              widget.inCatName.substring(0, (widget.inCatName.length - 1));
        } else {
          products = [];
        }

        products = products
            .where((e) =>
                (e.catName
                    .toLowerCase()
                    .trim()
                    .contains(widget.inCatName.toLowerCase().trim())) ||
                (e.catName
                    .toLowerCase()
                    .trim()
                    .contains(singularCatName.toLowerCase().trim())) ||
                (e.prodName
                    .toLowerCase()
                    .trim()
                    .contains(widget.inCatName.toLowerCase().trim())) ||
                (e.prodName
                    .toLowerCase()
                    .trim()
                    .contains(singularCatName.toLowerCase().trim())) ||
                (e.subCatType
                    .toLowerCase()
                    .trim()
                    .contains(widget.inCatName.toLowerCase().trim())) ||
                (e.subCatType
                    .toLowerCase()
                    .trim()
                    .contains(singularCatName.toLowerCase().trim())) ||
                (e.prodDes
                    .toLowerCase()
                    .trim()
                    .contains(widget.inCatName.toLowerCase().trim())) ||
                (e.prodDes
                    .toLowerCase()
                    .trim()
                    .contains(singularCatName.toLowerCase().trim())) ||
                // (e.sellerNotes
                //     .toLowerCase()
                //     .trim()
                //     .contains(widget.inCatName.toLowerCase().trim())) ||
                // (e.sellerNotes
                //     .toLowerCase()
                //     .trim()
                //     .contains(singularCatName.toLowerCase().trim())) ||
                (e.make
                    .toLowerCase()
                    .trim()
                    .contains(widget.inCatName.toLowerCase().trim())) ||
                (e.make
                    .toLowerCase()
                    .trim()
                    .contains(singularCatName.toLowerCase().trim())) ||
                (e.model
                    .toLowerCase()
                    .trim()
                    .contains(widget.inCatName.toLowerCase().trim())) ||
                (e.model.toLowerCase().contains(singularCatName.toLowerCase())))
            .toList();
      } else if (widget.inDisplayType == "Results" &&
          widget.inqueriedProdIdList != null) {
        productsQuery = [];

        for (var i = 0; i < widget.inqueriedProdIdList.length; i++) {
          List<Product> prodTemp = [];
          prodTemp = products
              .where((p) =>
                  p.prodDocId.trim() == widget.inqueriedProdIdList[i].trim())
              .toList();
          productsQuery = productsQuery + prodTemp;
        }

        products = productsQuery;
      }

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

        if (_subCatTypeSelected) {
          products = products
              .where((e) => e.subCatType.trim() == _subCatType.trim())
              .toList();
        }

        if (products.any((e) => e.prodCondition == 'New') &&
            products.any((e) => e.prodCondition == 'Used')) {
          currCondition = "NU";
        } else {
          if (products.any((e) => e.prodCondition == 'New')) {
            currCondition = "N";
          }
          if (products.any((e) => e.prodCondition == 'Used')) {
            currCondition = "U";
          }
        }

        if (widget.inDisplayType != "Results") {
          if (currCondition == "NU") {
            if (_prodCondition == "New" || _prodCondition == "Used") {
              products = products
                  .where((e) => e.prodCondition.trim() == _prodCondition.trim())
                  .toList();
            } else {
              status = true;
              products = products
                  .where((e) => e.prodCondition.trim() == "Used".trim())
                  .toList();
            }
          }
        }

        products.sort((a, b) {
          var aDistance = double.parse(a.distance);
          var bDistance = double.parse(b.distance);
          return aDistance.compareTo(bDistance);
        });
      }
    }
  }

  void showAlertDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text("Add to Favorites?"),
            content: Text("Please login to add items in Favorites!"),
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
  void initState() {
    super.initState();
    _createInterstitialAd();
    _createInlineBannerAd();
  }

  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
    _inlineBannerAd.dispose();
  }

  void _createInlineBannerAd() {
    _inlineBannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isInlineBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _inlineBannerAd.load();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback:
            InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        }, onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createInterstitialAd();
          }
        }));
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _createInterstitialAd();
      }, onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _createInterstitialAd();
      });
      _interstitialAd.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    _initialGetInfo();

    return (products.length > 0)
        ? Container(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 5,
                    child: Container(
                      color: bBackgroundColor,
                    ),
                  ),
                  if (availableProdSC.length > 0)
                    if (widget.inDisplayType != "Results" &&
                        widget.inDisplayType != "Search")
                      Flexible(
                        child: Container(
                          color: bBackgroundColor,
                          height: MediaQuery.of(context).size.height / 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Flexible(
                                flex: 1,
                                child: Container(
                                  width: MediaQuery.of(context).size.width / 4,
                                  child: currCondition == "NU"
                                      ? FlutterSwitch(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              5,
                                          activeColor: cupActiveGreen,
                                          inactiveColor: cupActiveBlue,
                                          activeText: 'Used',
                                          inactiveText: 'New',
                                          value: status,
                                          showOnOff: true,
                                          onToggle: (val) {
                                            setState(() {
                                              status = val;
                                              if (status == true) {
                                                setState(() {
                                                  _prodCondition = 'Used';
                                                });
                                              } else {
                                                setState(() {
                                                  _prodCondition = 'New';
                                                });
                                              }
                                            });
                                          },
                                        )
                                      : currCondition == "N"
                                          ? Container(
                                              height: 25,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(25),
                                                ),
                                                border: Border.all(
                                                    color: cupActiveGreen),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 1),
                                                child: const Text(
                                                  "New",
                                                  style: const TextStyle(
                                                      color: bDisabledColor,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              height: 25,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(25),
                                                  ),
                                                  border: Border.all(
                                                      color: cupActiveBlue)
                                                  // color: bPrimaryColor,
                                                  ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 1),
                                                child: const Text(
                                                  "Used",
                                                  style: const TextStyle(
                                                      color: bDisabledColor,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                ),
                              ),
                              Flexible(
                                child: Container(
                                  width: MediaQuery.of(context).size.width / 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) {
                                              return MotorFilterScreen(
                                                  catName: widget.inCatName,
                                                  subCatType: _subCatType != ''
                                                      ? _subCatType
                                                      : availableProdSC[0]
                                                          .subCatType);
                                            },
                                            fullscreenDialog: true),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Flexible(
                                          flex: 1,
                                          child: const Icon(
                                            CupertinoIcons.slider_horizontal_3,
                                            color: bPrimaryColor,
                                          ),
                                        ),
                                        Flexible(
                                          flex: 1,
                                          child: const SizedBox(
                                            width: 10,
                                          ),
                                        ),
                                        Flexible(
                                          flex: 3,
                                          child: const Text(
                                            'Filters',
                                            style: TextStyle(
                                              color: bPrimaryColor,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(
                    height: 5,
                  ),
                  Flexible(
                    child: Container(
                      color: bBackgroundColor,
                      height: MediaQuery.of(context).size.height / 8,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (availableProdSC.length > 1)
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, left: 10),
                                child: GestureDetector(
                                  child: CircleAvatar(
                                    backgroundColor: bBackgroundColor,
                                    radius: 30,
                                    child: Text(
                                      'All',
                                      style: TextStyle(
                                          color: _subCatTypeSelected
                                              ? Colors.grey[800]
                                              : bPrimaryColor),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _subCatTypeSelected = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                          Flexible(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10, left: 10),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemExtent: 90,
                                scrollDirection: Axis.horizontal,
                                itemCount: availableProdSC.length,
                                itemBuilder: (BuildContext context, int s) {
                                  return Container(
                                    width:
                                        MediaQuery.of(context).size.width / 5,
                                    child: GestureDetector(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            // flex: 2,
                                            child: availableProdSC[s]
                                                            .imageUrl ==
                                                        "" ||
                                                    availableProdSC[s]
                                                            .imageUrl ==
                                                        null
                                                ? CircleAvatar(
                                                    radius: 30,
                                                    backgroundImage: AssetImage(
                                                      'assets/images/default_user_image.png',
                                                    ),
                                                  )
                                                : Container(
                                                    height: 60,
                                                    width: 60,

                                                    // decoration: BoxDecoration(
                                                    //   shape: BoxShape.circle,
                                                    //   color: bBackgroundColor,
                                                    //   image: DecorationImage(
                                                    //     fit: BoxFit.fill,
                                                    //     image: NetworkImage(
                                                    //         availableProdSC[s]
                                                    //             .imageUrl),
                                                    //   ),
                                                    // )

                                                    child: CachedNetworkImage(
                                                      fit: BoxFit.cover,
                                                      imageUrl:
                                                          availableProdSC[s]
                                                              .imageUrl,
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        height: 0,
                                                        width: 0,
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Icon(Icons.error),
                                                    ),
                                                  ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                '${availableProdSC[s].subCatType}',
                                                // overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _subCatType !=
                                                              availableProdSC[s]
                                                                  .subCatType ||
                                                          !_subCatTypeSelected
                                                      ? Colors.grey[800]
                                                      : bPrimaryColor,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _subCatTypeSelected = true;
                                          _subCatType =
                                              availableProdSC[s].subCatType;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: products.length,
                        itemBuilder: (BuildContext context, int j) {
                          return Container(
                            color: bBackgroundColor,
                            padding: const EdgeInsets.all(5),
                            child: GestureDetector(
                              onTap: () {
                                _showInterstitialAd();
                                Navigator.of(context).pushNamed(
                                    ProductDetailScreen.routeName,
                                    arguments: products[j].prodDocId);
                              },
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            imageUrl:
                                                products[j].imageUrlFeatured,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 0,
                                              width: 0,
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                        ),
                                        // FractionallySizedBox(
                                        //   widthFactor:
                                        //       1.0, // width w.r.t to parent
                                        //   heightFactor:
                                        //       1.0, // height w.r.t to parent
                                        //   child: ClipRRect(
                                        //     child: Container(
                                        //       // height: 80,
                                        //       // width: 80,
                                        //       decoration: BoxDecoration(
                                        //         shape: BoxShape.rectangle,
                                        //         color: bBackgroundColor,
                                        //         // image: DecorationImage(
                                        //         //   image: NetworkImage(products[j]
                                        //         //       .imageUrlFeatured),
                                        //         // ),
                                        //       ),
                                        //       child: CachedNetworkImage(
                                        //         fit: BoxFit.cover,
                                        //         imageUrl:
                                        //             products[j].imageUrlFeatured,
                                        //         placeholder: (context, url) =>
                                        //             Container(
                                        //           height: 0,
                                        //           width: 0,
                                        //         ),
                                        //         errorWidget:
                                        //             (context, url, error) =>
                                        //                 Icon(Icons.error),
                                        //       ),
                                        //     ),

                                        //     // FadeInImage.assetNetwork(
                                        //     //   fit: BoxFit.fill,
                                        //     //   width: 50,
                                        //     //   height: 50,
                                        //     //   placeholder:
                                        //     //       'assets/images/image_loading.gif',
                                        //     //   image: products[j].imageUrlFeatured,
                                        //     // ),
                                        //     // Image(
                                        //     //   image: NetworkImage(
                                        //     //     products[j].imageUrlFeatured,
                                        //     //   ),
                                        //     //   fit: BoxFit.fill,
                                        //     // ),
                                        //   ),
                                        // ),
                                        Positioned(
                                          right: 0,
                                          child: IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(
                                              (favoriteProd.any((prod) =>
                                                      prod.prodDocId ==
                                                          products[j]
                                                              .prodDocId &&
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
                                                      products[j].prodDocId &&
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

                                                //         return AuthScreenNew();
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

                                                //   return AuthScreenNew();
                                                // }

                                                _manageFavorite(
                                                    products[j].prodDocId,
                                                    isFavorite,
                                                    userId);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      products[j].prodName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).disabledColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // Container(
                                  //   child: Row(
                                  //     children: [
                                  //       widget.inDisplayType == "Results"
                                  //           ? Flexible(
                                  //               child: Text(
                                  //                 products[j].prodName.length > 35
                                  //                     ? products[j]
                                  //                             .prodName
                                  //                             .substring(0, 35) +
                                  //                         '...'
                                  //                     : products[j].prodName,
                                  //                 style: TextStyle(
                                  //                     color: Theme.of(context)
                                  //                         .disabledColor,
                                  //                     fontSize: 15,
                                  //                     fontWeight:
                                  //                         FontWeight.bold),
                                  //               ),
                                  //             )
                                  //           : Flexible(
                                  //               child: Text(
                                  //                 products[j].prodName.length > 15
                                  //                     ? products[j]
                                  //                             .prodName
                                  //                             .substring(0, 15) +
                                  //                         '...'
                                  //                     : products[j].prodName,
                                  //                 style: const TextStyle(
                                  //                     color: bDisabledColor,
                                  //                     fontSize: 15,
                                  //                     fontWeight:
                                  //                         FontWeight.bold),
                                  //               ),
                                  //             ),
                                  //     ],
                                  //   ),
                                  // ),
                                  Container(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: RichText(
                                        text: TextSpan(
                                          text: products[j].currencySymbol,
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
                                              text: products[j].price,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: RichText(
                                              text: TextSpan(
                                                text: 'Distance : ',
                                                style: const TextStyle(
                                                  color: bDisabledColor,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: products[j].distance,
                                                  ),
                                                  const TextSpan(
                                                    text: ' ',
                                                  ),
                                                  const TextSpan(
                                                    text: 'KM',
                                                  ),
                                                ],
                                              ),
                                            ),
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
                          crossAxisCount:
                              widget.inDisplayType == "Results" ? 1 : 2,
                          childAspectRatio: 4 / 4,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Center(
            child: const Text('Products not found! Please try again!'),
          );
  }
}
