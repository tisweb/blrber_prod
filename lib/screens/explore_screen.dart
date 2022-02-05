//Imports for pubspec Packages
import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:blrber/helpers/ad_helper.dart';
import 'package:blrber/screens/gmap_screen.dart';
import 'package:blrber/screens/user_shop_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag/flag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as p;
// import 'package:google_ml_vision/google_ml_vision.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:darq/darq.dart';
import 'package:country_picker/country_picker.dart';

// Imports for Services
import '../services/foundation.dart';

// Imports for Models
import '../constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/user_detail.dart';

// Imports for maps/location
import '../provider/get_current_location.dart';

// Imports for Widgets
import '../widgets/display_product_grid.dart';

// Imports for Screens
import '../screens/product_detail_screen.dart';
import '../screens/search_results.dart';

// Imports for Services
import '../services/connectivity.dart';
import '../services/load_mlmodel.dart';

class ExploreScreen extends StatefulWidget {
  static const routeName = '/explore-screen';

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class ImageLabelInfo {
  String imageLabel;
  double confidence;

  ImageLabelInfo({
    this.imageLabel,
    this.confidence,
  });
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _displayType = "Category";
  List _output;
  String imageLabel = "";
  bool status = false;
  bool _isInitialState = true;
  String _getCurrentLocation = "";
  String _currencyName = "";
  String _currencySymbol = "";

  String _countryCode = "";
  bool _dataLoaded = false;
  String _connectionStatus = 'process';

  File pickedImage;

  TabController _tabController;

  List<String> availableProdCC = [];
  List<Category> categoryList = [];
  List<Product> products = [];
  List<UserDetail> userDetails = [];

  GetCurrentLocation getCurrentLocation = GetCurrentLocation();

  @override
  void initState() {
    getCurrentLocation =
        Provider.of<GetCurrentLocation>(context, listen: false);
    _currencyName = getCurrentLocation.currencyCode;
    _currencySymbol = getCurrencySymbolByName(_currencyName);

    getCurrentLocation.getCurrentPosition().then((value) {
      if (value == 1) {
        _checkLocationPermission().then((value) {
          setState(() {});
        });
      } else {
        print('getcurrentlocation return - $value');
      }
    });

    LoadMlModel.loadModel();

    super.initState();
  }

  void _pickImage() async {
    try {
      final picker = ImagePicker();
      final imageFile = await picker.getImage(source: ImageSource.gallery);

      if (imageFile == null) {
        return null;
      }

      setState(() {
        pickedImage = File(imageFile.path);
      });

      if (pickedImage != null) {
        runModelOnImage(); // It is to run ml on tflite model
        // var prodName = await findLabels(
        //     pickedImage); // It is to run ml on firebase ml vision

        // if (prodName != "") {
        //   Navigator.of(context)
        //       .pushNamed(SearchResults.routeName, arguments: prodName);
        // }
      }
    } on PlatformException catch (e) {
      print('Image picker PlatformException error - ${e.code}');
      if (e.code.trim() == "photo_access_denied") {
        showDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: Text('Camera Permission'),
            content: Text(
                'This app needs camera access to take / choose pictures for searching products by photo'),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text('Deny'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoDialogAction(
                child: Text('Settings'),
                onPressed: () => p.openAppSettings(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Image picker error - $e');
    }
  }

  runModelOnImage() async {
    var output = await Tflite.runModelOnImage(
      path: pickedImage.path,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 2,
      threshold: 0.8,
    );

    // setState(() {
    _output = output;

    if (output.length > 0) {
      imageLabel = _output[0]["label"];

      // var imageLabelOut =
      //     imageLabel.split(",")[0] + "-" + imageLabel.split(",")[1];

      var imageLabelOut = imageLabel.split(",")[1];

      if (imageLabelOut != "") {
        Navigator.of(context)
            .pushNamed(SearchResults.routeName, arguments: imageLabelOut);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product Not found'),
        ),
      );
    }
    // });
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

  // Future<String> findLabels(File _image) async {
  //   print("---------vijay1");
  //   final inputImage = InputImage.fromFile(_image);
  //   print("---------vijay2");
  //   List<ImageLabelInfo> _imageLabels = [];
  //   final imageLabeler = GoogleMlKit.vision
  //       .imageLabeler(ImageLabelerOptions(confidenceThreshold: 0.80));
  //   print("---------vijay3");

  //   final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
  //   print("---------vijay4");

  //   for (ImageLabel label in labels) {
  //     ImageLabelInfo _imageLabel = ImageLabelInfo();
  //     _imageLabel.imageLabel = label.label;
  //     print("_imageLabel.imageLabel - ${_imageLabel.imageLabel}");
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

  @override
  void didChangeDependencies() async {
    _initialGetInfo();

    super.didChangeDependencies();
  }

  void _initialGetInfo() {
    getCurrentLocation = Provider.of<GetCurrentLocation>(context);

    // if (getCurrentLocation.latitude != 0.0) {
    //   setState(() {
    //     _dataLoaded = true;
    //   });
    // }
    final categories = Provider.of<List<Category>>(context);
    products = Provider.of<List<Product>>(context);
    userDetails = Provider.of<List<UserDetail>>(context);

    _setBuyingCountryCode();
    if (products.length > 0) {
      _setProductCountryCode();
    }

    if (_countryCode.isEmpty) {
      _countryCode = getCurrentLocation.countryCode;
    }

    if (products.length > 0) {
      products = products
          .where((e) =>
              e.status == 'Verified' &&
              e.subscription != 'Unpaid' &&
              e.listingStatus == 'Available' &&
              e.countryCode == _countryCode)
          .toList();
    }

    categoryList = [];

    for (var i = 0; i < categories.length; i++) {
      var cnt = products
          .where((e) =>
              e.catName.trim().toLowerCase() ==
              categories[i].catName.trim().toLowerCase())
          .toList()
          .length;
      if (cnt > 0) {
        categoryList.add(categories[i]);
      }
    }

    if (categoryList.length > 0) {
      categoryList.sort((a, b) {
        var aSerialNum = a.serialNum;
        var bSerialNum = b.serialNum;
        return aSerialNum.compareTo(bSerialNum);
      });
    }

    if (getCurrentLocation.latitude != 0.0) {
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  Future<void> _updateBuyingCountry(String countryCode) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('userDetails')
        .doc(user.uid.trim())
        .update({
      'buyingCountryCode': countryCode,
    }).then((value) {
      print("User Updated with Selected Buying Country");
    }).catchError((error) =>
            print("Failed to update User\'s Buying Country: $error"));
  }

  void _setBuyingCountryCode() {
    final user = FirebaseAuth.instance.currentUser;
    _countryCode = "";
    if (user != null) {
      // final List<UserDetail> userDetails =
      //     Provider.of<List<UserDetail>>(context);
      if (userDetails != null) {
        if (userDetails.length > 0) {
          var userData = userDetails
              .where((e) => e.userDetailDocId.trim() == user.uid.trim())
              .toList();
          if (userData.length > 0) {
            if (userData[0].buyingCountryCode != null) {
              _countryCode = userData[0].buyingCountryCode;
            }
          }
        }
      }
    }
  }

  void _setProductCountryCode() {
    var distinctProductsCC = products.distinct((d) => d.countryCode).toList();

    availableProdCC = [];
    if (distinctProductsCC.length > 0) {
      for (var item in distinctProductsCC) {
        availableProdCC.add(item.countryCode);
      }
    }
  }

  Future<void> _checkConnectivity() async {
    var connectivityStatus = await ConnectivityCheck.connectivity();
    if (connectivityStatus == "WifiInternet" ||
        connectivityStatus == "MobileInternet") {
      setState(() {
        _connectionStatus = 'success';
      });
    } else {
      setState(() {
        _connectionStatus = 'fail';
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    var status = await p.Permission.location.status;
    if (!status.isGranted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text('Location Permission'),
          content: Text('This app needs Location access'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('Deny'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
            CupertinoDialogAction(
              child: Text('Settings'),
              onPressed: () {
                p.openAppSettings();
                setState(() {});
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialState) {
      _isInitialState = false;
      print("connectivity check");
      _checkConnectivity();
      // _checkLocationPermission().then((value) {
      //   setState(() {});
      // });
    }

    final _appBarRow = Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.only(right: 10),
            child: IconButton(
              iconSize: 28,
              padding: EdgeInsets.all(0),
              onPressed: () async {
                var status = await p.Permission.mediaLibrary.status;
                print("photo status main - $status");

                if (status.isGranted) {
                  _pickImage();
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => CupertinoAlertDialog(
                      title: Text('Camera Permission'),
                      content: Text(
                          'This app needs camera access to take / choose pictures for searching products by photo'),
                      actions: <Widget>[
                        CupertinoDialogAction(
                          child: Text('Deny'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        CupertinoDialogAction(
                          child: Text('Settings'),
                          onPressed: () => p.openAppSettings(),
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.camera_alt_outlined,
                color: bDisabledColor,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 15,
          child: Container(
            height: (MediaQuery.of(context).size.height) / 21,
            decoration: BoxDecoration(
                color: bScaffoldBackgroundColor,
                borderRadius: BorderRadius.all(
                  Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 2.0,
                  ),
                ]),
            child: Container(
              child: TextButton.icon(
                label: Container(
                  child: Text(
                    "Search Product / Category ",
                    style: TextStyle(color: bDisabledColor),
                  ),
                ),
                // alignment: Alignment.centerLeft,
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: ItemsSearch(
                        products: products,
                        currencySymbol: _currencySymbol,
                        userDetails: userDetails,
                        getCurrentLocation: getCurrentLocation),
                  );
                },
                icon: Icon(
                  Icons.search,
                  color: bDisabledColor,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.only(left: 8),
            child: GestureDetector(
              child: Flag(
                _countryCode.isEmpty
                    ? getCurrentLocation.countryCode
                    : _countryCode,
                height: (MediaQuery.of(context).size.height) / 32,
                fit: BoxFit.fill,
              ),
              onTap: () {
                // Following block of code is used to find products from other country.
                // This block of code is commented because now plan to market the app in thier own contry.

                // final user = FirebaseAuth.instance.currentUser;
                // if (user == null) {
                //   // print("Please login to change Buying country!");

                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(
                //       content: Text('Please login to change Buying country!'),
                //     ),
                //   );
                // } else {
                //   showCountryPicker(
                //     countryFilter: availableProdCC,
                //     context: context,
                //     showPhoneCode: false,
                //     onSelect: (Country country) {
                //       setState(() {
                //         _updateBuyingCountry(country.countryCode);
                //       });
                //     },
                //     countryListTheme: CountryListThemeData(
                //       borderRadius: BorderRadius.only(
                //         topLeft: Radius.circular(40.0),
                //         topRight: Radius.circular(40.0),
                //       ),
                //       inputDecoration: InputDecoration(
                //         labelText: 'Search',
                //         hintText: 'Start typing to search',
                //         prefixIcon: const Icon(Icons.search),
                //         border: OutlineInputBorder(
                //           borderSide: BorderSide(
                //             color: const Color(0xFF8C98A8).withOpacity(0.2),
                //           ),
                //         ),
                //       ),
                //     ),
                //   );
                // }
              },
            ),
          ),
        ),
      ],
    );

    final _pageBody = SafeArea(
      child: _dataLoaded && _connectionStatus == 'success'
          ? Column(
              children: [
                Expanded(
                  flex: 10,
                  child: TabBarView(
                    controller: _tabController,
                    children:
                        List<Widget>.generate(categoryList.length, (index) {
                      return getCurrentLocation.addressLocation != ''
                          ? Column(
                              children: [
                                Expanded(
                                  flex: 9,
                                  child: Container(
                                    child: DisplayProductGrid(
                                      inCatName: categoryList[index].catName,
                                      inProdCondition: "",
                                      inDisplayType: _displayType,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                children: [
                                  const Text("Something went wrong!"),
                                  TextButton(
                                      onPressed: () {
                                        setState(() {});
                                      },
                                      child: const Text('Refresh'))
                                ],
                              ),
                            );
                    }),
                  ),
                ),
              ],
            )
          : _connectionStatus == 'fail'
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 50,
                      color: bPrimaryColor,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text("No Internet Connection!!"),
                  ],
                ))
              : Center(
                  child:
                      // CupertinoActivityIndicator(),
                      CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).scaffoldBackgroundColor),
                    backgroundColor: bPrimaryColor,
                  ),
                ),
    );
    final _appBar = AppBar(
      backgroundColor: bBackgroundColor,
      elevation: 0.0,
      iconTheme: IconThemeData(color: bDisabledColor),
      title: Container(
        // height: 60,
        padding: const EdgeInsets.only(top: 30, bottom: 20),
        margin: EdgeInsets.only(bottom: 10),
        child: _appBarRow,
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: List<Widget>.generate(categoryList.length, (index) {
          return Tab(
            child: Text(
              categoryList[index].catName,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width / 25,
              ),
            ),
            // text: categoryList[index].catName,
            // icon: Icon(
            //   IconData(categoryList[index].iconValue,
            //       fontFamily: 'IconFont', fontPackage: 'line_awesome_icons'),
            // ),
          );
        }),
        isScrollable: true,
        indicatorColor: bPrimaryColor,
        labelColor: bPrimaryColor,
        unselectedLabelColor: bDisabledColor,
      ),
    );

    return DefaultTabController(
      length: categoryList.length,
      child: Scaffold(
        appBar: _appBar,
        body: _pageBody,
        // body: UpgradeAlert(
        //     // onIgnore: () {
        //     //   print("ignore");
        //     //   return true;
        //     // },
        //     // onUpdate: () {
        //     //   print("update");
        //     //   return true;
        //     // },
        //     // debugDisplayOnce: true,
        //     dialogStyle: isIos
        //         ? UpgradeDialogStyle.cupertino
        //         : UpgradeDialogStyle.material,
        //     child: _pageBody),
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
  List<UserDetail> userDetails = [];
  String currencySymbol;
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();

  ItemsSearch(
      {this.products,
      this.currencySymbol,
      this.userDetails,
      this.getCurrentLocation});

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
      query != ""
          ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                query = "";
              },
            )
          : IconButton(
              icon: Icon(Icons.mic),
              onPressed: () async {
                var status = await p.Permission.microphone.status;
                print("microphone status search - $status");

                if (status.isGranted) {
                  _initSpeech();

                  _showListenDialog(context);
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => CupertinoAlertDialog(
                      title: Text('Microphone Permission'),
                      content: Text('This app needs Microphone access'),
                      actions: <Widget>[
                        CupertinoDialogAction(
                          child: Text('Deny'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        CupertinoDialogAction(
                          child: Text('Settings'),
                          onPressed: () => p.openAppSettings(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
      IconButton(
        icon: Icon(Icons.camera_alt_outlined),
        onPressed: () async {
          var prodNameS;
          var status = await p.Permission.photos.status;
          print("photos status search - $status");

          prodNameS = await _pickImageS();

          if (prodNameS == '1') {
            showDialog(
                context: context,
                builder: (BuildContext context) => CupertinoAlertDialog(
                      title: Text('Camera Permission'),
                      content: Text(
                          'This app needs camera access to take / choose pictures'),
                      actions: <Widget>[
                        CupertinoDialogAction(
                          child: Text('Deny'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        CupertinoDialogAction(
                          child: Text('Settings'),
                          onPressed: () => p.openAppSettings(),
                        ),
                      ],
                    ));
          }
          // var prodNameS = await _pickImageS();
          if (prodNameS != "Not Found" &&
              prodNameS != "" &&
              prodNameS != null) {
            query = prodNameS;
            Navigator.of(context)
                .pushNamed(SearchResults.routeName, arguments: query);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Product Not found'),
              ),
            );
          }
        },
      ),
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
            //     ||
            // (p.userDetailDocId.trim()).contains(getUserNameByQuery(query)))
            .toList();

    final userList = query.isEmpty
        ? []
        : userDetails
            .where((u) =>
                (u.companyName.toLowerCase().trim())
                    .contains(query.toLowerCase().trim()) ||
                (u.displayName.toLowerCase().trim())
                    .contains(query.toLowerCase().trim()))
            .toList();

    print("query 1 - ${query}");
    return myList.isEmpty && userList.isEmpty
        ? Container(
            padding: EdgeInsets.only(top: 10, left: 10),
            child: Text('Search Items...'))
        : Column(
            children: [
              userList.length > 0
                  ? Container(
                      height: 150,
                      child: Column(
                        children: [
                          Container(
                            height: 30,
                            color: bScaffoldBackgroundColor,
                            padding: EdgeInsets.only(left: 8),
                            child: Align(
                              child: Text("Vendor"),
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          Container(
                            height: 120,
                            color: bBackgroundColor,
                            child: ListView.builder(
                              // shrinkWrap: true,
                              // itemExtent: 200,
                              scrollDirection: Axis.horizontal,
                              itemCount: userList.length,
                              itemBuilder: (context, index) {
                                final UserDetail listItem = userList[index];
                                // selectedItem = myList[0].prodName;

                                double distanceD = Geolocator.distanceBetween(
                                        getCurrentLocation.latitude,
                                        getCurrentLocation.longitude,
                                        listItem.latitude,
                                        listItem.longitude) /
                                    1000.round();

                                String distanceS;
                                if (distanceD != null) {
                                  distanceS = distanceD.round().toString();
                                } else {
                                  distanceS = distanceD.toString();
                                }

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) {
                                            return UserShopScreen(
                                                userDocId:
                                                    listItem.userDetailDocId);
                                          },
                                          fullscreenDialog: true),
                                    );
                                  },
                                  child: Container(
                                    //This color property is to make the container fully occupide to make GestureDetector works on the whole container
                                    color: bBackgroundColor,
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        listItem.userImageUrl != null &&
                                                listItem.userImageUrl != ""
                                            ? Container(
                                                height: 60,
                                                width: 60,
                                                child: CachedNetworkImage(
                                                  fit: BoxFit.cover,
                                                  imageUrl:
                                                      listItem.userImageUrl,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    height: 0,
                                                    width: 0,
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(Icons.error),
                                                ),
                                              )
                                            : Container(
                                                height: 60,
                                                width: 60,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      bScaffoldBackgroundColor,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                listItem.userType !=
                                                        "Private Seller"
                                                    ? listItem.companyName
                                                    : listItem.displayName,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            Text(listItem.userType),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: RichText(
                                                text: TextSpan(
                                                  text: 'Distance : ',
                                                  style: const TextStyle(
                                                    color: bDisabledColor,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: distanceS,
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
                                            Row(
                                              children: [
                                                RichText(
                                                  text: const WidgetSpan(
                                                    child: const Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 22,
                                                    ),
                                                    alignment:
                                                        PlaceholderAlignment
                                                            .middle,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  child: Text(
                                                    listItem.addressLocation,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color: bBlueColor),
                                                  ),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (_) {
                                                            return GMapScreen(
                                                              lat: listItem
                                                                  .latitude,
                                                              long: listItem
                                                                  .longitude,
                                                              addressLocation:
                                                                  listItem
                                                                      .addressLocation,
                                                            );
                                                          },
                                                          fullscreenDialog:
                                                              true),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Row(
                                    //   crossAxisAlignment:
                                    //       CrossAxisAlignment.start,
                                    //   children: [
                                    //     Align(
                                    //       child: Text(listItem.companyName),
                                    //       alignment: Alignment.centerLeft,
                                    //     ),
                                    //     SizedBox(
                                    //       width: 10,
                                    //     )
                                    //   ],
                                    // ),
                                  ),
                                );
                                // ListTile(
                                //   title: Column(
                                //     children: [
                                //       Row(
                                //         children: [
                                //           TextButton(
                                //             onPressed: () {
                                //               Navigator.push(
                                //                 context,
                                //                 MaterialPageRoute(
                                //                     builder: (_) {
                                //                       return UserShopScreen(
                                //                           userDocId:
                                //                               listItem.userDetailDocId);
                                //                     },
                                //                     fullscreenDialog: true),
                                //               );
                                //             },
                                //             child: Text(
                                //               getUserName(listItem.userDetailDocId),
                                //             ),
                                //           ),
                                //         ],
                                //       ),
                                //     ],
                                //   ),
                                //   onTap: () {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //           builder: (_) {
                                //             return UserShopScreen(
                                //                 userDocId: listItem.userDetailDocId);
                                //           },
                                //           fullscreenDialog: true),
                                //     );
                                //   },
                                // );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
              Divider(),
              myList.length > 0
                  ? Expanded(
                      child: Container(
                        color: bBackgroundColor,
                        child: Column(
                          children: [
                            Container(
                              height: 30,
                              color: bScaffoldBackgroundColor,
                              padding: EdgeInsets.only(left: 8),
                              child: Align(
                                child: Text("Products"),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: myList.length,
                                itemBuilder: (context, index) {
                                  final Product listItem = myList[index];
                                  selectedItem = myList[0].prodName;

                                  return ListTile(
                                    title: Column(
                                      children: [
                                        Row(
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
                                              child: RichText(
                                                text: TextSpan(
                                                  text: listItem.catName,
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: ' ',
                                                    ),
                                                    const TextSpan(
                                                      text: 'Category',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) {
                                                      return UserShopScreen(
                                                          userDocId: listItem
                                                              .userDetailDocId);
                                                    },
                                                    fullscreenDialog: true),
                                              );
                                            },
                                            child: RichText(
                                              text: TextSpan(
                                                text: getUserName(
                                                    listItem.userDetailDocId),
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: ' ',
                                                  ),
                                                  const TextSpan(
                                                    text: 'Vendor',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    onTap: () {
                                      selectedItem = listItem.prodName;

                                      showResults(context);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(),
            ],
          );
    // Divider(),
    // if (myList.length > 0)
    //   ListView.builder(
    //     shrinkWrap: true,
    //     itemCount: myList.length,
    //     itemBuilder: (context, index) {
    //       final Product listItem = myList[index];
    //       selectedItem = myList[0].prodName;

    //       return ListTile(
    //         title: Column(
    //           children: [
    //             Row(
    //               children: [
    //                 Text(listItem.prodName),
    //                 SizedBox(
    //                   width: 20,
    //                 ),
    //                 TextButton(
    //                   onPressed: () {
    //                     selectedItem = listItem.catName;
    //                     showResults(context);
    //                   },
    //                   child: Text(listItem.catName),
    //                 ),
    //               ],
    //             ),
    //             Align(
    //               alignment: Alignment.centerLeft,
    //               child: TextButton(
    //                 onPressed: () {
    //                   Navigator.push(
    //                     context,
    //                     MaterialPageRoute(
    //                         builder: (_) {
    //                           return UserShopScreen(
    //                               userDocId:
    //                                   listItem.userDetailDocId);
    //                         },
    //                         fullscreenDialog: true),
    //                   );
    //                 },
    //                 child: Text(
    //                   getUserName(listItem.userDetailDocId),
    //                 ),
    //               ),
    //             )
    //           ],
    //         ),
    //         onTap: () {
    //           selectedItem = listItem.prodName;

    //           showResults(context);
    //         },
    //       );
    //     },
    //   ),
  }

  String getUserName(userId) {
    var userData = userDetails
        .where((e) => e.userDetailDocId.trim() == userId.trim())
        .toList();

    return userData.length > 0
        ? userData[0].companyName != null
            ? userData[0].companyName
            : userData[0].displayName
        : "";
  }

  String getUserNameByQuery(userName) {
    var userData = userDetails
        .where((e) =>
            e.displayName
                .toLowerCase()
                .trim()
                .contains(query.toLowerCase().trim()) ||
            e.companyName
                .toLowerCase()
                .trim()
                .contains(query.toLowerCase().trim()))
        .toList();

    return userData.length > 0 ? userData[0].userDetailDocId : "";
  }
}
