//Imports for pubspec Packages
import 'dart:io';

import 'package:blrber/models/subscriptionPlan.dart';
import 'package:blrber/models/user_detail.dart';
import 'package:blrber/screens/edit_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:search_map_place/search_map_place.dart' as smp;
import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:tflite/tflite.dart';

//Imports for Constants
import '../constants.dart';

//Imports for Services
import '../services/foundation.dart';

//Imports for Models
import '../models/category.dart';
import '../models/product.dart';

//Imports for Providers
import '../provider/get_current_location.dart';
import '../provider/motor_form_sqldb_provider.dart';
import '../provider/prod_images_sqldb_provider.dart';

//Imports for Screen
import '../screens/post_added_result_screen.dart';

//Imports for services
import '../services/api_keys.dart';

//Imports for Widgets
import '../widgets/search_place_auto_complete_widget_custom.dart';
import '../widgets/vinc.dart';

class PostInputForm extends StatefulWidget {
  // final String editPost;
  final String prodId;
  PostInputForm({
    // this.editPost,
    this.prodId,
  });
  @override
  _PostInputFormState createState() => _PostInputFormState();
}

class _PostInputFormState extends State<PostInputForm>
    with SingleTickerProviderStateMixin {
  List<GlobalKey<FormState>> formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  int _currentStep = 0;
  File pickedImage;
  String imageLabel = "";
  String imageType = "";
  bool _featuredImage = false;
  dynamic motorFormProvider;
  dynamic prodImageProvider;
  int _motorFormCount = 0;
  int _totalImageCount = 0;
  String _addressLocation = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _imageUrl = "";
  String _prodUpdated = '';
  bool _specialVehicle = false;
  bool _searchableValidateMM = true; // Make and Model
  bool _searchableValidate = true; // step 2
  var _userDetailDocId = '';
  var _prodDocId = '';
  var user;

  List<DropdownMenuItem<String>> _prodConditions,
      _deliveryInfo,
      _typeOfAd,
      _forSaleBy,
      _vehicleType,
      _subModel,
      _driveType,
      _bodyType,
      _transmission,
      _steeringLocation,
      _fuelType = [];
  List<DropdownMenuItem<String>> _catNames, _subCatTypes = [];
  List<DropdownMenuItem<String>> _makes = [];
  List<DropdownMenuItem<String>> _models = [];

  var _initialSelectedItem = 'Unspecified';
  var _initialValueDeliveryInfo = "Buyer's choice";
  var _initialValueTypeOfAd = "For Sale";
  var _initialValuePostedBy = "Private Seller";
  var _initialValueProductCond = "Used";
  var _initialValueTransmission = "Manual";
  var _initialValueFuelType = "Diesel";
  var _initialValueVehicleType = "Passenger Vehicle";
  var _initialValueDriveType = "RWD";
  var _initialValueBodyType = "SEDAN";
  var _initialValueSteeringLocation = "Unspecified";
  bool cTA1981 = true;
  bool _enableVinValButton = false;
  bool _vinValidateFlag = false;
  int _eImageCount = 0;
  int _iImageCount = 0;
  String _currencySymbol = "";
  String _currencyName = "";
  String _countryCode = "";
  int i = 0;
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();

  // MotorFormSqlDb motorFormSqlDb = MotorFormSqlDb();

  MotorFormSqlDb motorFormSqlDb = MotorFormSqlDb(
    id: '',
    catName: 'Unspecified',
    subCatType: 'Unspecified',
    prodName: '',
    prodDes: '',
    sellerNotes: '',
    prodCondition: 'Used',
    price: '',
    stockInHand: '1',
    imageUrlFeatured: '',
    deliveryInfo: 'Buyer\'s choice',
    typeOfAd: 'For Sale',
    year: '',
    make: 'Unspecified',
    model: 'Unspecified',
    vehicleType: 'Passenger Vehicle',
    mileage: '',
    vin: '',
    engine: '',
    fuelType: 'Diesel',
    options: '',
    subModel: '',
    numberOfCylinders: '',
    safetyFeatures: '',
    driveType: 'RWD',
    interiorColor: '',
    bodyType: 'SEDAN',
    exteriorColor: '',
    forSaleBy: 'Private Seller',
    warranty: '',
    trim: '',
    transmission: 'Manual',
    steeringLocation: 'Unspecified',
    vehicleTypeYear: 'CTA1981',
    editPost: '',
  );

  List<ProdImagesSqlDb> prodImagesSqlDb = [];
  List<ProdImagesSqlDb> prodImagesSqlDbE = [];
  List<ProdImagesSqlDb> prodImagesSqlDbI = [];
  List<ProdImagesSqlDb> listOfRemovedImg = [];
  List<SubscriptionPlan> subscriptionPlans = [];
  List<UserDetail> userDetails = [];

  List<Category> catNames = [];

  // create a controller for the TextField
  TextEditingController controllerEC = TextEditingController();
  TextEditingController controllerIC = TextEditingController();

  // FocusNode textFocusVin = FocusNode();
  FocusNode textFocusYear = FocusNode();
  FocusNode textFocusTitle = FocusNode();
  FocusNode textFocusMake = FocusNode();
  FocusNode textFocusModel = FocusNode();
  FocusNode textFocusPrice = FocusNode();
  FocusNode textFocusStock = FocusNode();
  FocusNode textFocusDes = FocusNode();
  FocusNode textFocusSell = FocusNode();
  FocusNode textFocusMileage = FocusNode();
  FocusNode textFocusEC = FocusNode();
  FocusNode textFocusEngine = FocusNode();
  FocusNode textFocusOptions = FocusNode();
  FocusNode textFocusSubModel = FocusNode();
  FocusNode textFocusNC = FocusNode();
  FocusNode textFocusSF = FocusNode();
  FocusNode textFocusTrim = FocusNode();
  FocusNode textFocusIC = FocusNode();
  FocusNode textFocusWarranty = FocusNode();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    motorFormProvider =
        Provider.of<MotorFormSqlDbProvider>(context, listen: false);
    prodImageProvider =
        Provider.of<ProdImagesSqlDbProvider>(context, listen: false);
    _initialLoadMotorForm();
  }

  @override
  void dispose() {
    controllerEC.dispose();
    controllerIC.dispose();
    // textFocusVin.dispose();
    textFocusYear.dispose();
    textFocusTitle.dispose();
    textFocusMake.dispose();
    textFocusModel.dispose();
    textFocusPrice.dispose();
    textFocusStock.dispose();
    textFocusDes.dispose();
    textFocusSell.dispose();
    textFocusMileage.dispose();
    textFocusEC.dispose();
    textFocusEngine.dispose();
    textFocusOptions.dispose();
    textFocusSubModel.dispose();
    textFocusNC.dispose();
    textFocusSF.dispose();
    textFocusTrim.dispose();
    textFocusIC.dispose();
    textFocusWarranty.dispose();

    super.dispose();
  }

  _unFocusAll() {
    // textFocusVin.unfocus();
    textFocusYear.unfocus();
    textFocusTitle.unfocus();
    textFocusMake.unfocus();
    textFocusModel.unfocus();
    textFocusPrice.unfocus();
    textFocusStock.unfocus();
    textFocusDes.unfocus();
    textFocusSell.unfocus();
    textFocusMileage.unfocus();
    textFocusEC.unfocus();
    textFocusEngine.unfocus();
    textFocusOptions.unfocus();
    textFocusSubModel.unfocus();
    textFocusNC.unfocus();
    textFocusSF.unfocus();
    textFocusTrim.unfocus();
    textFocusIC.unfocus();
    textFocusWarranty.unfocus();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
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
                openAppSettings();
                setState(() {});
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showAddUpdatePostDialog(String editPost) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(editPost == "true" ? "Update Post" : "Add Post"),
              content: Container(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _prodUpdated == ""
                          ? Text(
                              editPost == "true"
                                  ? 'Do you want to Update Post?'
                                  : 'Do you want to Add Post?',
                              style: TextStyle(color: Colors.blue),
                            )
                          : CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).scaffoldBackgroundColor),
                              backgroundColor: bPrimaryColor,
                            ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                if (_prodUpdated == "")
                  TextButton(
                    child: Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                if (_prodUpdated == "")
                  TextButton(
                    child: Text('Yes'),
                    onPressed: () async {
                      setState(() {
                        _prodUpdated = 'Start';
                      });

                      if (editPost == "true") {
                        await _updateAds(widget.prodId, motorFormSqlDb.catName,
                                motorFormSqlDb.subCatType)
                            .then((value) async {
                          if (value == 'Success') {
                            await _deleteRemovedImgInStorage();
                            await _deleteAndProcess().then((value) {
                              _prodUpdated = "";
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) {
                                      return PostAddedResultScreen(
                                          editPost: motorFormSqlDb.editPost,
                                          displayType: "P");
                                    },
                                    fullscreenDialog: true),
                              );
                            });
                          } else {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Something went wrong! Please check!'),
                              ),
                            );
                          }
                        });
                      } else {
                        await _postAds().then((value) async {
                          if (value == 'Success') {
                            await _addUserSubDetails(
                                _userDetailDocId, userDetails[0].countryCode);
                            await _deleteAndProcess().then((value) {
                              _prodUpdated = "";
                              Navigator.of(context).pop();

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) {
                                      return PostAddedResultScreen(
                                        displayType: "P",
                                      );
                                    },
                                    fullscreenDialog: true),
                              );
                            });
                          } else {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Something went wrong! Please check!'),
                              ),
                            );
                          }
                        });
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // FocusScopeNode focusNode;

  @override
  void didChangeDependencies() async {
    await _checkLocationPermission();
    getCurrentLocation =
        Provider.of<GetCurrentLocation>(context, listen: false);
    _currencyName = getCurrentLocation.currencyCode;

    _currencySymbol = getCurrencySymbolByName(_currencyName);

    _countryCode = getCurrentLocation.countryCode;

    subscriptionPlans =
        Provider.of<List<SubscriptionPlan>>(context, listen: false);

    userDetails = Provider.of<List<UserDetail>>(context, listen: false);

    if (userDetails.length > 0 && user != null) {
      userDetails = userDetails
          .where((e) => e.userDetailDocId.trim() == user.uid.trim())
          .toList();
    }

    // focusNode = FocusScope.of(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // final focusNode = FocusScope.of(context);

    _userDetailDocId = user.uid;

    // Menu Items for Product Conditions

    List<ProductCondition> productConditions =
        Provider.of<List<ProductCondition>>(context);
    _prodConditions = [];

    if (productConditions != null) {
      for (ProductCondition productCondition in productConditions) {
        _prodConditions.add(
          DropdownMenuItem(
            value: productCondition.prodCondition,
            child: Text(productCondition.prodCondition),
          ),
        );
      }
    }

    // Menu Items for Steering Location

    _steeringLocation = [];

    _steeringLocation.add(
      DropdownMenuItem(
        value: "Left Side",
        child: Text("Left Side"),
      ),
    );

    _steeringLocation.add(
      DropdownMenuItem(
        value: "Right Side",
        child: Text("Right Side"),
      ),
    );

    _steeringLocation.add(
      DropdownMenuItem(
        value: "Unspecified",
        child: Text("Unspecified"),
      ),
    );

    // Menu Items for Delivery Info

    List<DeliveryInfo> deliveryInfos = Provider.of<List<DeliveryInfo>>(context);
    _deliveryInfo = [];

    if (deliveryInfos != null) {
      for (DeliveryInfo deliveryInfo in deliveryInfos) {
        _deliveryInfo.add(
          DropdownMenuItem(
            value: deliveryInfo.deliveryInfo,
            child: Text(deliveryInfo.deliveryInfo),
          ),
        );
      }
    }

    //

    // Menu Items for Type of ad

    List<TypeOfAd> typeOfAds = Provider.of<List<TypeOfAd>>(context);
    _typeOfAd = [];

    if (typeOfAds != null) {
      for (TypeOfAd typeOfAd in typeOfAds) {
        _typeOfAd.add(
          DropdownMenuItem(
            value: typeOfAd.typeOfAd,
            child: Text(typeOfAd.typeOfAd),
          ),
        );
      }
    }

    //

    // Menu Items for  _forSaleBy

    List<ForSaleBy> forSaleBys = Provider.of<List<ForSaleBy>>(context);
    _forSaleBy = [];

    if (forSaleBys != null) {
      for (ForSaleBy forSaleBy in forSaleBys) {
        _forSaleBy.add(
          DropdownMenuItem(
            value: forSaleBy.forSaleBy,
            child: Text(forSaleBy.forSaleBy),
          ),
        );
      }
    }

    // Menu Items for  _fuelType

    List<FuelType> fuelTypes = Provider.of<List<FuelType>>(context);
    _fuelType = [];

    if (fuelTypes != null) {
      for (FuelType fuelType in fuelTypes) {
        _fuelType.add(
          DropdownMenuItem(
            value: fuelType.fuelType,
            child: Text(fuelType.fuelType),
          ),
        );
      }
    }

    //

    // Menu Items for  _vehicleType

    List<VehicleType> vehicleTypes = Provider.of<List<VehicleType>>(context);
    _vehicleType = [];

    if (vehicleTypes != null) {
      for (VehicleType vehicleType in vehicleTypes) {
        _vehicleType.add(
          DropdownMenuItem(
            value: vehicleType.vehicleType,
            child: Text(vehicleType.vehicleType),
          ),
        );
      }
    }

    //

    // Menu Items for  _subModel

    List<SubModel> subModels = Provider.of<List<SubModel>>(context);
    _subModel = [];

    if (subModels != null) {
      for (SubModel subModel in subModels) {
        _subModel.add(
          DropdownMenuItem(
            value: subModel.subModel,
            child: Text(subModel.subModel),
          ),
        );
      }
    }

    //

    // Menu Items for  _driveType

    List<DriveType> driveTypes = Provider.of<List<DriveType>>(context);
    _driveType = [];

    if (driveTypes != null) {
      for (DriveType driveType in driveTypes) {
        _driveType.add(
          DropdownMenuItem(
            value: driveType.driveType,
            child: Text(driveType.driveType),
          ),
        );
      }
    }

    //

    // Menu Items for  _bodyType

    List<BodyType> bodyTypes = Provider.of<List<BodyType>>(context);
    _bodyType = [];

    if (bodyTypes != null) {
      for (BodyType bodyType in bodyTypes) {
        _bodyType.add(
          DropdownMenuItem(
            value: bodyType.bodyType,
            child: Text(bodyType.bodyType),
          ),
        );
      }
    }

    //

    // Menu Items for  _transmission

    List<Transmission> transmissions = Provider.of<List<Transmission>>(context);
    _transmission = [];

    if (transmissions != null) {
      for (Transmission transmission in transmissions) {
        _transmission.add(
          DropdownMenuItem(
            value: transmission.transmission,
            child: Text(transmission.transmission),
          ),
        );
      }
    }

    //

    catNames = Provider.of<List<Category>>(context);
    _catNames = [];
    _catNames.add(
      DropdownMenuItem(
        value: _initialSelectedItem,
        child: Text(_initialSelectedItem),
      ),
    );
    if (catNames != null) {
      for (Category catName in catNames) {
        _catNames.add(
          DropdownMenuItem(
            value: catName.catName,
            child: Text(catName.catName),
          ),
        );
      }
    }

// Sub cat type
    if (motorFormSqlDb.catName != null && motorFormSqlDb.catName != '') {
      print("motorFormSqlDb.catName - ${motorFormSqlDb.catName}");
      var subCatTypes = Provider.of<List<SubCategory>>(context);
      if (subCatTypes.length > 0) {
        subCatTypes = subCatTypes
            .where((e) =>
                e.catName.toLowerCase().trim() ==
                motorFormSqlDb.catName.toLowerCase().trim())
            .toList();
        print("subCatTypes length - ${subCatTypes.length}");
        _subCatTypes = [];
        _subCatTypes.add(
          DropdownMenuItem(
            value: _initialSelectedItem,
            child: Text(_initialSelectedItem),
          ),
        );
        print("subCatTypes length 11 - ${subCatTypes.length}");
        // _subCatTypes.add(
        //   DropdownMenuItem(
        //     value: "Others",
        //     child: Text("Others"),
        //   ),
        // );

        if (subCatTypes.length > 0) {
          for (SubCategory subCatType in subCatTypes) {
            _subCatTypes.add(
              DropdownMenuItem(
                value: subCatType.subCatType,
                child: Text(subCatType.subCatType),
              ),
            );
          }
        }
      }
    }

    if (motorFormSqlDb.subCatType != null && motorFormSqlDb.subCatType != '') {
      List<Make> makes = Provider.of<List<Make>>(context);

      makes = makes
          .where((e) => e.subCatType == motorFormSqlDb.subCatType)
          .toList();

      _makes = [];
      _makes.add(
        DropdownMenuItem(
          value: _initialSelectedItem,
          child: Text(_initialSelectedItem),
        ),
      );
      _makes.add(
        DropdownMenuItem(
          value: "Others",
          child: Text("Enter New Make..."),
        ),
      );
      if (makes != null) {
        for (Make make in makes) {
          _makes.add(
            DropdownMenuItem(
              value: make.make,
              child: Text(make.make),
            ),
          );
        }
      }

      List<Model> models = Provider.of<List<Model>>(context);

      models = models
          .where((e) =>
              e.subCatType == motorFormSqlDb.subCatType &&
              e.make == motorFormSqlDb.make)
          .toList();

      _models = [];

      _models.add(
        DropdownMenuItem(
          value: _initialSelectedItem,
          child: Text(_initialSelectedItem),
        ),
      );
      _models.add(
        DropdownMenuItem(
          value: "Others",
          child: Text("Enter New Model..."),
        ),
      );

      if (models != null) {
        for (Model model in models) {
          _models.add(
            DropdownMenuItem(
              value: model.model,
              child: Text(model.model),
            ),
          );
        }
      }
    }

    List<Step> steps = [
      Step(
        title: const Text('Photo'),
        isActive: _currentStep >= 0,
        state: _currentStep >= 0 ? StepState.complete : StepState.disabled,
        content: Form(
          key: formKeys[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Add upto 20 photos'),
              SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OutlineButton(
                    shape: StadiumBorder(),
                    textColor: Colors.blue,
                    child: Text('Take a photo'),
                    borderSide: BorderSide(
                        color: Colors.blue, style: BorderStyle.solid, width: 1),
                    onPressed: () async {
                      var status = await Permission.photos.status;

                      if (status.isGranted) {
                        await _pickImage('C');
                      } else {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                CupertinoAlertDialog(
                                  title: Text('Camera Permission'),
                                  content: Text(
                                      'This app needs camera access to take / choose pictures'),
                                  actions: <Widget>[
                                    CupertinoDialogAction(
                                      child: Text('Deny'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    CupertinoDialogAction(
                                      child: Text('Settings'),
                                      onPressed: () => openAppSettings(),
                                    ),
                                  ],
                                ));
                      }
                    },
                  ),
                  OutlineButton(
                    shape: StadiumBorder(),
                    textColor: Colors.blue,
                    child: Text('Select photos'),
                    borderSide: BorderSide(
                        color: Colors.blue, style: BorderStyle.solid, width: 1),
                    onPressed: () async {
                      var status = await Permission.photos.status;

                      print('status - $status');

                      if (status.isGranted) {
                        await _pickImage('G');
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              CupertinoAlertDialog(
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
                                onPressed: () => openAppSettings(),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Column(
                children: [
                  Column(
                    children: [
                      FutureBuilder(
                        future: Provider.of<ProdImagesSqlDbProvider>(context,
                                listen: false)
                            .fetchAndSetImages('E'),
                        builder: (ctx, snapshot) => snapshot.connectionState ==
                                ConnectionState.waiting
                            ? Container(
                                width: 0,
                                height: 0,
                              )
                            : Consumer<ProdImagesSqlDbProvider>(
                                child: const Center(
                                  child: Text(
                                      'Got no images yet, start adding some!'),
                                ),
                                builder: (ctx, imageData, ch) {
                                  _totalImageCount = imageData.itemsE.length;

                                  if (imageData.itemsE.length > 0) {
                                    prodImagesSqlDbE = imageData.itemsE;

                                    return Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              'Exterior (${prodImagesSqlDbE.length})'),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          height: 100,
                                          child: ListView.builder(
                                              itemCount:
                                                  prodImagesSqlDbE.length,
                                              scrollDirection: Axis.horizontal,
                                              itemBuilder: (context, index) {
                                                return Container(
                                                  margin:
                                                      EdgeInsets.only(right: 3),
                                                  child: Stack(children: [
                                                    Container(
                                                      width: 100,
                                                      height: 100,
                                                      child: prodImagesSqlDbE[
                                                                      index]
                                                                  .imageUrl
                                                                  .substring(
                                                                      0, 5) ==
                                                              'https'
                                                          ? Image.network(
                                                              prodImagesSqlDbE[
                                                                      index]
                                                                  .imageUrl,
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Image.file(
                                                              File(prodImagesSqlDbE[
                                                                      index]
                                                                  .imageUrl),
                                                              fit: BoxFit.cover,
                                                            ),
                                                    ),
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white60,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(50),
                                                          ),
                                                        ),
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            await _deleteImage(
                                                                prodImagesSqlDbE[
                                                                        index]
                                                                    .id,
                                                                prodImagesSqlDbE[
                                                                        index]
                                                                    .imageType);
                                                            _removeImage(
                                                                prodImagesSqlDbE,
                                                                index);
                                                          },
                                                          child: Icon(
                                                            Icons.close,
                                                            size: 20,
                                                            color: Colors
                                                                .grey[800],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ]),
                                                );
                                              }),
                                        ),
                                      ],
                                    );
                                  } else
                                    return Container();
                                }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      FutureBuilder(
                        future: Provider.of<ProdImagesSqlDbProvider>(context,
                                listen: false)
                            .fetchAndSetImages('I'),
                        builder: (ctx, snapshot) => snapshot.connectionState ==
                                ConnectionState.waiting
                            ? Container(
                                width: 0,
                                height: 0,
                              )
                            : Consumer<ProdImagesSqlDbProvider>(
                                child: const Center(
                                  child: const Text(
                                      'Got no images yet, start adding some!'),
                                ),
                                builder: (ctx, imageData, ch) {
                                  _totalImageCount = _totalImageCount +
                                      imageData.itemsI.length;
                                  if (imageData.itemsI.length > 0) {
                                    prodImagesSqlDbI = imageData.itemsI;
                                    return Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              'Interior (${prodImagesSqlDbI.length})'),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          height: 100,
                                          child: ListView.builder(
                                              itemCount:
                                                  prodImagesSqlDbI.length,
                                              scrollDirection: Axis.horizontal,
                                              itemBuilder: (context, index) {
                                                return Container(
                                                  margin:
                                                      EdgeInsets.only(right: 3),
                                                  child: Stack(
                                                    children: [
                                                      Container(
                                                        width: 100,
                                                        height: 100,
                                                        child: prodImagesSqlDbI[
                                                                        index]
                                                                    .imageUrl
                                                                    .substring(
                                                                        0, 5) ==
                                                                'https'
                                                            ? Image.network(
                                                                prodImagesSqlDbI[
                                                                        index]
                                                                    .imageUrl,
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                            : Image.file(
                                                                File(prodImagesSqlDbI[
                                                                        index]
                                                                    .imageUrl),
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                      ),
                                                      Positioned(
                                                        top: 0,
                                                        right: 0,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            await _deleteImage(
                                                                prodImagesSqlDbI[
                                                                        index]
                                                                    .id,
                                                                prodImagesSqlDbI[
                                                                        index]
                                                                    .imageType);
                                                            _removeImage(
                                                                prodImagesSqlDbI,
                                                                index);
                                                          },
                                                          child: const Icon(
                                                            Icons.close,
                                                            size: 20,
                                                            color:
                                                                bBackgroundColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                        ),
                                      ],
                                    );
                                  } else
                                    return Container();
                                }),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      Step(
        title: const Text('Details'),
        isActive: _currentStep >= 0,
        state: _currentStep >= 1 ? StepState.complete : StepState.disabled,
        content: Container(
          child: SingleChildScrollView(
            child: Form(
              key: formKeys[1],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Product Category',
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                        color: bScaffoldBackgroundColor,
                        child: DropdownButtonFormField<String>(
                          items: _catNames,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) async {
                            // setState(() {
                            motorFormSqlDb.catName = value;

                            // });

                            // motorFormSqlDb.subCatType = "Unspecified";
                            // await _updateMotorForm(motorFormSqlDb.id,
                            //     'subCatType', motorFormSqlDb.subCatType);

                            motorFormSqlDb.subCatType = "Unspecified";
                            await _updateMotorForm(motorFormSqlDb.id, 'catName',
                                motorFormSqlDb.catName);
                          },
                          onSaved: (value) {
                            motorFormSqlDb.catName = value;
                          },
                          onTap: () {
                            _unFocusAll();
                          },
                          validator: (value) {
                            if (value == 'Unspecified') {
                              return 'Please select prod category!';
                            }
                            return null;
                          },
                          value: _motorFormCount > 0
                              ? motorFormSqlDb.catName
                              : _initialSelectedItem,
                        ),
                      ),
                    ],
                  ),
                  if (motorFormSqlDb.catName != null)
                    Column(
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Sub Product Category',
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Container(
                          color: bScaffoldBackgroundColor,
                          child: DropdownButtonFormField<String>(
                            items: _subCatTypes,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) async {
                              setState(() {
                                motorFormSqlDb.subCatType = value;
                              });
                              if (motorFormSqlDb.subCatType == 'Cars' ||
                                  motorFormSqlDb.subCatType == 'Trucks' ||
                                  motorFormSqlDb.subCatType == 'Caravans') {
                                _specialVehicle = true;
                              } else {
                                _specialVehicle = false;
                              }
                              await _updateMotorForm(motorFormSqlDb.id,
                                  'subCatType', motorFormSqlDb.subCatType);
                            },
                            onSaved: (value) {
                              motorFormSqlDb.subCatType = value;
                            },
                            onTap: () {
                              _unFocusAll();
                            },
                            validator: (value) {
                              if (value == 'Unspecified' || value == null) {
                                return 'Please select type of the product!';
                              }
                              return null;
                            },
                            value: _motorFormCount > 0
                                ? motorFormSqlDb.subCatType
                                : _initialSelectedItem,
                          ),
                        ),
                      ],
                    ),
                  if (motorFormSqlDb.catName != null &&
                      motorFormSqlDb.subCatType != null)
                    (motorFormSqlDb.catName.trim() == 'Vehicle'.trim() &&
                            !motorFormSqlDb.subCatType
                                .contains('Accessories') &&
                            !motorFormSqlDb.subCatType.contains('Others'))
                        // ? motorDetailsUI(focusNode)
                        // : commonDetailsUI(focusNode),
                        ? motorDetailsUI()
                        : commonDetailsUI(),
                ],
              ),
            ),
          ),
        ),
      ),
      Step(
        title: const Text('Spec'),
        isActive: _currentStep >= 0,
        state: _currentStep >= 2 ? StepState.complete : StepState.disabled,
        content: Container(
          child: SingleChildScrollView(
            child: Form(
              key: formKeys[2],
              child: Column(
                children: <Widget>[
                  if (motorFormSqlDb.catName != null)
                    (motorFormSqlDb.catName.trim() == 'Vehicle'.trim() &&
                            !motorFormSqlDb.subCatType
                                .contains('Accessories') &&
                            !motorFormSqlDb.subCatType.contains('Others'))
                        ? Column(
                            children: [
                              Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Mileage',
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Container(
                                    color: bScaffoldBackgroundColor,
                                    height:
                                        MediaQuery.of(context).size.height / 15,
                                    child: TextFormField(
                                        key: ValueKey('mileage'),
                                        focusNode: textFocusMileage,
                                        // onEditingComplete: () =>
                                        //     focusNode.nextFocus(),
                                        initialValue: motorFormSqlDb.mileage,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) async {
                                          setState(() {
                                            motorFormSqlDb.mileage = value;
                                          });
                                          await _updateMotorForm(
                                              motorFormSqlDb.id,
                                              'mileage',
                                              motorFormSqlDb.mileage);
                                        },
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return 'Please enter mileage!';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          motorFormSqlDb.mileage = value;
                                        },
                                        onTap: () {
                                          textFocusEC.unfocus();
                                          textFocusEngine.unfocus();
                                          textFocusOptions.unfocus();
                                          textFocusSubModel.unfocus();
                                          textFocusNC.unfocus();
                                          textFocusSF.unfocus();
                                          textFocusTrim.unfocus();
                                          textFocusIC.unfocus();

                                          textFocusWarranty.unfocus();
                                        }),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Column(
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Fuel Type',
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Container(
                                    color: bScaffoldBackgroundColor,
                                    child: DropdownButtonFormField<String>(
                                      items: _fuelType,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) async {
                                        setState(() {
                                          motorFormSqlDb.fuelType = value;
                                        });
                                        await _updateMotorForm(
                                            motorFormSqlDb.id,
                                            'fuelType',
                                            motorFormSqlDb.fuelType);
                                      },
                                      onSaved: (value) {
                                        motorFormSqlDb.fuelType = value;
                                      },
                                      validator: (value) {
                                        if (value == 'Unspecified') {
                                          return 'Please select Fuel Type!';
                                        }
                                        return null;
                                      },
                                      onTap: () {
                                        _unFocusAll();
                                      },
                                      value: motorFormSqlDb.fuelType != null
                                          ? motorFormSqlDb.fuelType
                                          : _initialValueFuelType,
                                    ),
                                  ),

                                  // (motorFormSqlDb.fuelType != null)
                                  //     ? (_fuelType.any((e) =>
                                  //             e.value.trim().toLowerCase() ==
                                  //             motorFormSqlDb.fuelType
                                  //                 .trim()
                                  //                 .toLowerCase()))
                                  //         ? Container(
                                  //             color: bScaffoldBackgroundColor,
                                  //             child: SearchableDropdown.single(
                                  //               items: _fuelType,
                                  //               value: motorFormSqlDb
                                  //                           .fuelType !=
                                  //                       null
                                  //                   ? motorFormSqlDb.fuelType
                                  //                   : _initialValueFuelType,
                                  //               hint: "Select fuelType",
                                  //               searchHint: "Select fuelType",
                                  //               onChanged: (value) async {
                                  //                 setState(() {
                                  //                   motorFormSqlDb.fuelType =
                                  //                       value;
                                  //                 });
                                  //                 await _updateMotorForm(
                                  //                     motorFormSqlDb.id,
                                  //                     'fuelType',
                                  //                     motorFormSqlDb.fuelType);
                                  //               },
                                  //               validator: (value) {
                                  //                 if (value == 'Unspecified') {
                                  //                   print(
                                  //                       'Fuel Type Unspecified');
                                  //                   _searchableValidate = false;
                                  //                   return 'Please select fuelType! - $value';
                                  //                 }
                                  //                 _searchableValidate = true;
                                  //                 return null;
                                  //               },
                                  //               isExpanded: true,
                                  //             ),
                                  //           )
                                  //         : Container(
                                  //             color: bScaffoldBackgroundColor,
                                  //             height: MediaQuery.of(context)
                                  //                     .size
                                  //                     .height /
                                  //                 15,
                                  //             child: TextFormField(
                                  //               key: ValueKey('fuelType'),
                                  //               // onEditingComplete: () => focusNode.unfocus(),
                                  //               initialValue: motorFormSqlDb
                                  //                           .fuelType !=
                                  //                       null
                                  //                   ? motorFormSqlDb.fuelType
                                  //                   : _initialValueFuelType,
                                  //               decoration:
                                  //                   const InputDecoration(
                                  //                 border: OutlineInputBorder(),
                                  //               ),
                                  //               onChanged: (value) async {
                                  //                 setState(() {
                                  //                   motorFormSqlDb.fuelType =
                                  //                       value;
                                  //                 });
                                  //                 await _updateMotorForm(
                                  //                     motorFormSqlDb.id,
                                  //                     'fuelType',
                                  //                     motorFormSqlDb.fuelType);
                                  //               },
                                  //               validator: (value) {
                                  //                 if (value.isEmpty) {
                                  //                   return 'Please enter fuelType!';
                                  //                 }
                                  //                 return null;
                                  //               },
                                  //               onSaved: (value) {
                                  //                 motorFormSqlDb.fuelType =
                                  //                     value;
                                  //               },
                                  //             ),
                                  //           )
                                  //     : Container(
                                  //         color: bScaffoldBackgroundColor,
                                  //         child: SearchableDropdown.single(
                                  //           items: _fuelType,
                                  //           value:
                                  //               motorFormSqlDb.fuelType != null
                                  //                   ? motorFormSqlDb.fuelType
                                  //                   : _initialValueFuelType,
                                  //           hint: "Select fuelType",
                                  //           searchHint: "Select fuelType",
                                  //           onChanged: (value) async {
                                  //             setState(() {
                                  //               motorFormSqlDb.fuelType = value;
                                  //             });
                                  //             await _updateMotorForm(
                                  //                 motorFormSqlDb.id,
                                  //                 'fuelType',
                                  //                 motorFormSqlDb.fuelType);
                                  //           },
                                  //           validator: (value) {
                                  //             if (value == 'Unspecified') {
                                  //               print('Fuel Type1 Unspecified');
                                  //               _searchableValidate = false;
                                  //               return 'Please select fuelType! - $value';
                                  //             }
                                  //             _searchableValidate = true;
                                  //             return null;
                                  //           },
                                  //           isExpanded: true,
                                  //         ),
                                  //       ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),

                              //
                              Column(
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Exterior Color',
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Container(
                                    color: bScaffoldBackgroundColor,
                                    height:
                                        MediaQuery.of(context).size.height / 15,
                                    child: TextFormField(
                                      enabled: false,
                                      focusNode: textFocusEC,
                                      key: ValueKey('exteriorColor'),
                                      // onEditingComplete: () =>
                                      //     focusNode.nextFocus(),
                                      controller: controllerEC,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              //

                              GestureDetector(
                                onTap: () {
                                  _unFocusAll();
                                },
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _unFocusAll();
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              setState(() {
                                                motorFormSqlDb.exteriorColor =
                                                    "Red";
                                                controllerEC.text = "Red";
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'exteriorColor',
                                                  motorFormSqlDb.exteriorColor);

                                              _unFocusAll();
                                            },
                                            child: const Text(''),
                                            style: ElevatedButton.styleFrom(
                                              shape: CircleBorder(
                                                side: motorFormSqlDb
                                                            .exteriorColor ==
                                                        "Red"
                                                    ? BorderSide(
                                                        width: 2,
                                                        style:
                                                            BorderStyle.solid,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                              primary: Colors.red[700],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              setState(() {
                                                motorFormSqlDb.exteriorColor =
                                                    "Orange";
                                                controllerEC.text = "Orange";
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'exteriorColor',
                                                  motorFormSqlDb.exteriorColor);
                                              _unFocusAll();
                                            },
                                            child: const Text(''),
                                            style: ElevatedButton.styleFrom(
                                              shape: CircleBorder(
                                                side: motorFormSqlDb
                                                            .exteriorColor ==
                                                        "Orange"
                                                    ? const BorderSide(
                                                        width: 2,
                                                        style:
                                                            BorderStyle.solid,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                              primary: Colors.orange[700],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              setState(() {
                                                motorFormSqlDb.exteriorColor =
                                                    "Yellow";
                                                controllerEC.text = "Yellow";
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'exteriorColor',
                                                  motorFormSqlDb.exteriorColor);
                                              _unFocusAll();
                                            },
                                            child: const Text(''),
                                            style: ElevatedButton.styleFrom(
                                              shape: CircleBorder(
                                                side: motorFormSqlDb
                                                            .exteriorColor ==
                                                        "Yellow"
                                                    ? const BorderSide(
                                                        width: 2,
                                                        style:
                                                            BorderStyle.solid,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                              primary: Colors.yellow[700],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              setState(() {
                                                motorFormSqlDb.exteriorColor =
                                                    "Green";
                                                controllerEC.text = "Green";
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'exteriorColor',
                                                  motorFormSqlDb.exteriorColor);
                                              _unFocusAll();
                                            },
                                            child: const Text(''),
                                            style: ElevatedButton.styleFrom(
                                              shape: CircleBorder(
                                                side: motorFormSqlDb
                                                            .exteriorColor ==
                                                        "Green"
                                                    ? const BorderSide(
                                                        width: 2,
                                                        style:
                                                            BorderStyle.solid,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                              primary: Colors.green[700],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              setState(() {
                                                motorFormSqlDb.exteriorColor =
                                                    "Blue";
                                                controllerEC.text = "Blue";
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'exteriorColor',
                                                  motorFormSqlDb.exteriorColor);
                                              _unFocusAll();
                                            },
                                            child: const Text(''),
                                            style: ElevatedButton.styleFrom(
                                              shape: CircleBorder(
                                                side: motorFormSqlDb
                                                            .exteriorColor ==
                                                        "Blue"
                                                    ? const BorderSide(
                                                        width: 2,
                                                        style:
                                                            BorderStyle.solid,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                              primary: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              motorFormSqlDb.exteriorColor =
                                                  "Purple";
                                              controllerEC.text = "Purple";
                                            });
                                            await _updateMotorForm(
                                                motorFormSqlDb.id,
                                                'exteriorColor',
                                                motorFormSqlDb.exteriorColor);
                                            _unFocusAll();
                                          },
                                          child: const Text(''),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(
                                              side: motorFormSqlDb
                                                          .exteriorColor ==
                                                      "Purple"
                                                  ? const BorderSide(
                                                      width: 2,
                                                      style: BorderStyle.solid,
                                                    )
                                                  : BorderSide.none,
                                            ),
                                            primary: Colors.purple[700],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              motorFormSqlDb.exteriorColor =
                                                  "Black";
                                              controllerEC.text = "Black";
                                            });
                                            await _updateMotorForm(
                                                motorFormSqlDb.id,
                                                'exteriorColor',
                                                motorFormSqlDb.exteriorColor);
                                            _unFocusAll();
                                          },
                                          child: const Text(''),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(
                                              side: motorFormSqlDb
                                                          .exteriorColor ==
                                                      "Black"
                                                  ? BorderSide(
                                                      width: 2,
                                                      style: BorderStyle.solid,
                                                      color: Colors.grey[200],
                                                    )
                                                  : BorderSide.none,
                                            ),
                                            primary: Colors.black,
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              motorFormSqlDb.exteriorColor =
                                                  "Grey";
                                              controllerEC.text = "Grey";
                                            });
                                            await _updateMotorForm(
                                                motorFormSqlDb.id,
                                                'exteriorColor',
                                                motorFormSqlDb.exteriorColor);
                                            _unFocusAll();
                                          },
                                          child: const Text(''),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(
                                              side: motorFormSqlDb
                                                          .exteriorColor ==
                                                      "Grey"
                                                  ? const BorderSide(
                                                      width: 2,
                                                      style: BorderStyle.solid,
                                                    )
                                                  : BorderSide.none,
                                            ),
                                            primary: Colors.grey[300],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              motorFormSqlDb.exteriorColor =
                                                  "Brown";
                                              controllerEC.text = "Brown";
                                            });
                                            await _updateMotorForm(
                                                motorFormSqlDb.id,
                                                'exteriorColor',
                                                motorFormSqlDb.exteriorColor);
                                            _unFocusAll();
                                          },
                                          child: const Text(''),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(
                                              side: motorFormSqlDb
                                                          .exteriorColor ==
                                                      "Brown"
                                                  ? const BorderSide(
                                                      width: 2,
                                                      style: BorderStyle.solid,
                                                    )
                                                  : BorderSide.none,
                                            ),
                                            primary: Colors.brown[500],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              motorFormSqlDb.exteriorColor =
                                                  "White";
                                              controllerEC.text = "White";
                                            });
                                            await _updateMotorForm(
                                                motorFormSqlDb.id,
                                                'exteriorColor',
                                                motorFormSqlDb.exteriorColor);
                                            _unFocusAll();
                                          },
                                          child: const Text(''),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(
                                              side: motorFormSqlDb
                                                          .exteriorColor ==
                                                      "White"
                                                  ? const BorderSide(
                                                      width: 2,
                                                      style: BorderStyle.solid,
                                                    )
                                                  : BorderSide.none,
                                            ),
                                            primary: bBackgroundColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              if (_specialVehicle)
                                Column(
                                  children: [
                                    Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Vehicle Type',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          child:
                                              DropdownButtonFormField<String>(
                                            items: _vehicleType,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.vehicleType =
                                                    value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'vehicleType',
                                                  motorFormSqlDb.vehicleType);
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.vehicleType =
                                                  value;
                                            },
                                            validator: (value) {
                                              if (value == 'Unspecified') {
                                                return 'Please select Vehicle Type!';
                                              }
                                              return null;
                                            },
                                            onTap: () {
                                              _unFocusAll();
                                            },
                                            value: motorFormSqlDb.vehicleType !=
                                                    null
                                                ? motorFormSqlDb.vehicleType
                                                : _initialValueVehicleType,
                                          ),
                                        ),
                                        // (motorFormSqlDb.vehicleType != null)
                                        //     ? (_vehicleType.any((e) =>
                                        //             e.value
                                        //                 .trim()
                                        //                 .toLowerCase() ==
                                        //             motorFormSqlDb.vehicleType
                                        //                 .trim()
                                        //                 .toLowerCase()))
                                        //         ? Container(
                                        //             color:
                                        //                 bScaffoldBackgroundColor,
                                        //             child: SearchableDropdown
                                        //                 .single(
                                        //               items: _vehicleType,
                                        //               value: motorFormSqlDb
                                        //                           .vehicleType !=
                                        //                       null
                                        //                   ? motorFormSqlDb
                                        //                       .vehicleType
                                        //                   : _initialValueVehicleType,
                                        //               hint:
                                        //                   "Select vehicleType",
                                        //               searchHint:
                                        //                   "Select vehicleType",
                                        //               onChanged: (value) async {
                                        //                 setState(() {
                                        //                   motorFormSqlDb
                                        //                           .vehicleType =
                                        //                       value;
                                        //                 });
                                        //                 await _updateMotorForm(
                                        //                     motorFormSqlDb.id,
                                        //                     'vehicleType',
                                        //                     motorFormSqlDb
                                        //                         .vehicleType);
                                        //               },
                                        //               validator: (value) {
                                        //                 if (value ==
                                        //                     'Unspecified') {
                                        //                   print(
                                        //                       'vehicle type Unspecified');
                                        //                   _searchableValidate =
                                        //                       false;
                                        //                   return 'Please select vehicleType! - $value';
                                        //                 }
                                        //                 _searchableValidate =
                                        //                     true;
                                        //                 return null;
                                        //               },
                                        //               isExpanded: true,
                                        //             ),
                                        //           )
                                        //         : Container(
                                        //             color:
                                        //                 bScaffoldBackgroundColor,
                                        //             height:
                                        //                 MediaQuery.of(context)
                                        //                         .size
                                        //                         .height /
                                        //                     15,
                                        //             child: TextFormField(
                                        //               key: ValueKey(
                                        //                   'vehicleType'),
                                        //               // onEditingComplete: () => focusNode.unfocus(),
                                        //               initialValue: motorFormSqlDb
                                        //                           .vehicleType !=
                                        //                       null
                                        //                   ? motorFormSqlDb
                                        //                       .vehicleType
                                        //                   : _initialValueVehicleType,
                                        //               decoration:
                                        //                   const InputDecoration(
                                        //                 border:
                                        //                     OutlineInputBorder(),
                                        //               ),
                                        //               onChanged: (value) async {
                                        //                 setState(() {
                                        //                   motorFormSqlDb
                                        //                           .vehicleType =
                                        //                       value;
                                        //                 });
                                        //                 await _updateMotorForm(
                                        //                     motorFormSqlDb.id,
                                        //                     'vehicleType',
                                        //                     motorFormSqlDb
                                        //                         .vehicleType);
                                        //               },
                                        //               validator: (value) {
                                        //                 if (value.isEmpty) {
                                        //                   return 'Please enter vehicleType!';
                                        //                 }
                                        //                 return null;
                                        //               },
                                        //               onSaved: (value) {
                                        //                 motorFormSqlDb
                                        //                         .vehicleType =
                                        //                     value;
                                        //               },
                                        //             ),
                                        //           )
                                        //     : Container(
                                        //         color: bScaffoldBackgroundColor,
                                        //         child:
                                        //             SearchableDropdown.single(
                                        //           items: _vehicleType,
                                        //           value: motorFormSqlDb
                                        //                       .vehicleType !=
                                        //                   null
                                        //               ? motorFormSqlDb
                                        //                   .vehicleType
                                        //               : _initialValueVehicleType,
                                        //           hint: "Select vehicleType",
                                        //           searchHint:
                                        //               "Select vehicleType",
                                        //           onChanged: (value) async {
                                        //             setState(() {
                                        //               motorFormSqlDb
                                        //                   .vehicleType = value;
                                        //             });
                                        //             await _updateMotorForm(
                                        //                 motorFormSqlDb.id,
                                        //                 'vehicleType',
                                        //                 motorFormSqlDb
                                        //                     .vehicleType);
                                        //           },
                                        //           validator: (value) {
                                        //             if (value ==
                                        //                 'Unspecified') {
                                        //               print(
                                        //                   'vehicle type 1 Unspecified');
                                        //               _searchableValidate =
                                        //                   false;
                                        //               return 'Please select vehicleType! - $value';
                                        //             }
                                        //             _searchableValidate = true;
                                        //             return null;
                                        //           },
                                        //           isExpanded: true,
                                        //         ),
                                        //       ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Engine',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              15,
                                          child: TextFormField(
                                            key: ValueKey('engine'),
                                            // onEditingComplete: () =>
                                            //     focusNode.nextFocus(),
                                            focusNode: textFocusEngine,
                                            initialValue: motorFormSqlDb.engine,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.engine = value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'engine',
                                                  motorFormSqlDb.engine);
                                            },
                                            validator: (value) {
                                              if (value.isEmpty) {
                                                return 'Please enter engine!';
                                              }
                                              return null;
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.engine = value;
                                            },
                                            onTap: () {
                                              textFocusMileage.unfocus();
                                              textFocusEC.unfocus();
                                              textFocusOptions.unfocus();
                                              textFocusSubModel.unfocus();
                                              textFocusNC.unfocus();
                                              textFocusSF.unfocus();
                                              textFocusTrim.unfocus();
                                              textFocusIC.unfocus();

                                              textFocusWarranty.unfocus();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Options (Optional)',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          child: TextFormField(
                                            maxLines: 5,
                                            key: ValueKey('options'),
                                            focusNode: textFocusOptions,
                                            // onEditingComplete: () =>
                                            //     focusNode.nextFocus(),
                                            initialValue:
                                                motorFormSqlDb.options,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.options = value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'options',
                                                  motorFormSqlDb.options);
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.options = value;
                                            },
                                            onTap: () {
                                              textFocusMileage.unfocus();
                                              textFocusEC.unfocus();
                                              textFocusEngine.unfocus();
                                              textFocusSubModel.unfocus();
                                              textFocusNC.unfocus();
                                              textFocusSF.unfocus();
                                              textFocusTrim.unfocus();
                                              textFocusIC.unfocus();

                                              textFocusWarranty.unfocus();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Sub Model (Optional)',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        // Container(
                                        //   color: bScaffoldBackgroundColor,
                                        //   child:
                                        //       DropdownButtonFormField<String>(
                                        //     items: _subModel,
                                        //     decoration: const InputDecoration(
                                        //       border: OutlineInputBorder(),
                                        //     ),
                                        //     onChanged: (value) async {
                                        //       setState(() {
                                        //         motorFormSqlDb.subModel = value;
                                        //       });
                                        //       await _updateMotorForm(
                                        //           motorFormSqlDb.id,
                                        //           'subModel',
                                        //           motorFormSqlDb.subModel);
                                        //     },
                                        //     onSaved: (value) {
                                        //       motorFormSqlDb.subModel = value;
                                        //     },
                                        //     validator: (value) {
                                        //       if (value == 'Unspecified') {
                                        //         return 'Please select Sub Model!';
                                        //       }
                                        //       return null;
                                        //     },
                                        //     value:
                                        //         motorFormSqlDb.subModel != null
                                        //             ? motorFormSqlDb.subModel
                                        //             : _initialSelectedItem,
                                        //   ),
                                        // ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              15,
                                          child: TextFormField(
                                            key: ValueKey('subModel'),
                                            focusNode: textFocusSubModel,
                                            // onEditingComplete: () =>
                                            //     focusNode.nextFocus(),
                                            // keyboardType: TextInputType.number,
                                            initialValue:
                                                motorFormSqlDb.subModel,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.subModel = value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'subModel',
                                                  motorFormSqlDb.subModel);
                                            },
                                            // validator: (value) {
                                            //   if (value.isEmpty) {
                                            //     return 'Please enter Sub Model!';
                                            //   }
                                            //   return null;
                                            // },
                                            onSaved: (value) {
                                              motorFormSqlDb.subModel = value;
                                            },
                                            onTap: () {
                                              textFocusMileage.unfocus();
                                              textFocusEC.unfocus();
                                              textFocusEngine.unfocus();
                                              textFocusOptions.unfocus();
                                              textFocusNC.unfocus();
                                              textFocusSF.unfocus();
                                              textFocusTrim.unfocus();
                                              textFocusIC.unfocus();

                                              textFocusWarranty.unfocus();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Number of Cylinders',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              15,
                                          child: TextFormField(
                                            key: ValueKey('numberOfCylinders'),
                                            // onEditingComplete: () =>
                                            //     focusNode.nextFocus(),
                                            focusNode: textFocusNC,
                                            keyboardType: TextInputType.number,
                                            initialValue: motorFormSqlDb
                                                .numberOfCylinders,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb
                                                    .numberOfCylinders = value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'numberOfCylinders',
                                                  motorFormSqlDb
                                                      .numberOfCylinders);
                                            },
                                            validator: (value) {
                                              if (value.isEmpty) {
                                                return 'Please enter numberOfCylinders!';
                                              }
                                              return null;
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.numberOfCylinders =
                                                  value;
                                            },
                                            onTap: () {
                                              textFocusMileage.unfocus();
                                              textFocusEC.unfocus();
                                              textFocusEngine.unfocus();
                                              textFocusOptions.unfocus();
                                              textFocusSubModel.unfocus();
                                              textFocusSF.unfocus();
                                              textFocusTrim.unfocus();
                                              textFocusIC.unfocus();

                                              textFocusWarranty.unfocus();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Safety Features (Optional)',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              15,
                                          child: TextFormField(
                                            key: ValueKey('safetyFeatures'),
                                            // onEditingComplete: () =>
                                            //     focusNode.nextFocus(),
                                            focusNode: textFocusSF,
                                            initialValue: motorFormSqlDb
                                                        .safetyFeatures !=
                                                    null
                                                ? motorFormSqlDb.safetyFeatures
                                                : '',
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.safetyFeatures =
                                                    value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'safetyFeatures',
                                                  motorFormSqlDb
                                                      .safetyFeatures);
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.safetyFeatures =
                                                  value;
                                            },
                                            onTap: () {
                                              textFocusMileage.unfocus();
                                              textFocusEC.unfocus();
                                              textFocusEngine.unfocus();
                                              textFocusOptions.unfocus();
                                              textFocusSubModel.unfocus();
                                              textFocusNC.unfocus();
                                              textFocusTrim.unfocus();
                                              textFocusIC.unfocus();

                                              textFocusWarranty.unfocus();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Drive Type',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          child:
                                              DropdownButtonFormField<String>(
                                            items: _driveType,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.driveType =
                                                    value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'driveType',
                                                  motorFormSqlDb.driveType);
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.driveType = value;
                                            },
                                            onTap: () {
                                              _unFocusAll();
                                            },
                                            validator: (value) {
                                              if (value == 'Unspecified') {
                                                return 'Please select Drive Type!';
                                              }
                                              return null;
                                            },
                                            value:
                                                motorFormSqlDb.driveType != null
                                                    ? motorFormSqlDb.driveType
                                                    : _initialValueDriveType,
                                          ),
                                        ),
                                        // (motorFormSqlDb.driveType != null)
                                        //     ? (_driveType.any((e) =>
                                        //             e.value
                                        //                 .trim()
                                        //                 .toLowerCase() ==
                                        //             motorFormSqlDb.driveType
                                        //                 .trim()
                                        //                 .toLowerCase()))
                                        //         ? Container(
                                        //             color:
                                        //                 bScaffoldBackgroundColor,
                                        //             child: SearchableDropdown
                                        //                 .single(
                                        //               items: _driveType,
                                        //               value: motorFormSqlDb
                                        //                           .driveType !=
                                        //                       null
                                        //                   ? motorFormSqlDb
                                        //                       .driveType
                                        //                   : _initialValueDriveType,
                                        //               hint: "Select driveType",
                                        //               searchHint:
                                        //                   "Select driveType",
                                        //               onChanged: (value) async {
                                        //                 setState(() {
                                        //                   motorFormSqlDb
                                        //                           .driveType =
                                        //                       value;
                                        //                 });
                                        //                 await _updateMotorForm(
                                        //                     motorFormSqlDb.id,
                                        //                     'driveType',
                                        //                     motorFormSqlDb
                                        //                         .driveType);
                                        //               },
                                        //               validator: (value) {
                                        //                 if (value ==
                                        //                     'Unspecified') {
                                        //                   print(
                                        //                       'drive type Unspecified');
                                        //                   _searchableValidate =
                                        //                       false;
                                        //                   return 'Please select driveType! - $value';
                                        //                 }
                                        //                 _searchableValidate =
                                        //                     true;
                                        //                 return null;
                                        //               },
                                        //               isExpanded: true,
                                        //             ),
                                        //           )
                                        //         : Container(
                                        //             color:
                                        //                 bScaffoldBackgroundColor,
                                        //             height:
                                        //                 MediaQuery.of(context)
                                        //                         .size
                                        //                         .height /
                                        //                     15,
                                        //             child: TextFormField(
                                        //               key:
                                        //                   ValueKey('driveType'),
                                        //               // onEditingComplete: () => focusNode.unfocus(),
                                        //               initialValue: motorFormSqlDb
                                        //                           .driveType !=
                                        //                       null
                                        //                   ? motorFormSqlDb
                                        //                       .driveType
                                        //                   : _initialValueDriveType,
                                        //               decoration:
                                        //                   const InputDecoration(
                                        //                 border:
                                        //                     OutlineInputBorder(),
                                        //               ),
                                        //               onChanged: (value) async {
                                        //                 setState(() {
                                        //                   motorFormSqlDb
                                        //                           .driveType =
                                        //                       value;
                                        //                 });
                                        //                 await _updateMotorForm(
                                        //                     motorFormSqlDb.id,
                                        //                     'driveType',
                                        //                     motorFormSqlDb
                                        //                         .driveType);
                                        //               },
                                        //               validator: (value) {
                                        //                 if (value.isEmpty) {
                                        //                   return 'Please enter driveType!';
                                        //                 }
                                        //                 return null;
                                        //               },
                                        //               onSaved: (value) {
                                        //                 motorFormSqlDb
                                        //                     .driveType = value;
                                        //               },
                                        //             ),
                                        //           )
                                        //     : Container(
                                        //         color: bScaffoldBackgroundColor,
                                        //         child:
                                        //             SearchableDropdown.single(
                                        //           items: _driveType,
                                        //           value: motorFormSqlDb
                                        //                       .driveType !=
                                        //                   null
                                        //               ? motorFormSqlDb.driveType
                                        //               : _initialValueDriveType,
                                        //           hint: "Select driveType",
                                        //           searchHint:
                                        //               "Select driveType",
                                        //           onChanged: (value) async {
                                        //             setState(() {
                                        //               motorFormSqlDb.driveType =
                                        //                   value;
                                        //             });
                                        //             await _updateMotorForm(
                                        //                 motorFormSqlDb.id,
                                        //                 'driveType',
                                        //                 motorFormSqlDb
                                        //                     .driveType);
                                        //           },
                                        //           validator: (value) {
                                        //             if (value ==
                                        //                 'Unspecified') {
                                        //               print(
                                        //                   'drive type Unspecified');
                                        //               _searchableValidate =
                                        //                   false;
                                        //               return 'Please select driveType! - $value';
                                        //             }
                                        //             _searchableValidate = true;
                                        //             return null;
                                        //           },
                                        //           isExpanded: true,
                                        //         ),
                                        //       ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Body Type',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          child:
                                              DropdownButtonFormField<String>(
                                            items: _bodyType,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.bodyType = value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'bodyType',
                                                  motorFormSqlDb.bodyType);
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.bodyType = value;
                                            },
                                            onTap: () {
                                              _unFocusAll();
                                            },
                                            validator: (value) {
                                              if (value == 'Unspecified') {
                                                return 'Please select Body Type!';
                                              }
                                              return null;
                                            },
                                            value:
                                                motorFormSqlDb.bodyType != null
                                                    ? motorFormSqlDb.bodyType
                                                    : _initialSelectedItem,
                                          ),
                                        ),
                                        // (motorFormSqlDb.bodyType != null)
                                        //     ? (_bodyType.any((e) =>
                                        //             e.value
                                        //                 .trim()
                                        //                 .toLowerCase() ==
                                        //             motorFormSqlDb.bodyType
                                        //                 .trim()
                                        //                 .toLowerCase()))
                                        //         ? Container(
                                        //             color:
                                        //                 bScaffoldBackgroundColor,
                                        //             child: SearchableDropdown
                                        //                 .single(
                                        //               items: _bodyType,
                                        //               value: motorFormSqlDb
                                        //                           .bodyType !=
                                        //                       null
                                        //                   ? motorFormSqlDb
                                        //                       .bodyType
                                        //                   : _initialValueBodyType,
                                        //               hint: "Select bodyType",
                                        //               searchHint:
                                        //                   "Select bodyType",
                                        //               onChanged: (value) async {
                                        //                 setState(() {
                                        //                   motorFormSqlDb
                                        //                       .bodyType = value;
                                        //                 });
                                        //                 await _updateMotorForm(
                                        //                     motorFormSqlDb.id,
                                        //                     'bodyType',
                                        //                     motorFormSqlDb
                                        //                         .bodyType);
                                        //               },
                                        //               validator: (value) {
                                        //                 if (value ==
                                        //                     'Unspecified') {
                                        //                   print(
                                        //                       'body type Unspecified');
                                        //                   _searchableValidate =
                                        //                       false;
                                        //                   return 'Please select bodyType! - $value';
                                        //                 }
                                        //                 _searchableValidate =
                                        //                     true;
                                        //                 return null;
                                        //               },
                                        //               isExpanded: true,
                                        //             ),
                                        //           )
                                        //         : Container(
                                        //             color:
                                        //                 bScaffoldBackgroundColor,
                                        //             height:
                                        //                 MediaQuery.of(context)
                                        //                         .size
                                        //                         .height /
                                        //                     15,
                                        //             child: TextFormField(
                                        //               key: ValueKey('bodyType'),
                                        //               // onEditingComplete: () => focusNode.unfocus(),
                                        //               initialValue:
                                        //                   motorFormSqlDb
                                        //                       .bodyType,
                                        //               decoration:
                                        //                   const InputDecoration(
                                        //                 border:
                                        //                     OutlineInputBorder(),
                                        //               ),
                                        //               onChanged: (value) async {
                                        //                 setState(() {
                                        //                   motorFormSqlDb
                                        //                       .bodyType = value;
                                        //                 });
                                        //                 await _updateMotorForm(
                                        //                     motorFormSqlDb.id,
                                        //                     'bodyType',
                                        //                     motorFormSqlDb
                                        //                         .bodyType);
                                        //               },
                                        //               validator: (value) {
                                        //                 if (value.isEmpty) {
                                        //                   return 'Please enter bodyType!';
                                        //                 }
                                        //                 return null;
                                        //               },
                                        //               onSaved: (value) {
                                        //                 motorFormSqlDb
                                        //                     .bodyType = value;
                                        //               },
                                        //             ),
                                        //           )
                                        //     : Container(
                                        //         color: bScaffoldBackgroundColor,
                                        //         child:
                                        //             SearchableDropdown.single(
                                        //           items: _bodyType,
                                        //           value: motorFormSqlDb
                                        //                       .bodyType !=
                                        //                   null
                                        //               ? motorFormSqlDb.bodyType
                                        //               : _initialSelectedItem,
                                        //           hint: "Select bodyType",
                                        //           searchHint: "Select bodyType",
                                        //           onChanged: (value) async {
                                        //             setState(() {
                                        //               motorFormSqlDb.bodyType =
                                        //                   value;
                                        //             });
                                        //             await _updateMotorForm(
                                        //                 motorFormSqlDb.id,
                                        //                 'bodyType',
                                        //                 motorFormSqlDb
                                        //                     .bodyType);
                                        //           },
                                        //           validator: (value) {
                                        //             if (value ==
                                        //                 'Unspecified') {
                                        //               print(
                                        //                   'body type1 Unspecified');
                                        //               _searchableValidate =
                                        //                   false;
                                        //               return 'Please select bodyType! - $value';
                                        //             }
                                        //             _searchableValidate = true;
                                        //             return null;
                                        //           },
                                        //           isExpanded: true,
                                        //         ),
                                        //       ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Trim (Optional)',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              12,
                                          child: TextFormField(
                                            key: ValueKey('trim'),
                                            focusNode: textFocusTrim,
                                            // onEditingComplete: () =>
                                            //     focusNode.nextFocus(),
                                            initialValue:
                                                motorFormSqlDb.trim != null
                                                    ? motorFormSqlDb.trim
                                                    : ' ',
                                            decoration: const InputDecoration(
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.trim = value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'trim',
                                                  motorFormSqlDb.trim);
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.trim = value;
                                            },
                                            onTap: () {
                                              textFocusMileage.unfocus();
                                              textFocusEC.unfocus();
                                              textFocusEngine.unfocus();
                                              textFocusOptions.unfocus();
                                              textFocusSubModel.unfocus();
                                              textFocusNC.unfocus();
                                              textFocusSF.unfocus();
                                              textFocusIC.unfocus();

                                              textFocusWarranty.unfocus();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Transmission',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        // (motorFormSqlDb.transmission != null)
                                        //     ? (_transmission.any((e) =>
                                        //             e.value
                                        //                 .trim()
                                        //                 .toLowerCase() ==
                                        //             motorFormSqlDb.transmission
                                        //                 .trim()
                                        //                 .toLowerCase()))
                                        //         ? Container(
                                        //             color:
                                        //                 bScaffoldBackgroundColor,
                                        //             child: SearchableDropdown
                                        //                 .single(
                                        //               items: _transmission,
                                        //               value: motorFormSqlDb
                                        //                           .transmission !=
                                        //                       null
                                        //                   ? motorFormSqlDb
                                        //                       .transmission
                                        //                   : _initialValueTransmission,
                                        //               hint:
                                        //                   "Select transmission",
                                        //               searchHint:
                                        //                   "Select transmission",
                                        //               onChanged: (value) async {
                                        //                 setState(() {
                                        //                   motorFormSqlDb
                                        //                           .transmission =
                                        //                       value;
                                        //                 });
                                        //                 await _updateMotorForm(
                                        //                     motorFormSqlDb.id,
                                        //                     'transmission',
                                        //                     motorFormSqlDb
                                        //                         .transmission);
                                        //               },
                                        //               validator: (value) {
                                        //                 if (value ==
                                        //                     'Unspecified') {
                                        //                   print(
                                        //                       'transmission Unspecified');
                                        //                   _searchableValidate =
                                        //                       false;
                                        //                   return 'Please select transmission! - $value';
                                        //                 }
                                        //                 _searchableValidate =
                                        //                     true;
                                        //                 return null;
                                        //               },
                                        //               isExpanded: true,
                                        //             ),
                                        //           )
                                        //         : Container(
                                        //             color:
                                        //                 bScaffoldBackgroundColor,
                                        //             height:
                                        //                 MediaQuery.of(context)
                                        //                         .size
                                        //                         .height /
                                        //                     15,
                                        //             child: TextFormField(
                                        //               key: ValueKey(
                                        //                   'transmission'),
                                        //               // onEditingComplete: () => focusNode.unfocus(),
                                        //               initialValue: motorFormSqlDb
                                        //                           .transmission !=
                                        //                       null
                                        //                   ? motorFormSqlDb
                                        //                       .transmission
                                        //                   : _initialValueTransmission,
                                        //               decoration:
                                        //                   const InputDecoration(
                                        //                 border:
                                        //                     OutlineInputBorder(),
                                        //               ),
                                        //               onChanged: (value) async {
                                        //                 setState(() {
                                        //                   motorFormSqlDb
                                        //                           .transmission =
                                        //                       value;
                                        //                 });
                                        //                 await _updateMotorForm(
                                        //                     motorFormSqlDb.id,
                                        //                     'transmission',
                                        //                     motorFormSqlDb
                                        //                         .transmission);
                                        //               },
                                        //               validator: (value) {
                                        //                 if (value.isEmpty) {
                                        //                   return 'Please enter transmission!';
                                        //                 }
                                        //                 return null;
                                        //               },
                                        //               onSaved: (value) {
                                        //                 motorFormSqlDb
                                        //                         .transmission =
                                        //                     value;
                                        //               },
                                        //             ),
                                        //           )
                                        //     : Container(
                                        //         color: bScaffoldBackgroundColor,
                                        //         child:
                                        //             SearchableDropdown.single(
                                        //           items: _transmission,
                                        //           value: motorFormSqlDb
                                        //                       .transmission !=
                                        //                   null
                                        //               ? motorFormSqlDb
                                        //                   .transmission
                                        //               : _initialSelectedItem,
                                        //           hint: "Select transmission",
                                        //           searchHint:
                                        //               "Select transmission",
                                        //           onChanged: (value) async {
                                        //             setState(() {
                                        //               motorFormSqlDb
                                        //                   .transmission = value;
                                        //             });
                                        //             await _updateMotorForm(
                                        //                 motorFormSqlDb.id,
                                        //                 'transmission',
                                        //                 motorFormSqlDb
                                        //                     .transmission);
                                        //           },
                                        //           validator: (value) {
                                        //             if (value ==
                                        //                 'Unspecified') {
                                        //               print(
                                        //                   'transmission1 Unspecified');
                                        //               _searchableValidate =
                                        //                   false;
                                        //               return 'Please select transmission! - $value';
                                        //             }
                                        //             _searchableValidate = true;
                                        //             return null;
                                        //           },
                                        //           isExpanded: true,
                                        //         ),
                                        //       ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          child:
                                              DropdownButtonFormField<String>(
                                            items: _transmission,
                                            decoration: const InputDecoration(
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb.transmission =
                                                    value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'transmission',
                                                  motorFormSqlDb.transmission);
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.transmission =
                                                  value;
                                            },
                                            onTap: () {
                                              _unFocusAll();
                                            },
                                            validator: (value) {
                                              if (value == 'Unspecified') {
                                                return 'Please select Transmission!';
                                              }
                                              return null;
                                            },
                                            value: motorFormSqlDb
                                                        .transmission !=
                                                    null
                                                ? motorFormSqlDb.transmission
                                                : _initialValueTransmission,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    //
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Interior Color',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              15,
                                          child: TextFormField(
                                            key: ValueKey('interiorColor'),
                                            focusNode: textFocusIC,
                                            // onEditingComplete: () =>
                                            //     focusNode.nextFocus(),
                                            enabled: false,
                                            controller: controllerIC,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    //
                                    GestureDetector(
                                      onTap: () {
                                        _unFocusAll();
                                      },
                                      child: Column(
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _unFocusAll();
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      motorFormSqlDb
                                                              .interiorColor =
                                                          "Red";
                                                      controllerIC.text = "Red";
                                                    });
                                                    await _updateMotorForm(
                                                        motorFormSqlDb.id,
                                                        'interiorColor',
                                                        motorFormSqlDb
                                                            .interiorColor);
                                                    _unFocusAll();
                                                  },
                                                  child: const Text(''),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    shape: CircleBorder(
                                                      side: motorFormSqlDb
                                                                  .interiorColor ==
                                                              "Red"
                                                          ? const BorderSide(
                                                              width: 2,
                                                              style: BorderStyle
                                                                  .solid,
                                                            )
                                                          : BorderSide.none,
                                                    ),
                                                    primary: Colors.red[700],
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      motorFormSqlDb
                                                              .interiorColor =
                                                          "Orange";
                                                      controllerIC.text =
                                                          "Orange";
                                                    });
                                                    await _updateMotorForm(
                                                        motorFormSqlDb.id,
                                                        'interiorColor',
                                                        motorFormSqlDb
                                                            .interiorColor);
                                                    _unFocusAll();
                                                  },
                                                  child: const Text(''),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    shape: CircleBorder(
                                                      side: motorFormSqlDb
                                                                  .interiorColor ==
                                                              "Orange"
                                                          ? const BorderSide(
                                                              width: 2,
                                                              style: BorderStyle
                                                                  .solid,
                                                            )
                                                          : BorderSide.none,
                                                    ),
                                                    primary: Colors.orange[700],
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      motorFormSqlDb
                                                              .interiorColor =
                                                          "Yellow";
                                                      controllerIC.text =
                                                          "Yellow";
                                                    });
                                                    await _updateMotorForm(
                                                        motorFormSqlDb.id,
                                                        'interiorColor',
                                                        motorFormSqlDb
                                                            .interiorColor);
                                                    _unFocusAll();
                                                  },
                                                  child: const Text(''),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    shape: CircleBorder(
                                                      side: motorFormSqlDb
                                                                  .interiorColor ==
                                                              "Yellow"
                                                          ? const BorderSide(
                                                              width: 2,
                                                              style: BorderStyle
                                                                  .solid,
                                                            )
                                                          : BorderSide.none,
                                                    ),
                                                    primary: Colors.yellow[700],
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      motorFormSqlDb
                                                              .interiorColor =
                                                          "Green";
                                                      controllerIC.text =
                                                          "Green";
                                                    });
                                                    await _updateMotorForm(
                                                        motorFormSqlDb.id,
                                                        'interiorColor',
                                                        motorFormSqlDb
                                                            .interiorColor);
                                                    _unFocusAll();
                                                  },
                                                  child: const Text(''),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    shape: CircleBorder(
                                                      side: motorFormSqlDb
                                                                  .interiorColor ==
                                                              "Green"
                                                          ? const BorderSide(
                                                              width: 2,
                                                              style: BorderStyle
                                                                  .solid,
                                                            )
                                                          : BorderSide.none,
                                                    ),
                                                    primary: Colors.green[700],
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      motorFormSqlDb
                                                              .interiorColor =
                                                          "Blue";
                                                      controllerIC.text =
                                                          "Blue";
                                                    });
                                                    await _updateMotorForm(
                                                        motorFormSqlDb.id,
                                                        'interiorColor',
                                                        motorFormSqlDb
                                                            .interiorColor);
                                                    _unFocusAll();
                                                  },
                                                  child: const Text(''),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    shape: CircleBorder(
                                                      side: motorFormSqlDb
                                                                  .interiorColor ==
                                                              "Blue"
                                                          ? const BorderSide(
                                                              width: 2,
                                                              style: BorderStyle
                                                                  .solid,
                                                            )
                                                          : BorderSide.none,
                                                    ),
                                                    primary: Colors.blue[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    motorFormSqlDb
                                                            .interiorColor =
                                                        "Purple";
                                                    controllerIC.text =
                                                        "Purple";
                                                  });
                                                  await _updateMotorForm(
                                                      motorFormSqlDb.id,
                                                      'interiorColor',
                                                      motorFormSqlDb
                                                          .interiorColor);
                                                  _unFocusAll();
                                                },
                                                child: const Text(''),
                                                style: ElevatedButton.styleFrom(
                                                  shape: CircleBorder(
                                                    side: motorFormSqlDb
                                                                .interiorColor ==
                                                            "Purple"
                                                        ? const BorderSide(
                                                            width: 2,
                                                            style: BorderStyle
                                                                .solid,
                                                          )
                                                        : BorderSide.none,
                                                  ),
                                                  primary: Colors.purple[700],
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    motorFormSqlDb
                                                            .interiorColor =
                                                        "Black";
                                                    controllerIC.text = "Black";
                                                  });
                                                  await _updateMotorForm(
                                                      motorFormSqlDb.id,
                                                      'interiorColor',
                                                      motorFormSqlDb
                                                          .interiorColor);
                                                  _unFocusAll();
                                                },
                                                child: const Text(''),
                                                style: ElevatedButton.styleFrom(
                                                  shape: CircleBorder(
                                                    side: motorFormSqlDb
                                                                .interiorColor ==
                                                            "Black"
                                                        ? BorderSide(
                                                            width: 2,
                                                            style: BorderStyle
                                                                .solid,
                                                            color: Colors
                                                                .grey[200],
                                                          )
                                                        : BorderSide.none,
                                                  ),
                                                  primary: Colors.black,
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    motorFormSqlDb
                                                        .interiorColor = "Grey";
                                                    controllerIC.text = "Grey";
                                                  });
                                                  await _updateMotorForm(
                                                      motorFormSqlDb.id,
                                                      'interiorColor',
                                                      motorFormSqlDb
                                                          .interiorColor);
                                                  _unFocusAll();
                                                },
                                                child: const Text(''),
                                                style: ElevatedButton.styleFrom(
                                                  shape: CircleBorder(
                                                    side: motorFormSqlDb
                                                                .interiorColor ==
                                                            "Grey"
                                                        ? const BorderSide(
                                                            width: 2,
                                                            style: BorderStyle
                                                                .solid,
                                                          )
                                                        : BorderSide.none,
                                                  ),
                                                  primary: Colors.grey[300],
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    motorFormSqlDb
                                                            .interiorColor =
                                                        "Brown";
                                                    controllerIC.text = "Brown";
                                                  });
                                                  await _updateMotorForm(
                                                      motorFormSqlDb.id,
                                                      'interiorColor',
                                                      motorFormSqlDb
                                                          .interiorColor);
                                                  _unFocusAll();
                                                },
                                                child: const Text(''),
                                                style: ElevatedButton.styleFrom(
                                                  shape: CircleBorder(
                                                    side: motorFormSqlDb
                                                                .interiorColor ==
                                                            "Brown"
                                                        ? const BorderSide(
                                                            width: 2,
                                                            style: BorderStyle
                                                                .solid,
                                                          )
                                                        : BorderSide.none,
                                                  ),
                                                  primary: Colors.brown[500],
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    motorFormSqlDb
                                                            .interiorColor =
                                                        "White";
                                                    controllerIC.text = "White";
                                                  });
                                                  await _updateMotorForm(
                                                      motorFormSqlDb.id,
                                                      'interiorColor',
                                                      motorFormSqlDb
                                                          .interiorColor);
                                                  _unFocusAll();
                                                },
                                                child: const Text(''),
                                                style: ElevatedButton.styleFrom(
                                                  shape: CircleBorder(
                                                    side: motorFormSqlDb
                                                                .interiorColor ==
                                                            "White"
                                                        ? const BorderSide(
                                                            width: 2,
                                                            style: BorderStyle
                                                                .solid,
                                                          )
                                                        : BorderSide.none,
                                                  ),
                                                  primary: bBackgroundColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Column(
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Steering Location',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        // Container(
                                        //   color: bScaffoldBackgroundColor,
                                        //   height: MediaQuery.of(context)
                                        //           .size
                                        //           .height /
                                        //       15,
                                        //   child: TextFormField(
                                        //     key: ValueKey('steeringLocation'),
                                        //     // onEditingComplete: () =>
                                        //     //     focusNode.nextFocus(),
                                        //     initialValue: motorFormSqlDb
                                        //                 .steeringLocation !=
                                        //             null
                                        //         ? motorFormSqlDb
                                        //             .steeringLocation
                                        //         : '',
                                        //     decoration: const InputDecoration(
                                        //       border:
                                        //           const OutlineInputBorder(),
                                        //     ),
                                        //     onChanged: (value) async {
                                        //       setState(() {
                                        //         motorFormSqlDb
                                        //             .steeringLocation = value;
                                        //       });
                                        //       await _updateMotorForm(
                                        //           motorFormSqlDb.id,
                                        //           'steeringLocation',
                                        //           motorFormSqlDb
                                        //               .steeringLocation);
                                        //     },
                                        //     onSaved: (value) {
                                        //       motorFormSqlDb.steeringLocation =
                                        //           value;
                                        //     },
                                        //   ),
                                        // ),

                                        Container(
                                          color: bScaffoldBackgroundColor,
                                          child:
                                              DropdownButtonFormField<String>(
                                            items: _steeringLocation,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) async {
                                              setState(() {
                                                motorFormSqlDb
                                                    .steeringLocation = value;
                                              });
                                              await _updateMotorForm(
                                                  motorFormSqlDb.id,
                                                  'steeringLocation',
                                                  motorFormSqlDb
                                                      .steeringLocation);
                                            },
                                            onSaved: (value) {
                                              motorFormSqlDb.steeringLocation =
                                                  value;
                                            },
                                            onTap: () {
                                              _unFocusAll();
                                            },
                                            validator: (value) {
                                              if (value == 'Unspecified') {
                                                return 'Please select steering Location!';
                                              }
                                              return null;
                                            },
                                            value: motorFormSqlDb
                                                        .steeringLocation !=
                                                    null
                                                ? motorFormSqlDb
                                                    .steeringLocation
                                                : _initialValueSteeringLocation,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),

                              Column(
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Warranty in years (Optional)',
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Container(
                                    color: bScaffoldBackgroundColor,
                                    height:
                                        MediaQuery.of(context).size.height / 15,
                                    child: TextFormField(
                                      key: ValueKey('warranty'),
                                      // onEditingComplete: () =>
                                      //     focusNode.nextFocus(),
                                      focusNode: textFocusWarranty,

                                      initialValue: motorFormSqlDb.warranty,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) async {
                                        setState(() {
                                          motorFormSqlDb.warranty = value;
                                        });
                                        await _updateMotorForm(
                                            motorFormSqlDb.id,
                                            'warranty',
                                            motorFormSqlDb.warranty);
                                      },
                                      onSaved: (value) {
                                        motorFormSqlDb.warranty = value;
                                      },
                                      onTap: () {
                                        textFocusMileage.unfocus();
                                        textFocusEC.unfocus();
                                        textFocusEngine.unfocus();
                                        textFocusOptions.unfocus();
                                        textFocusSubModel.unfocus();
                                        textFocusNC.unfocus();
                                        textFocusSF.unfocus();
                                        textFocusTrim.unfocus();
                                        textFocusIC.unfocus();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const Text('Please Continue Further!!'),
                            ],
                          ),
                ],
              ),
            ),
          ),
        ),
      ),
      Step(
        title: const Text('Review'),
        isActive: _currentStep >= 0,
        state: _currentStep >= 3 ? StepState.complete : StepState.disabled,
        content: Form(
          key: formKeys[3],
          child: Column(
            children: <Widget>[
              const Text('Select Location'),
              SearchPlaceAutoCompleteWidgetCustom(
                apiKey: placeApiKey,
                components: _countryCode,
                placeType: smp.PlaceType.address,
                onSelected: (place) async {
                  print('place - ${place.description}');
                  setState(() {
                    _addressLocation = '';
                    _latitude = 0.0;
                    _longitude = 0.0;
                  });
                  await getCurrentLocation.getselectedPosition(place);

                  setState(() {
                    _addressLocation = getCurrentLocation.addressLocation;
                    _latitude = getCurrentLocation.latitude;
                    _longitude = getCurrentLocation.longitude;
                  });
                },
              ),
              TextButton.icon(
                onPressed: () async {
                  setState(() {
                    _addressLocation = '';
                    _latitude = 0.0;
                    _longitude = 0.0;
                  });

                  await getCurrentLocation.getCurrentPosition();
                  setState(() {
                    _addressLocation = getCurrentLocation.addressLocation;
                    _latitude = getCurrentLocation.latitude;
                    _longitude = getCurrentLocation.longitude;
                  });
                },
                icon: Icon(Icons.my_location),
                label: const Text("Current location"),
              ),
              Text(_addressLocation),
            ],
          ),
        ),
      ),
    ];

    return GestureDetector(
      onTap: () {
        _unFocusAll();
      },
      child: Container(
        color: bBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: Stepper(
                type: StepperType.horizontal,
                physics: ClampingScrollPhysics(),
                currentStep: _currentStep,
                onStepTapped: (step) => tapped(step),
                onStepContinue: () async {
                  setState(() {
                    // motorFormSqlDb.editPost = widget.editPost;
                    bool _validate = true;
                    if (_currentStep > 0) {
                      print('check _searchableValidate - $_searchableValidate');
                      if (_currentStep == 1) {
                        if (!_searchableValidateMM) {
                          _validate = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Please select mandatory fields Make/Model! - $_searchableValidateMM'),
                            ),
                          );
                        }
                      }
                      if (_currentStep == 2) {
                        if (!_searchableValidate) {
                          _validate = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Please select mandatory fields! - $_searchableValidate'),
                            ),
                          );
                        }
                      }
                      if (_specialVehicle) {
                        // if (motorFormSqlDb.vehicleTypeYear == "CTA1981" &&
                        //     !_vinValidateFlag &&
                        //     motorFormSqlDb.year == null) {
                        //   _validate = false;
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(
                        //       content: const Text('Please validate VIN!'),
                        //     ),
                        //   );
                        // }
                        if (_currentStep > 1) {
                          if (motorFormSqlDb.exteriorColor == null) {
                            _validate = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    const Text('Please select exterior color!'),
                              ),
                            );
                          }

                          if (_specialVehicle) {
                            if (motorFormSqlDb.interiorColor == null) {
                              _validate = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: const Text(
                                      'Please select interior color!'),
                                ),
                              );
                            }
                          }
                        }
                      }

                      if (_validate) {
                        if (formKeys[_currentStep].currentState.validate()) {
                          formKeys[_currentStep].currentState.save();
                          if (_currentStep < steps.length - 1) {
                            _currentStep = _currentStep + 1;
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  const Text('Please Enter Mandatory Fields!'),
                            ),
                          );
                        }
                      }

                      if (_currentStep == 2) {
                        _addressLocation = '';
                        _latitude = 0.0;
                        _longitude = 0.0;
                      }
                    } else if (_currentStep == 0 && _totalImageCount > 0) {
                      if (userDetails[0].isProfileUpdated) {
                        _currentStep = _currentStep + 1;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Please Update Profile in \"MyBlrber" Profile Screen!'),
                            action: SnackBarAction(
                              label: 'Update',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) {
                                        return EditProfile();
                                      },
                                      fullscreenDialog: true),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: const Text('Please Select Image!')));
                    }
                  });
                },
                onStepCancel: cancel,
                steps: steps,
                controlsBuilder: (BuildContext context,
                    {VoidCallback onStepContinue, VoidCallback onStepCancel}) {
                  return Row(
                    children: <Widget>[
                      _currentStep < 3
                          ? ElevatedButton(
                              onPressed: onStepContinue,
                              child: const Text('Continue'),
                            )
                          : _addressLocation.isNotEmpty
                              ? ElevatedButton(
                                  onPressed: () async {
                                    print(
                                        'motorFormSqlDb.editPost - ${motorFormSqlDb.editPost}');

                                    await _showAddUpdatePostDialog(
                                        motorFormSqlDb.editPost);
                                  },
                                  child: const Text('Post Ad'),
                                )
                              : ElevatedButton(
                                  onPressed: () {},
                                  child: const CircularProgressIndicator(
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            bScaffoldBackgroundColor),
                                    backgroundColor: bPrimaryColor,
                                  ),
                                ),
                      TextButton(
                        onPressed: onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI design Widgets

  Widget motorDetailsUI() {
    return Column(
      children: [
        // if (motorFormSqlDb.catName != null)
        // if (_specialVehicle)
        // Column(
        //   children: [
        //     const SizedBox(
        //       height: 8,
        //     ),
        //     const Text('What type of vehicle are you selling?'),
        //     SizedBox(
        //       height: 10,
        //     ),
        //     CustomRadioButton(
        //       horizontal: true,
        //       unSelectedColor: Theme.of(context).canvasColor,
        //       buttonLables: [
        //         'Car or Truck (Pre 1981)',
        //         'Car or Truck (1981 - Today)',
        //       ],
        //       buttonValues: [
        //         "CTB1981",
        //         "CTA1981",
        //       ],
        //       defaultSelected: motorFormSqlDb.vehicleTypeYear,
        //       radioButtonValue: (value) async {
        //         setState(() {
        //           motorFormSqlDb.vehicleTypeYear = value;
        //         });

        //         await _updateMotorForm(
        //             motorFormSqlDb.id, 'vehicleTypeYear', value);
        //         if (value == "CTA1981") {
        //           setState(() {
        //             cTA1981 = true;
        //           });
        //         } else {
        //           setState(() {
        //             cTA1981 = false;
        //           });
        //         }
        //       },
        //       selectedColor: Colors.blue[200],
        //       unSelectedBorderColor: Colors.grey,
        //       selectedBorderColor: Colors.blue[200],
        //       elevation: 0.0,
        //       enableShape: false,
        //     ),
        //     const SizedBox(
        //       height: 10,
        //     ),
        //     TextFormField(
        //       key: ValueKey('vin'),
        //       focusNode: textFocusVin,
        //       initialValue: motorFormSqlDb.vin,
        //       // onEditingComplete: () => focusNode.nextFocus(),

        //       decoration: const InputDecoration(
        //           border: OutlineInputBorder(), labelText: 'VIN'),
        //       onTap: () {
        //         textFocusYear.unfocus();
        //         textFocusTitle.unfocus();
        //         textFocusMake.unfocus();
        //         textFocusModel.unfocus();
        //         textFocusPrice.unfocus();
        //         textFocusStock.unfocus();
        //         textFocusDes.unfocus();
        //         textFocusSell.unfocus();
        //       },

        //       onChanged: (value) async {
        //         setState(() {
        //           motorFormSqlDb.vin = value;
        //         });
        //         await _updateMotorForm(
        //             motorFormSqlDb.id, 'vin', motorFormSqlDb.vin);
        //         if (value.length == 17) {
        //           setState(() {
        //             _enableVinValButton = true;
        //           });
        //         } else {
        //           _enableVinValButton = false;
        //         }
        //       },
        //       validator: (value) {
        //         if (motorFormSqlDb.vehicleTypeYear == 'CTA1981') {
        //           // if (value.isEmpty) {
        //           //   return 'Please enter VIN';
        //           // } else
        //           if (value.length > 0 && value.length < 17) {
        //             return 'Please enter valid VIN, should be 17 letters.';
        //           }
        //         }
        //         return null;
        //       },
        //       onSaved: (value) async {
        //         motorFormSqlDb.vin = value;
        //       },
        //     ),
        //   ],
        // ),
        // SizedBox(
        //   height: 10,
        // ),
        // if (motorFormSqlDb.vehicleTypeYear == 'CTA1981' && _specialVehicle)
        //   _enableVinValButton
        //       ? OutlineButton(
        //           shape: StadiumBorder(),
        //           textColor: Colors.blue,
        //           child: const Text('Validate VIN'),
        //           borderSide: const BorderSide(
        //               color: Colors.grey, style: BorderStyle.solid, width: 1),
        //           onPressed: () async {
        //             _vinValidateFlag = false;
        //             await _validateVIN(motorFormSqlDb.vin).then((value) {
        //               setState(() {
        //                 _vinValidateFlag = true;
        //               });
        //             });
        //           },
        //         )
        //       : TextButton(
        //           onPressed: () {
        //             setState(() {
        //               _vinValidateFlag = true;
        //             });
        //           },
        //           child: Text("Don't have VIN!")),
        // const SizedBox(
        //   height: 10,
        // ),
        // !_vinValidateFlag &&
        //         motorFormSqlDb.vehicleTypeYear == 'CTA1981' &&
        //         _specialVehicle &&
        //         motorFormSqlDb.year == null
        //     ? Container(
        //         height: 0,
        //         width: 0,
        //       )
        //     :

        Column(
          children: [
            // Year
            Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Year',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  height: MediaQuery.of(context).size.height / 15,
                  child: TextFormField(
                    // onEditingComplete: () => focusNode.nextFocus(),
                    keyboardType: TextInputType.number,
                    key: ValueKey('year'),
                    focusNode: textFocusYear,
                    initialValue:
                        motorFormSqlDb.year != null ? motorFormSqlDb.year : '',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      // textFocusVin.unfocus();
                      textFocusTitle.unfocus();
                      textFocusMake.unfocus();
                      textFocusModel.unfocus();
                      textFocusPrice.unfocus();
                      textFocusStock.unfocus();
                      textFocusDes.unfocus();
                      textFocusSell.unfocus();
                    },
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.year = value;
                      });
                      await _updateMotorForm(
                          motorFormSqlDb.id, 'year', motorFormSqlDb.year);
                    },
                    onSaved: (value) {
                      motorFormSqlDb.year = value;
                    },
                    validator: (value) {
                      // if (_specialVehicle) {
                      //   if (value.isNotEmpty) {
                      //     var yr = num.parse(value.trim());
                      //     if ((motorFormSqlDb.vehicleTypeYear == 'CTA1981') &&
                      //         yr < 1981) {
                      //       return 'Please enter product year greater than 1981';
                      //     } else if (motorFormSqlDb.vehicleTypeYear ==
                      //         'CTB1981') {
                      //       if (yr >= 1981) {
                      //         return 'Year must be < 1981 or Please select option \"Car or Truck (1981 - Today)" & validate VIN!';
                      //       }
                      //     }
                      //   }
                      // }
                      if (value.isEmpty) {
                        return 'Please enter year!';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            // Prod Name
            Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Title',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  height: MediaQuery.of(context).size.height / 15,
                  child: TextFormField(
                    key: ValueKey('prodName'),
                    focusNode: textFocusTitle,
                    // onEditingComplete: () => focusNode.unfocus(),
                    initialValue: motorFormSqlDb.prodName,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      // textFocusVin.unfocus();
                      textFocusYear.unfocus();
                      textFocusMake.unfocus();
                      textFocusModel.unfocus();
                      textFocusPrice.unfocus();
                      textFocusStock.unfocus();
                      textFocusDes.unfocus();
                      textFocusSell.unfocus();
                    },
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.prodName = value;
                      });
                      await _updateMotorForm(motorFormSqlDb.id, 'prodName',
                          motorFormSqlDb.prodName);
                    },
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter title!';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      motorFormSqlDb.prodName = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),

            if (_makes != null)
              Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Make',
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  (motorFormSqlDb.make != null)
                      ? (_makes.any((e) =>
                                  e.value.trim().toLowerCase() ==
                                  motorFormSqlDb.make.trim().toLowerCase()) &&
                              motorFormSqlDb.make.trim().toLowerCase() !=
                                  'others')
                          ? Container(
                              color: bScaffoldBackgroundColor,
                              child: DropdownButtonFormField<String>(
                                items: _makes,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) async {
                                  setState(() {
                                    motorFormSqlDb.make = value;
                                  });
                                  await _updateMotorForm(motorFormSqlDb.id,
                                      'make', motorFormSqlDb.make);
                                },
                                onSaved: (value) {
                                  motorFormSqlDb.make = value;
                                },
                                onTap: () {
                                  _unFocusAll();
                                },
                                validator: (value) {
                                  if (value == 'Unspecified') {
                                    return 'Please select Make!';
                                  }
                                  return null;
                                },
                                value: motorFormSqlDb.make != null
                                    ? motorFormSqlDb.make
                                    : _initialSelectedItem,
                              ),
                            )
                          : Container(
                              color: bScaffoldBackgroundColor,
                              height: MediaQuery.of(context).size.height / 15,
                              child: TextFormField(
                                key: ValueKey('make'),
                                autofocus: true,
                                focusNode: textFocusMake,
                                // onEditingComplete: () => focusNode.unfocus(),
                                initialValue:
                                    motorFormSqlDb.make.toLowerCase().trim() ==
                                            "others"
                                        ? ""
                                        : motorFormSqlDb.make,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),

                                onTap: () {
                                  // textFocusVin.unfocus();
                                  textFocusYear.unfocus();
                                  textFocusTitle.unfocus();
                                  textFocusModel.unfocus();
                                  textFocusPrice.unfocus();
                                  textFocusStock.unfocus();
                                  textFocusDes.unfocus();
                                  textFocusSell.unfocus();
                                },
                                onChanged: (value) async {
                                  _searchableValidateMM = true;
                                  setState(() {
                                    motorFormSqlDb.make = value.toUpperCase();
                                  });
                                  await _updateMotorForm(motorFormSqlDb.id,
                                      'make', motorFormSqlDb.make);
                                },
                                validator: (value) {
                                  if (value.isEmpty ||
                                      value.trim().toLowerCase() == 'others') {
                                    return 'Please enter make!';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  motorFormSqlDb.make = value.toUpperCase();
                                },
                              ),
                            )
                      : Container(
                          color: bScaffoldBackgroundColor,
                          child: DropdownButtonFormField<String>(
                            items: _makes,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              _unFocusAll();
                            },
                            onChanged: (value) async {
                              setState(() {
                                motorFormSqlDb.make = value;
                              });
                              await _updateMotorForm(motorFormSqlDb.id, 'make',
                                  motorFormSqlDb.make);
                            },
                            onSaved: (value) {
                              motorFormSqlDb.make = value;
                            },
                            validator: (value) {
                              if (value == 'Unspecified') {
                                return 'Please select Make!';
                              }
                              return null;
                            },
                            value: motorFormSqlDb.make != null
                                ? motorFormSqlDb.make
                                : _initialSelectedItem,
                          ),
                        ),
                ],
              ),
            const SizedBox(
              height: 10,
            ),
            //Model
            if (_models != null)
              Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Model',
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  (motorFormSqlDb.model != null)
                      ? (_models.any((e) =>
                                  e.value.trim().toLowerCase() ==
                                  motorFormSqlDb.model.trim().toLowerCase()) &&
                              motorFormSqlDb.model.trim().toLowerCase() !=
                                  'others')
                          ? Container(
                              color: bScaffoldBackgroundColor,
                              child: DropdownButtonFormField<String>(
                                items: _models,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                onTap: () {
                                  _unFocusAll();
                                },
                                onChanged: (value) async {
                                  setState(() {
                                    motorFormSqlDb.model = value;
                                  });
                                  await _updateMotorForm(motorFormSqlDb.id,
                                      'model', motorFormSqlDb.model);
                                },
                                onSaved: (value) {
                                  motorFormSqlDb.model = value;
                                },
                                validator: (value) {
                                  if (value == 'Unspecified') {
                                    return 'Please select Model!';
                                  }
                                  return null;
                                },
                                value: motorFormSqlDb.model != null
                                    ? motorFormSqlDb.model
                                    : _initialSelectedItem,
                              ),
                            )
                          : Container(
                              color: bScaffoldBackgroundColor,
                              height: MediaQuery.of(context).size.height / 15,
                              child: TextFormField(
                                key: ValueKey('model'),
                                autofocus: true,
                                focusNode: textFocusModel,
                                // onEditingComplete: () => focusNode.unfocus(),
                                initialValue:
                                    motorFormSqlDb.model.toLowerCase().trim() ==
                                            "others"
                                        ? ""
                                        : motorFormSqlDb.model,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                onTap: () {
                                  // textFocusVin.unfocus();
                                  textFocusYear.unfocus();
                                  textFocusTitle.unfocus();
                                  textFocusMake.unfocus();
                                  textFocusPrice.unfocus();
                                  textFocusStock.unfocus();
                                  textFocusDes.unfocus();
                                  textFocusSell.unfocus();
                                },
                                onChanged: (value) async {
                                  _searchableValidateMM = true;
                                  setState(() {
                                    motorFormSqlDb.model = value.toUpperCase();
                                  });
                                  await _updateMotorForm(motorFormSqlDb.id,
                                      'model', motorFormSqlDb.model);
                                },
                                validator: (value) {
                                  if (value.isEmpty ||
                                      value.trim().toLowerCase() == 'others') {
                                    return 'Please enter model!';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  motorFormSqlDb.model = value.toUpperCase();
                                },
                              ),
                            )
                      : Container(
                          color: bScaffoldBackgroundColor,
                          child: DropdownButtonFormField<String>(
                            items: _models,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              _unFocusAll();
                            },
                            onChanged: (value) async {
                              setState(() {
                                motorFormSqlDb.model = value;
                              });
                              await _updateMotorForm(motorFormSqlDb.id, 'model',
                                  motorFormSqlDb.model);
                            },
                            onSaved: (value) {
                              motorFormSqlDb.model = value;
                            },
                            validator: (value) {
                              if (value == 'Unspecified') {
                                return 'Please select Model!';
                              }
                              return null;
                            },
                            value: motorFormSqlDb.model != null
                                ? motorFormSqlDb.model
                                : _initialSelectedItem,
                          ),
                        ),
                ],
              ),

            const SizedBox(
              height: 10,
            ),
            // Product Condition
            Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Product Condition',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  child: DropdownButtonFormField<String>(
                    items: _prodConditions,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.prodCondition = value;
                      });
                      await _updateMotorForm(motorFormSqlDb.id, 'prodCondition',
                          motorFormSqlDb.prodCondition);
                    },
                    onSaved: (value) {
                      motorFormSqlDb.prodCondition = value;
                    },
                    onTap: () {
                      _unFocusAll();
                    },
                    validator: (value) {
                      if (value == 'Unspecified') {
                        return 'Please select prod condition!';
                      }
                      return null;
                    },
                    value: motorFormSqlDb.prodCondition != null
                        ? motorFormSqlDb.prodCondition
                        : _initialValueProductCond,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Price $_currencySymbol',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  height: MediaQuery.of(context).size.height / 15,
                  child: TextFormField(
                    key: ValueKey('price'),
                    focusNode: textFocusPrice,
                    // onEditingComplete: () => focusNode.nextFocus(),
                    initialValue: motorFormSqlDb.price,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      // textFocusVin.unfocus();
                      textFocusYear.unfocus();
                      textFocusTitle.unfocus();
                      textFocusMake.unfocus();
                      textFocusModel.unfocus();
                      textFocusStock.unfocus();
                      textFocusDes.unfocus();
                      textFocusSell.unfocus();
                    },
                    keyboardType: TextInputType.number,
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.price = value;
                      });
                      await _updateMotorForm(
                          motorFormSqlDb.id, 'price', motorFormSqlDb.price);
                    },
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter price';
                      }
                      return null;
                    },

                    onSaved: (value) {
                      motorFormSqlDb.price = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Stock In Hand',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  height: MediaQuery.of(context).size.height / 15,
                  child: TextFormField(
                    key: ValueKey('stockInHand'),
                    focusNode: textFocusStock,
                    // onEditingComplete: () => focusNode.nextFocus(),
                    initialValue: motorFormSqlDb.stockInHand.toString(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onTap: () {
                      // textFocusVin.unfocus();
                      textFocusYear.unfocus();
                      textFocusTitle.unfocus();
                      textFocusMake.unfocus();
                      textFocusModel.unfocus();
                      textFocusPrice.unfocus();
                      textFocusDes.unfocus();
                      textFocusSell.unfocus();
                    },
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.stockInHand = value;
                      });
                      await _updateMotorForm(motorFormSqlDb.id, 'stockInHand',
                          motorFormSqlDb.stockInHand);
                    },
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter stockInHand';
                      }
                      return null;
                    },

                    onSaved: (value) {
                      motorFormSqlDb.stockInHand = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Description',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  child: TextFormField(
                    maxLines: 5,
                    focusNode: textFocusDes,
                    key: ValueKey('prodDes'),

                    // onEditingComplete: () => textFocusDes.unfocus(),
                    initialValue: motorFormSqlDb.prodDes,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      // textFocusVin.unfocus();
                      textFocusYear.unfocus();
                      textFocusTitle.unfocus();
                      textFocusMake.unfocus();
                      textFocusModel.unfocus();
                      textFocusPrice.unfocus();
                      textFocusStock.unfocus();
                      textFocusSell.unfocus();
                    },
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.prodDes = value;
                      });
                      await _updateMotorForm(
                          motorFormSqlDb.id, 'prodDes', motorFormSqlDb.prodDes);
                    },
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter description!';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      motorFormSqlDb.prodDes = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Seller Notes (Optional)',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  child: TextFormField(
                    focusNode: textFocusSell,
                    maxLines: 5,
                    key: ValueKey('sellerNotes'),

                    // onEditingComplete: () => textFocusSell.unfocus(),
                    initialValue: motorFormSqlDb.sellerNotes,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    onTap: () {
                      // textFocusVin.unfocus();
                      textFocusYear.unfocus();
                      textFocusTitle.unfocus();
                      textFocusMake.unfocus();
                      textFocusModel.unfocus();
                      textFocusPrice.unfocus();
                      textFocusStock.unfocus();
                      textFocusDes.unfocus();
                    },
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.sellerNotes = value;
                      });
                      await _updateMotorForm(motorFormSqlDb.id, 'sellerNotes',
                          motorFormSqlDb.sellerNotes);
                    },
                    // validator: (value) {
                    //   if (value.isEmpty) {
                    //     return 'Please enter seller notes!';
                    //   }
                    //   return null;
                    // },
                    onSaved: (value) {
                      motorFormSqlDb.sellerNotes = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Delivery Info',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  child: DropdownButtonFormField<String>(
                    items: _deliveryInfo,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.deliveryInfo = value;
                      });

                      await _updateMotorForm(motorFormSqlDb.id, 'deliveryInfo',
                          motorFormSqlDb.deliveryInfo);
                    },
                    onTap: () {
                      _unFocusAll();
                    },
                    onSaved: (value) {
                      motorFormSqlDb.deliveryInfo = value;
                    },
                    validator: (value) {
                      if (value == 'Unspecified') {
                        return 'Please select Delivery Info!';
                      }
                      return null;
                    },
                    value: motorFormSqlDb.deliveryInfo != null
                        ? motorFormSqlDb.deliveryInfo
                        : _initialValueDeliveryInfo,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Type of Ad',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  child: DropdownButtonFormField<String>(
                    items: _typeOfAd,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.typeOfAd = value;
                      });
                      await _updateMotorForm(motorFormSqlDb.id, 'typeOfAd',
                          motorFormSqlDb.typeOfAd);
                    },
                    onTap: () {
                      _unFocusAll();
                    },
                    onSaved: (value) {
                      motorFormSqlDb.typeOfAd = value;
                    },
                    validator: (value) {
                      if (value == 'Unspecified') {
                        return 'Please select Type of ad!';
                      }
                      return null;
                    },
                    value: motorFormSqlDb.typeOfAd != null
                        ? motorFormSqlDb.typeOfAd
                        : _initialValueTypeOfAd,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Posted By',
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  color: bScaffoldBackgroundColor,
                  child: DropdownButtonFormField<String>(
                    items: _forSaleBy,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      setState(() {
                        motorFormSqlDb.forSaleBy = value;
                      });
                      await _updateMotorForm(motorFormSqlDb.id, 'forSaleBy',
                          motorFormSqlDb.forSaleBy);
                    },
                    onSaved: (value) {
                      motorFormSqlDb.forSaleBy = value;
                    },
                    onTap: () {
                      _unFocusAll();
                    },
                    validator: (value) {
                      print(
                          "motorFormSqlDb.forSaleBy - ${motorFormSqlDb.forSaleBy}");
                      if (value == 'Unspecified') {
                        return 'Please select ForSaleBy!';
                      }
                      return null;
                    },
                    value: motorFormSqlDb.forSaleBy != null
                        ? motorFormSqlDb.forSaleBy
                        : _initialValuePostedBy,
                  ),
                ),
              ],
            )
          ],
        )
      ],
    );
  }

  void showAlertDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text("Post Ad?"),
            content: Text("Please update your profile with dealer info!"),
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

  Widget commonDetailsUI() {
    _searchableValidateMM = true;
    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Year',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              height: MediaQuery.of(context).size.height / 15,
              child: TextFormField(
                key: ValueKey('year'),
                keyboardType: TextInputType.number,
                focusNode: textFocusYear,
                // onEditingComplete: () => focusNode.nextFocus(),
                initialValue:
                    motorFormSqlDb.year != null ? motorFormSqlDb.year : '',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.year = value;
                  });
                  await _updateMotorForm(
                      motorFormSqlDb.id, 'year', motorFormSqlDb.year);
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter year!';
                  }
                  return null;
                },
                onSaved: (value) {
                  motorFormSqlDb.year = value;
                },
                onTap: () {
                  // textFocusVin.unfocus();
                  textFocusTitle.unfocus();
                  textFocusMake.unfocus();
                  textFocusModel.unfocus();
                  textFocusPrice.unfocus();
                  textFocusStock.unfocus();
                  textFocusDes.unfocus();
                  textFocusSell.unfocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        // Prod Name
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Title',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              height: MediaQuery.of(context).size.height / 15,
              child: TextFormField(
                key: ValueKey('prodName'),
                focusNode: textFocusTitle,
                // onEditingComplete: () => focusNode.dispose(),
                initialValue: motorFormSqlDb.prodName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.prodName = value;
                  });
                  await _updateMotorForm(
                      motorFormSqlDb.id, 'prodName', motorFormSqlDb.prodName);
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter title!';
                  }
                  return null;
                },
                onSaved: (value) {
                  motorFormSqlDb.prodName = value;
                },
                onTap: () {
                  // textFocusVin.unfocus();
                  textFocusYear.unfocus();
                  textFocusMake.unfocus();
                  textFocusModel.unfocus();
                  textFocusPrice.unfocus();
                  textFocusStock.unfocus();
                  textFocusDes.unfocus();
                  textFocusSell.unfocus();
                },
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),
        if (motorFormSqlDb.catName.trim() == 'Vehicle' ||
            motorFormSqlDb.catName.trim() == 'Electronics' ||
            motorFormSqlDb.catName.trim() == 'Home Appliances')
          Column(
            children: [
              // Make
              if (_makes != null)
                Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Make',
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    (motorFormSqlDb.make != null)
                        ? (_makes.any((e) =>
                                    e.value.trim().toLowerCase() ==
                                    motorFormSqlDb.make.trim().toLowerCase()) &&
                                motorFormSqlDb.make.trim().toLowerCase() !=
                                    'others')
                            ? Container(
                                color: bScaffoldBackgroundColor,
                                child: DropdownButtonFormField<String>(
                                  items: _makes,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) async {
                                    setState(() {
                                      motorFormSqlDb.make = value;
                                    });
                                    await _updateMotorForm(motorFormSqlDb.id,
                                        'make', motorFormSqlDb.make);
                                  },
                                  onSaved: (value) {
                                    motorFormSqlDb.make = value;
                                  },
                                  onTap: () {
                                    _unFocusAll();
                                  },
                                  validator: (value) {
                                    if (value == 'Unspecified') {
                                      return 'Please select Make!';
                                    }
                                    return null;
                                  },
                                  value: motorFormSqlDb.make != null
                                      ? motorFormSqlDb.make
                                      : _initialSelectedItem,
                                ),
                              )
                            // Container(
                            //     color: bScaffoldBackgroundColor,
                            //     child: SearchableDropdown.single(
                            //       closeButton: "Clear",
                            //       items: _makes,

                            //       // value: motorFormSqlDb.make,
                            //       //     ? motorFormSqlDb.make
                            //       //     : _initialSelectedItem,
                            //       hint: "Select Make",
                            //       searchHint: "Select Make",

                            //       onChanged: (value) async {
                            //         setState(() {
                            //           motorFormSqlDb.make = value;
                            //         });
                            //         print("value 020----- $value");
                            //         await _updateMotorForm(motorFormSqlDb.id,
                            //             'make', motorFormSqlDb.make);
                            //       },
                            //       validator: (value) {
                            //         if (value == 'Unspecified') {
                            //           print('Make Unspecified');
                            //           _searchableValidateMM = false;

                            //           return 'Please select make!';
                            //         }

                            //         _searchableValidateMM = true;
                            //         return null;
                            //       },
                            //       isExpanded: true,
                            //     ),
                            //   )
                            : Container(
                                color: bScaffoldBackgroundColor,
                                height: MediaQuery.of(context).size.height / 15,
                                child: TextFormField(
                                  key: ValueKey('make'),

                                  // onEditingComplete: () => focusNode.unfocus(),
                                  focusNode: textFocusMake,
                                  autofocus: true,
                                  initialValue: motorFormSqlDb.make
                                              .toLowerCase()
                                              .trim() ==
                                          "others"
                                      ? ""
                                      : motorFormSqlDb.make,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) async {
                                    _searchableValidateMM = true;

                                    setState(() {
                                      motorFormSqlDb.make = value;
                                    });
                                    await _updateMotorForm(motorFormSqlDb.id,
                                        'make', motorFormSqlDb.make);
                                  },
                                  validator: (value) {
                                    if (value.isEmpty ||
                                        value.trim().toLowerCase() ==
                                            'others') {
                                      return 'Please enter make!';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    motorFormSqlDb.make = value;
                                  },
                                  onTap: () {
                                    // textFocusVin.unfocus();
                                    textFocusYear.unfocus();
                                    textFocusTitle.unfocus();
                                    textFocusModel.unfocus();
                                    textFocusPrice.unfocus();
                                    textFocusStock.unfocus();
                                    textFocusDes.unfocus();
                                    textFocusSell.unfocus();
                                  },
                                ),
                              )
                        : Container(
                            color: bScaffoldBackgroundColor,
                            child: DropdownButtonFormField<String>(
                              items: _makes,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) async {
                                setState(() {
                                  motorFormSqlDb.make = value;
                                });
                                await _updateMotorForm(motorFormSqlDb.id,
                                    'make', motorFormSqlDb.make);
                              },
                              onSaved: (value) {
                                motorFormSqlDb.make = value;
                              },
                              onTap: () {
                                _unFocusAll();
                              },
                              validator: (value) {
                                if (value == 'Unspecified') {
                                  return 'Please select Make!';
                                }
                                return null;
                              },
                              value: motorFormSqlDb.make != null
                                  ? motorFormSqlDb.make
                                  : _initialSelectedItem,
                            ),
                          ),
                    // Container(
                    //   color: bScaffoldBackgroundColor,
                    //   child: SearchableDropdown.single(
                    //     items: _makes,
                    //     value: motorFormSqlDb.make != null
                    //         ? motorFormSqlDb.make
                    //         : _initialSelectedItem,
                    //     hint: "Select Make",
                    //     searchHint: "Select Make",
                    //     onChanged: (value) async {
                    //       setState(() {
                    //         motorFormSqlDb.make = value;
                    //       });
                    //       await _updateMotorForm(
                    //           motorFormSqlDb.id, 'make', motorFormSqlDb.make);
                    //     },
                    //     validator: (value) {
                    //       if (value == 'Unspecified') {
                    //         _searchableValidate = false;
                    //         return 'Please select make!';
                    //       }
                    //       _searchableValidate = true;
                    //       return null;
                    //     },
                    //     isExpanded: true,
                    //   ),
                    // ),
                  ],
                ),
              const SizedBox(
                height: 10,
              ),

              if (_models != null)
                Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Model',
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    (motorFormSqlDb.model != null)
                        ? (_models.any((e) =>
                                    e.value.trim().toLowerCase() ==
                                    motorFormSqlDb.model
                                        .trim()
                                        .toLowerCase()) &&
                                motorFormSqlDb.model.trim().toLowerCase() !=
                                    'others')
                            ? Container(
                                color: bScaffoldBackgroundColor,
                                child: DropdownButtonFormField<String>(
                                  items: _models,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) async {
                                    setState(() {
                                      motorFormSqlDb.model = value;
                                    });
                                    await _updateMotorForm(motorFormSqlDb.id,
                                        'model', motorFormSqlDb.model);
                                  },
                                  onSaved: (value) {
                                    motorFormSqlDb.model = value;
                                  },
                                  onTap: () {
                                    _unFocusAll();
                                  },
                                  validator: (value) {
                                    if (value == 'Unspecified') {
                                      return 'Please select Model!';
                                    }
                                    return null;
                                  },
                                  value: motorFormSqlDb.model != null
                                      ? motorFormSqlDb.model
                                      : _initialSelectedItem,
                                ),
                              )
                            : Container(
                                color: bScaffoldBackgroundColor,
                                height: MediaQuery.of(context).size.height / 15,
                                child: TextFormField(
                                  key: ValueKey('model'),
                                  focusNode: textFocusModel,
                                  autofocus: true,
                                  // onEditingComplete: () => focusNode.unfocus(),
                                  initialValue: motorFormSqlDb.model
                                              .toLowerCase()
                                              .trim() ==
                                          "others"
                                      ? ""
                                      : motorFormSqlDb.model,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) async {
                                    _searchableValidateMM = true;

                                    setState(() {
                                      motorFormSqlDb.model = value;
                                    });
                                    await _updateMotorForm(motorFormSqlDb.id,
                                        'model', motorFormSqlDb.model);
                                  },
                                  validator: (value) {
                                    if (value.isEmpty ||
                                        value.trim().toLowerCase() ==
                                            'others') {
                                      return 'Please enter model!';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    motorFormSqlDb.model = value;
                                  },
                                  onTap: () {
                                    // textFocusVin.unfocus();
                                    textFocusYear.unfocus();
                                    textFocusTitle.unfocus();
                                    textFocusMake.unfocus();
                                    textFocusPrice.unfocus();
                                    textFocusStock.unfocus();
                                    textFocusDes.unfocus();
                                    textFocusSell.unfocus();
                                  },
                                ),
                              )
                        : Container(
                            color: bScaffoldBackgroundColor,
                            child: DropdownButtonFormField<String>(
                              items: _models,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) async {
                                setState(() {
                                  motorFormSqlDb.model = value;
                                });
                                await _updateMotorForm(motorFormSqlDb.id,
                                    'model', motorFormSqlDb.model);
                              },
                              onSaved: (value) {
                                motorFormSqlDb.model = value;
                              },
                              onTap: () {
                                _unFocusAll();
                              },
                              validator: (value) {
                                if (value == 'Unspecified') {
                                  return 'Please select Model!';
                                }
                                return null;
                              },
                              value: motorFormSqlDb.model != null
                                  ? motorFormSqlDb.model
                                  : _initialSelectedItem,
                            ),
                          ),
                    // Container(
                    //   color: bScaffoldBackgroundColor,
                    //   child: SearchableDropdown.single(
                    //     items: _models,
                    //     value: motorFormSqlDb.model != null
                    //         ? motorFormSqlDb.model
                    //         : _initialSelectedItem,
                    //     hint: "Select Model",
                    //     searchHint: "Select Model",
                    //     onChanged: (value) async {
                    //       setState(() {
                    //         motorFormSqlDb.model = value;
                    //       });
                    //       await _updateMotorForm(
                    //           motorFormSqlDb.id, 'model', motorFormSqlDb.model);
                    //     },
                    //     validator: (value) {
                    //       if (value == 'Unspecified') {
                    //         _searchableValidate = false;
                    //         return 'Please select model!';
                    //       }
                    //       _searchableValidate = true;
                    //       return null;
                    //     },
                    //     isExpanded: true,
                    //   ),
                    // ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
            ],
          ),

        // Product Condition
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Product Condition',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              child: DropdownButtonFormField<String>(
                items: _prodConditions,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.prodCondition = value;
                  });
                  await _updateMotorForm(motorFormSqlDb.id, 'prodCondition',
                      motorFormSqlDb.prodCondition);
                },
                onSaved: (value) {
                  motorFormSqlDb.prodCondition = value;
                },
                onTap: () {
                  _unFocusAll();
                },
                validator: (value) {
                  if (value == 'Unspecified') {
                    return 'Please select prod condition!';
                  }
                  return null;
                },
                value: motorFormSqlDb.prodCondition != null
                    ? motorFormSqlDb.prodCondition
                    : _initialValueProductCond,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Price $_currencySymbol',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              height: MediaQuery.of(context).size.height / 15,
              child: TextFormField(
                key: ValueKey('price'),
                // onEditingComplete: () => focusNode.nextFocus(),
                focusNode: textFocusPrice,
                initialValue: motorFormSqlDb.price,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.price = value;
                  });
                  await _updateMotorForm(
                      motorFormSqlDb.id, 'price', motorFormSqlDb.price);
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter price';
                  }
                  return null;
                },
                onSaved: (value) {
                  motorFormSqlDb.price = value;
                },
                onTap: () {
                  // textFocusVin.unfocus();
                  textFocusYear.unfocus();
                  textFocusTitle.unfocus();
                  textFocusMake.unfocus();
                  textFocusModel.unfocus();
                  textFocusStock.unfocus();
                  textFocusDes.unfocus();
                  textFocusSell.unfocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Stock In Hand',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              height: MediaQuery.of(context).size.height / 15,
              child: TextFormField(
                key: ValueKey('stockInHand'),
                // onEditingComplete: () => focusNode.nextFocus(),
                focusNode: textFocusStock,
                initialValue: motorFormSqlDb.stockInHand.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.stockInHand = value;
                  });
                  await _updateMotorForm(motorFormSqlDb.id, 'stockInHand',
                      motorFormSqlDb.stockInHand);
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter stockInHand';
                  }
                  return null;
                },
                onSaved: (value) {
                  motorFormSqlDb.stockInHand = value;
                },
                onTap: () {
                  // textFocusVin.unfocus();
                  textFocusYear.unfocus();
                  textFocusTitle.unfocus();
                  textFocusMake.unfocus();
                  textFocusModel.unfocus();
                  textFocusPrice.unfocus();
                  textFocusDes.unfocus();
                  textFocusSell.unfocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Description',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              child: TextFormField(
                maxLines: 5,
                key: ValueKey('prodDes'),
                focusNode: textFocusDes,
                // onEditingComplete: () => focusNode.nextFocus(),
                initialValue: motorFormSqlDb.prodDes,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.prodDes = value;
                  });
                  await _updateMotorForm(
                      motorFormSqlDb.id, 'prodDes', motorFormSqlDb.prodDes);
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter product description!';
                  }
                  return null;
                },
                onSaved: (value) {
                  motorFormSqlDb.prodDes = value;
                },

                onTap: () {
                  // textFocusVin.unfocus();
                  textFocusYear.unfocus();
                  textFocusTitle.unfocus();
                  textFocusMake.unfocus();
                  textFocusModel.unfocus();
                  textFocusPrice.unfocus();
                  textFocusStock.unfocus();
                  textFocusSell.unfocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Seller Notes (Optional)',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              child: TextFormField(
                maxLines: 5,
                key: ValueKey('sellerNotes'),
                focusNode: textFocusSell,

                // onEditingComplete: () => focusNode.nextFocus(),
                initialValue: motorFormSqlDb.sellerNotes,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.sellerNotes = value;
                  });
                  await _updateMotorForm(motorFormSqlDb.id, 'sellerNotes',
                      motorFormSqlDb.sellerNotes);
                },
                // validator: (value) {
                //   if (value.isEmpty) {
                //     return 'Please enter seller notes!';
                //   }
                //   return null;
                // },
                onSaved: (value) {
                  motorFormSqlDb.sellerNotes = value;
                },
                onTap: () {
                  // textFocusVin.unfocus();
                  textFocusYear.unfocus();
                  textFocusTitle.unfocus();
                  textFocusMake.unfocus();
                  textFocusModel.unfocus();
                  textFocusPrice.unfocus();
                  textFocusStock.unfocus();
                  textFocusDes.unfocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Delivery Info',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              child: DropdownButtonFormField<String>(
                items: _deliveryInfo,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.deliveryInfo = value;
                  });
                  await _updateMotorForm(motorFormSqlDb.id, 'deliveryInfo',
                      motorFormSqlDb.deliveryInfo);
                },
                onSaved: (value) {
                  motorFormSqlDb.deliveryInfo = value;
                },
                onTap: () {
                  _unFocusAll();
                },
                validator: (value) {
                  if (value == 'Unspecified') {
                    return 'Please select Delivery Info!';
                  }
                  return null;
                },
                value: motorFormSqlDb.deliveryInfo != null
                    ? motorFormSqlDb.deliveryInfo
                    : _initialValueDeliveryInfo,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Type of Ad',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              child: DropdownButtonFormField<String>(
                items: _typeOfAd,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.typeOfAd = value;
                  });
                  await _updateMotorForm(
                      motorFormSqlDb.id, 'typeOfAd', motorFormSqlDb.typeOfAd);
                },
                onSaved: (value) {
                  motorFormSqlDb.typeOfAd = value;
                },
                onTap: () {
                  _unFocusAll();
                },
                validator: (value) {
                  if (value == 'Unspecified') {
                    return 'Please select Type of Ad!';
                  }
                  return null;
                },
                value: motorFormSqlDb.typeOfAd != null
                    ? motorFormSqlDb.typeOfAd
                    : _initialValueTypeOfAd,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Posted By',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              color: bScaffoldBackgroundColor,
              child: DropdownButtonFormField<String>(
                items: _forSaleBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) async {
                  setState(() {
                    motorFormSqlDb.forSaleBy = value;
                  });
                  await _updateMotorForm(
                      motorFormSqlDb.id, 'forSaleBy', motorFormSqlDb.forSaleBy);
                },
                onSaved: (value) {
                  motorFormSqlDb.forSaleBy = value;
                },
                onTap: () {
                  _unFocusAll();
                },
                validator: (value) {
                  print(
                      "motorFormSqlDb.forSaleBy 11 - ${motorFormSqlDb.forSaleBy}");
                  if (value == 'Unspecified') {
                    return 'Please select ForSaleBy!';
                  }
                  return null;
                },
                value: motorFormSqlDb.forSaleBy != null
                    ? motorFormSqlDb.forSaleBy
                    : _initialValuePostedBy,
              ),
            ),
          ],
        )
      ],
    );
  }

  //Steps Functions

  tapped(int step) {
    setState(() => _currentStep = step);
  }

  // continued() {
  //   _currentStep < 3 ? setState(() => _currentStep += 1) : null;
  // }

  cancel() {
    _currentStep > 0 ? setState(() => _currentStep -= 1) : null;
  }

  Future _pickImage(String sourceType) async {
    try {
      final picker = ImagePicker();
      final imageFile = await picker.getImage(
        source: sourceType == 'G' ? ImageSource.gallery : ImageSource.camera,
        // imageQuality: 50,
        // maxWidth: 150,
      );
      if (imageFile == null) {
        return null;
      }

      setState(() {
        pickedImage = File(imageFile.path);
      });

      // if (pickedImage != null) {
      //   File croppedFile = await ImageCropper.cropImage(
      //       maxHeight: 600,
      //       maxWidth: 600,
      //       sourcePath: imageFile.path,
      //       aspectRatioPresets: Platform.isAndroid
      //           ? [
      //               CropAspectRatioPreset.square,
      //               CropAspectRatioPreset.ratio3x2,
      //               CropAspectRatioPreset.original,
      //               CropAspectRatioPreset.ratio4x3,
      //               CropAspectRatioPreset.ratio16x9
      //             ]
      //           : [
      //               CropAspectRatioPreset.original,
      //               CropAspectRatioPreset.square,
      //               CropAspectRatioPreset.ratio3x2,
      //               CropAspectRatioPreset.ratio4x3,
      //               CropAspectRatioPreset.ratio5x3,
      //               CropAspectRatioPreset.ratio5x4,
      //               CropAspectRatioPreset.ratio7x5,
      //               CropAspectRatioPreset.ratio16x9
      //             ],
      //       androidUiSettings: AndroidUiSettings(
      //           toolbarTitle: 'Cropper',
      //           toolbarColor: bPrimaryColor,
      //           toolbarWidgetColor: bBackgroundColor,
      //           initAspectRatio: CropAspectRatioPreset.original,
      //           lockAspectRatio: false),
      //       iosUiSettings: IOSUiSettings(
      //         title: 'Cropper',
      //       ));
      //   if (croppedFile != null) {
      //     setState(() {
      //       pickedImage = croppedFile;
      //     });
      //   }
      // }

      if (pickedImage != null) {
        await runModelOnImage();
      }
    } on PlatformException catch (e) {
      print('Image picker PlatformException error - ${e.code}');
      if (e.code.trim() == "photo_access_denied" ||
          e.code.trim() == "camera_access_denied") {
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
                onPressed: () => openAppSettings(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Image picker error - $e');
    }
  }

  Future runModelOnImage() async {
    var output = await Tflite.runModelOnImage(
      path: pickedImage.path,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 2,
      threshold: 0.8,
    );

    if (output.length > 0) {
      setState(() {
        imageLabel = output[0]["label"];

        motorFormSqlDb.catName = imageLabel.split(",")[0];

        motorFormSqlDb.subCatType = imageLabel.split(",")[1];
        motorFormSqlDb.make = imageLabel.split(",")[2] == "NA"
            ? "Unspecified"
            : imageLabel.split(",")[2];
        motorFormSqlDb.model = imageLabel.split(",")[3] == "NA"
            ? "Unspecified"
            : imageLabel.split(",")[3];
        imageType = imageLabel.split(",")[4];
      });
    } else {
      imageLabel = 'Unspecified';
      motorFormSqlDb.catName = "Unspecified";
      motorFormSqlDb.subCatType = "Unspecified";
      motorFormSqlDb.make = "Unspecified";
      motorFormSqlDb.model = "Unspecified";
      imageType = 'E';
    }
    if (imageLabel.isNotEmpty) {
      await loadImage();
    }
  }

  loadImage() async {
    ProdImagesSqlDb prodImageSqlDb = ProdImagesSqlDb();

    if (_featuredImage == false) {
      _featuredImage = true;
      prodImageSqlDb.featuredImage = 'true';
    } else {
      prodImageSqlDb.featuredImage = 'false';
    }

    if (motorFormSqlDb.catName != 'Vehicle') {
      imageType = 'E';
    }

    prodImageSqlDb.imageType = imageType.substring(0, 1).toUpperCase();

    prodImageSqlDb.imageUrl = pickedImage.path;

    _saveImage(prodImageSqlDb).then((value) {
      _showDialogImages();
    });
  }

  void _showDialogImages() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Organizing your images"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Center(
                  child: Text('$_eImageCount Exterior'),
                ),
                Center(
                  child: Text('$_iImageCount Interiors'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Center(
                child: const Text('View Images'),
              ),
              onPressed: () async {
                await _initialLoadMotorForm();
                if (_motorFormCount == 0) {
                  // Initial vehicle Type Year
                  _specialVehicle = false;
                  if (motorFormSqlDb.subCatType == 'Cars' ||
                      motorFormSqlDb.subCatType == 'Trucks' ||
                      motorFormSqlDb.subCatType == 'Caravans') {
                    _specialVehicle = true;
                    motorFormSqlDb.vehicleTypeYear = "CTA1981";
                  }

                  print('edit post _specialVehicle - $_specialVehicle');

                  // motorFormSqlDb.editPost = 'false';
                  await _saveMotorForm(motorFormSqlDb);
                  print('edit post _specialVehicle 1 - $_specialVehicle');
                }
                setState(() {
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Future _validateVIN(String inVIN) async {
  //   var vin = VINC(number: inVIN, extended: true);

  //   var year = vin.getYear().toString();
  //   if (year != null) {
  //     print('VIN Year - $year');
  //     setState(() {
  //       motorFormSqlDb.year = year;
  //     });

  //     await _updateMotorForm(motorFormSqlDb.id, 'year', motorFormSqlDb.year);
  //   }

  //   // The following calls are to the NHTSA DB, and are carried out asynchronously
  //   var make = await vin.getMakeAsync();

  //   if (make != null) {
  //     print('VIN make - $make');
  //     setState(() {
  //       motorFormSqlDb.make = make;
  //     });
  //     await _updateMotorForm(motorFormSqlDb.id, 'make', motorFormSqlDb.make);
  //   }

  //   var model = await vin.getModelAsync();
  //   print('VIN model - $model');
  //   if (model != null) {
  //     setState(() {
  //       motorFormSqlDb.model = model;
  //     });
  //     await _updateMotorForm(motorFormSqlDb.id, 'model', motorFormSqlDb.model);
  //   }

  //   var vehicleType = await vin.getVehicleTypeAsync();

  //   if (vehicleType != null) {
  //     print('VIN vehicleType - $vehicleType');
  //     setState(() {
  //       motorFormSqlDb.vehicleType = vehicleType;
  //     });
  //     await _updateMotorForm(
  //         motorFormSqlDb.id, 'vehicleType', motorFormSqlDb.vehicleType);
  //   }

  //   var numberOfCylinders = await vin.getEngineNumberofCylindersAsync();

  //   if (numberOfCylinders != null) {
  //     print('VIN numberOfCylinders - $numberOfCylinders');
  //     setState(() {
  //       motorFormSqlDb.numberOfCylinders = numberOfCylinders;
  //     });
  //     await _updateMotorForm(motorFormSqlDb.id, 'numberOfCylinders',
  //         motorFormSqlDb.numberOfCylinders);
  //   }

  //   var safetyFeatures = await vin.getActiveSafetySystemNoteAsync();

  //   if (safetyFeatures != null) {
  //     print('VIN safetyFeatures - $safetyFeatures');
  //     setState(() {
  //       motorFormSqlDb.safetyFeatures = safetyFeatures;
  //     });
  //     await _updateMotorForm(
  //         motorFormSqlDb.id, 'safetyFeatures', motorFormSqlDb.safetyFeatures);
  //   }

  //   var transmission = await vin.getTransmissionStyleAsync();

  //   if (transmission != null) {
  //     print('VIN transmission - $transmission');
  //     setState(() {
  //       motorFormSqlDb.transmission = transmission;
  //     });
  //     await _updateMotorForm(
  //         motorFormSqlDb.id, 'transmission', motorFormSqlDb.transmission);
  //   }

  //   var steeringLocation = await vin.getSteeringLocationAsync();

  //   if (steeringLocation != null) {
  //     print('VIN steeringLocation - $steeringLocation');
  //     setState(() {
  //       motorFormSqlDb.steeringLocation = steeringLocation;
  //     });
  //     await _updateMotorForm(motorFormSqlDb.id, 'steeringLocation',
  //         motorFormSqlDb.steeringLocation);
  //   }

  //   var fuelType = await vin.getFuelTypePrimaryAsync();

  //   if (fuelType != null) {
  //     print('VIN fuelType - $fuelType');
  //     setState(() {
  //       motorFormSqlDb.fuelType = fuelType;
  //     });
  //     await _updateMotorForm(
  //         motorFormSqlDb.id, 'fuelType', motorFormSqlDb.fuelType);
  //   }

  //   var trim = await vin.getTrimAsync();

  //   if (trim != null) {
  //     print('VIN trim - $trim');
  //     setState(() {
  //       motorFormSqlDb.trim = trim;
  //     });
  //     await _updateMotorForm(motorFormSqlDb.id, 'trim', motorFormSqlDb.trim);
  //   }

  //   var driveType = await vin.getDriveTypeAsync();

  //   if (driveType != null) {
  //     print('VIN driveType - $driveType');
  //     setState(() {
  //       motorFormSqlDb.driveType = driveType;
  //     });
  //     await _updateMotorForm(
  //         motorFormSqlDb.id, 'driveType', motorFormSqlDb.driveType);
  //   }

  //   var bodyType = await vin.getBodyTypeAsync();

  //   if (bodyType != null) {
  //     print('VIN bodyType - $bodyType');
  //     setState(() {
  //       motorFormSqlDb.bodyType = bodyType;
  //     });
  //     await _updateMotorForm(
  //         motorFormSqlDb.id, 'bodyType', motorFormSqlDb.bodyType);
  //   }

  //   var displacementL = await vin.getDisplacementLAsync();

  //   if (displacementL != null) {
  //     print('VIN displacementL - $displacementL');
  //     String disp = double.parse(displacementL).toStringAsFixed(1);
  //     if (disp != null && fuelType != null) {
  //       var engine = ("$disp L $fuelType").toString();

  //       if (engine != null) {
  //         print('VIN engine - $engine');
  //         setState(() {
  //           motorFormSqlDb.engine = engine;
  //         });
  //         await _updateMotorForm(
  //             motorFormSqlDb.id, 'engine', motorFormSqlDb.engine);
  //       }
  //     }
  //   }

  //   // var generated = VINGenerator().generate();
  //   // print('Randomly Generated VIN is $generated');
  // }

  void _removeImage(List<ProdImagesSqlDb> prodImagesSqlDbData, int index) {
    // listOfRemovedImg will contain all images which are already in firebase storage, that has to be removed
    if (prodImagesSqlDbData[index].imageUrl.substring(0, 5) == 'https') {
      listOfRemovedImg.add(prodImagesSqlDbData[index]);
    }
    prodImagesSqlDbData.removeAt(index);
  }

  Future<String> _postAds() async {
    prodImagesSqlDb = prodImagesSqlDbE + prodImagesSqlDbI;

    if (motorFormSqlDb.catName.trim() != 'Vehicle' &&
        motorFormSqlDb.catName.trim() != 'Electronics' &&
        motorFormSqlDb.catName.trim() != 'Home Appliances') {
      motorFormSqlDb.make = "Others";
      motorFormSqlDb.model = "Others";
    }

    if (motorFormSqlDb.catName.trim() == 'Vehicle' &&
        !motorFormSqlDb.subCatType.contains('Accessories') &&
        !motorFormSqlDb.subCatType.contains('Others')) {
      await FirebaseFirestore.instance.collection('products').add({
        'prodName': motorFormSqlDb.prodName,
        'catName': motorFormSqlDb.catName,
        'subCatType': motorFormSqlDb.subCatType,
        'prodDes': motorFormSqlDb.prodDes,
        'sellerNotes': motorFormSqlDb.sellerNotes,
        'year': motorFormSqlDb.year,
        'make': motorFormSqlDb.make,
        'model': motorFormSqlDb.model,
        'prodCondition': motorFormSqlDb.prodCondition,
        'price': motorFormSqlDb.price,
        'stockInHand': motorFormSqlDb.stockInHand,
        'currencyName': _currencyName,
        'currencySymbol': _currencySymbol,
        'imageUrlFeatured': motorFormSqlDb.imageUrlFeatured,
        'addressLocation': _addressLocation,
        'countryCode': _countryCode,
        'latitude': _latitude,
        'longitude': _longitude,
        'userDetailDocId': _userDetailDocId,
        'deliveryInfo': motorFormSqlDb.deliveryInfo,
        'typeOfAd': motorFormSqlDb.typeOfAd,
        'distance': '',
        'status': 'Pending',
        'forSaleBy': motorFormSqlDb.forSaleBy,
        'listingStatus': 'Available',
        'createdAt': Timestamp.now(),
        'subscription': 'Free',
      }).then((p) async {
        await FirebaseFirestore.instance.collection('CtmSpecialInfo').add({
          'prodDocId': p.id.toString(),
          'year': motorFormSqlDb.year,
          'make': motorFormSqlDb.make,
          'model': motorFormSqlDb.model,
          'vehicleType': motorFormSqlDb.vehicleType,
          'mileage': motorFormSqlDb.mileage,
          'vin': motorFormSqlDb.vin,
          'engine': motorFormSqlDb.engine,
          'fuelType': motorFormSqlDb.fuelType,
          'options': motorFormSqlDb.options,
          'subModel': motorFormSqlDb.subModel,
          'numberOfCylinders': motorFormSqlDb.numberOfCylinders,
          'safetyFeatures': motorFormSqlDb.safetyFeatures,
          'driveType': motorFormSqlDb.driveType,
          'interiorColor': motorFormSqlDb.interiorColor,
          'bodyType': motorFormSqlDb.bodyType,
          'forSaleBy': motorFormSqlDb.forSaleBy,
          'warranty': motorFormSqlDb.warranty,
          'exteriorColor': motorFormSqlDb.exteriorColor,
          'trim': motorFormSqlDb.trim,
          'transmission': motorFormSqlDb.transmission,
          'steeringLocation': motorFormSqlDb.steeringLocation,
        }).then(
          (ctm) async {
            _prodDocId = p.id;

            if (_prodDocId.isNotEmpty) {
              for (var i = 0; i < prodImagesSqlDb.length; i++) {
                if (prodImagesSqlDb[i].imageUrl.substring(0, 5) != 'https') {
                  final fileNameExt =
                      prodImagesSqlDb[i].imageUrl.split('/').last;
                  final fileName = fileNameExt.split('.').first;

                  final ref = FirebaseStorage.instance
                      .ref()
                      .child('product_images/${user.uid}')
                      // 'product_images/$_prodDocId')
                      .child(motorFormSqlDb.make +
                          motorFormSqlDb.model +
                          fileName +
                          '.jpg');

                  await ref.putFile(File(prodImagesSqlDb[i].imageUrl));

                  _imageUrl = await ref.getDownloadURL();

                  prodImagesSqlDb[i].imageUrl = _imageUrl;
                }
              }

              print('All images are loaded into storage');
              _addMake();
              _addModel();
              if (prodImagesSqlDb.length > 0) {
                if (prodImagesSqlDb.any((e) => e.featuredImage == "true")) {
                } else {
                  prodImagesSqlDb[0].featuredImage = "true";
                }
              }
              _featuredImage = false;
              for (var i = 0; i < prodImagesSqlDb.length; i++) {
                if (prodImagesSqlDb[i].featuredImage == 'true') {
                  if (!_featuredImage) {
                    _featuredImage = true;
                  } else {
                    prodImagesSqlDb[i].featuredImage = 'false';
                  }
                }

                await FirebaseFirestore.instance.collection('ProdImages').add({
                  'prodDocId': _prodDocId,
                  'imageType': prodImagesSqlDb[i].imageType,
                  'imageUrl': prodImagesSqlDb[i].imageUrl,
                  'featuredImage':
                      prodImagesSqlDb[i].featuredImage == 'true' ? true : false,
                }).then(
                  (value) async {
                    if (prodImagesSqlDb[i].featuredImage == 'true' &&
                        prodImagesSqlDb[i].imageUrl.isNotEmpty) {
                      motorFormSqlDb.imageUrlFeatured =
                          prodImagesSqlDb[i].imageUrl;
                      _prodUpdated = 'Uncompleted';

                      await _updateProdFeaturedImage(
                              _prodDocId, motorFormSqlDb.imageUrlFeatured)
                          .then(
                        (value) {
                          _prodUpdated = value;
                        },
                      );
                    }
                  },
                );
              }
            }
          },
        ).catchError(
          (onError) {
            print('Unable to post your add please try again!!');
          },
        );
      });
      // return _prodUpdated;
    } else {
      await FirebaseFirestore.instance.collection('products').add({
        'prodName': motorFormSqlDb.prodName,
        'catName': motorFormSqlDb.catName,
        'subCatType': motorFormSqlDb.subCatType,
        'prodDes': motorFormSqlDb.prodDes,
        'sellerNotes': motorFormSqlDb.sellerNotes,
        'year': motorFormSqlDb.year,
        'make': motorFormSqlDb.make,
        'model': motorFormSqlDb.model,
        'prodCondition': motorFormSqlDb.prodCondition,
        'price': motorFormSqlDb.price,
        'stockInHand': motorFormSqlDb.stockInHand,
        'currencyName': _currencyName,
        'currencySymbol': _currencySymbol,
        'imageUrlFeatured': motorFormSqlDb.imageUrlFeatured,
        'addressLocation': _addressLocation,
        'countryCode': _countryCode,
        'latitude': _latitude,
        'longitude': _longitude,
        'userDetailDocId': _userDetailDocId,
        'deliveryInfo': motorFormSqlDb.deliveryInfo,
        'typeOfAd': motorFormSqlDb.typeOfAd,
        'distance': '',
        'status': 'Pending',
        'forSaleBy': motorFormSqlDb.forSaleBy,
        'listingStatus': 'Available',
        'createdAt': Timestamp.now(),
        'subscription': 'Free',
      }).then((p) async {
        _prodDocId = p.id;

        if (_prodDocId.isNotEmpty) {
          for (var i = 0; i < prodImagesSqlDb.length; i++) {
            if (prodImagesSqlDb[i].imageUrl.substring(0, 5) != 'https') {
              final fileNameExt = prodImagesSqlDb[i].imageUrl.split('/').last;
              final fileName = fileNameExt.split('.').first;

              final ref = FirebaseStorage.instance
                  .ref()
                  .child('product_images/${user.uid}')
                  // 'product_images/$_prodDocId')
                  .child(motorFormSqlDb.make +
                      motorFormSqlDb.model +
                      fileName +
                      '.jpg');

              await ref.putFile(File(prodImagesSqlDb[i].imageUrl));

              _imageUrl = await ref.getDownloadURL();

              prodImagesSqlDb[i].imageUrl = _imageUrl;
            }
          }

          print('All images are loaded into storage');
          _addMake();
          _addModel();

          if (prodImagesSqlDb.length > 0) {
            if (prodImagesSqlDb.any((e) => e.featuredImage == "true")) {
            } else {
              prodImagesSqlDb[0].featuredImage = "true";
            }
          }
          _featuredImage = false;
          for (var i = 0; i < prodImagesSqlDb.length; i++) {
            if (prodImagesSqlDb[i].featuredImage == 'true') {
              if (!_featuredImage) {
                _featuredImage = true;
              } else {
                prodImagesSqlDb[i].featuredImage = 'false';
              }
            }
            await FirebaseFirestore.instance.collection('ProdImages').add({
              'prodDocId': _prodDocId,
              'imageType': prodImagesSqlDb[i].imageType,
              'imageUrl': prodImagesSqlDb[i].imageUrl,
              'featuredImage':
                  prodImagesSqlDb[i].featuredImage == 'true' ? true : false,
            }).then((value) async {
              if (prodImagesSqlDb[i].featuredImage == 'true' &&
                  prodImagesSqlDb[i].imageUrl.isNotEmpty) {
                motorFormSqlDb.imageUrlFeatured = prodImagesSqlDb[i].imageUrl;
                _prodUpdated = 'Uncompleted';

                await _updateProdFeaturedImage(
                        _prodDocId, motorFormSqlDb.imageUrlFeatured)
                    .then(
                  (value) {
                    _prodUpdated = value;
                  },
                );
              }
            });
          }
        }
      }).catchError((onError) {
        print('Unable to post your add please try again!!');
      });
    }

    return _prodUpdated;
  }

  Future<void> _addUserSubDetails(String userId, String userCountryCode) async {
    subscriptionPlans = subscriptionPlans
        .where((e) => e.planName == "Free" && e.countryCode == _countryCode)
        .toList();
    if (subscriptionPlans.length > 0) {
      await FirebaseFirestore.instance
          .collection('userSubDetails')
          .doc(userId)
          .get()
          .then((DocumentSnapshot documentSnapshot) async {
        if (documentSnapshot.exists) {
          print(
              'Document userSubDetails exists on the database - ${documentSnapshot.data()["userId"]}');
        } else {
          print(
              'Document NOT userSubDetails exists on the database - Adding new UserSubDetails');
          await FirebaseFirestore.instance
              .collection('userSubDetails')
              .doc(userId)
              .set({
                'userId': userId,
                'renewedAt': Timestamp.now(),
                'postNoOfDays': 1,
                'planValidDays': subscriptionPlans[0].planValidDays,
                'paidStatus': 'Free',
                'planName': 'Free',
                'userCountryCode': userCountryCode,
              })
              .then((value) => print("userSubDetails added"))
              .catchError(
                  (error) => print("Failed to add userSubDetails: $error"));
        }
      });
    }
  }

  Future<void> _addMake() async {
    if (_makes.any((e) =>
        e.value.trim().toLowerCase() ==
        motorFormSqlDb.make.trim().toLowerCase())) {
      print("Make exist");
    } else {
      print("No Make exist");
      await FirebaseFirestore.instance.collection('makes').add({
        'make': motorFormSqlDb.make.toUpperCase(),
        'subCatType': motorFormSqlDb.subCatType,
      }).then((value) {
        print("Make Added");
      }).catchError((error) => print("Failed to add make: $error"));
    }
  }

  Future<void> _addModel() async {
    if (_models.any((e) =>
        e.value.trim().toLowerCase() ==
        motorFormSqlDb.model.trim().toLowerCase())) {
      print("Model exist");
    } else {
      print("No Model exist");
      await FirebaseFirestore.instance.collection('models').add({
        'make': motorFormSqlDb.make.toUpperCase(),
        'model': motorFormSqlDb.model.toUpperCase(),
        'subCatType': motorFormSqlDb.subCatType,
      }).then((value) {
        print("Model Added");
      }).catchError((error) => print("Failed to add model: $error"));
    }
  }

  Future<void> _deleteAndProcess() async {
    await _deleteImageAll();

    await _deleteMotorFormAll().then((value) async {
      if (_prodUpdated == 'Success') {
        setState(() {});
      }
    });
  }

  Future<void> _deleteRemovedImgInStorage() async {
    if (listOfRemovedImg.length > 0) {
      for (var i = 0; i < listOfRemovedImg.length; i++) {
        try {
          Reference ref =
              FirebaseStorage.instance.refFromURL(listOfRemovedImg[i].imageUrl);
          await ref.delete();
        } catch (e) {
          print('Failed with error code: ${e.code}');
          print(e.message);
        }
      }
    }
  }

  Future<String> _updateAds(
      String prodId, String category, String subCategory) async {
    prodImagesSqlDb = prodImagesSqlDbE + prodImagesSqlDbI;

    if (motorFormSqlDb.catName.trim() != 'Vehicle' &&
        motorFormSqlDb.catName.trim() != 'Electronics' &&
        motorFormSqlDb.catName.trim() != 'Home Appliances') {
      motorFormSqlDb.make = "Others";
      motorFormSqlDb.model = "Others";
    }
    WriteBatch batch = FirebaseFirestore.instance.batch();

    if (motorFormSqlDb.catName.trim() == 'Vehicle' &&
        !motorFormSqlDb.subCatType.contains('Accessories') &&
        !motorFormSqlDb.subCatType.contains('Others')) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(prodId)
          .update({
        'prodName': motorFormSqlDb.prodName,
        'catName': motorFormSqlDb.catName,
        'subCatType': motorFormSqlDb.subCatType,
        'prodDes': motorFormSqlDb.prodDes,
        'sellerNotes': motorFormSqlDb.sellerNotes,
        'year': motorFormSqlDb.year,
        'make': motorFormSqlDb.make,
        'model': motorFormSqlDb.model,
        'prodCondition': motorFormSqlDb.prodCondition,
        'price': motorFormSqlDb.price,
        'stockInHand': motorFormSqlDb.stockInHand,
        'currencyName': _currencyName,
        'currencySymbol': _currencySymbol,
        'imageUrlFeatured': motorFormSqlDb.imageUrlFeatured,
        'addressLocation': _addressLocation,
        'countryCode': _countryCode,
        'latitude': _latitude,
        'longitude': _longitude,
        'userDetailDocId': _userDetailDocId,
        'deliveryInfo': motorFormSqlDb.deliveryInfo,
        'typeOfAd': motorFormSqlDb.typeOfAd,
        'distance': '',
        'status': 'Pending',
        'forSaleBy': motorFormSqlDb.forSaleBy,
        'listingStatus': 'Available',
        'createdAt': Timestamp.now(),
        'subscription': 'Free',
      }).then((p) async {
        await FirebaseFirestore.instance
            .collection('CtmSpecialInfo')
            .where('prodDocId', isEqualTo: prodId)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((document) {
            batch.update(document.reference, {
              'year': motorFormSqlDb.year,
              'make': motorFormSqlDb.make,
              'model': motorFormSqlDb.model,
              'vehicleType': motorFormSqlDb.vehicleType,
              'mileage': motorFormSqlDb.mileage,
              'vin': motorFormSqlDb.vin,
              'engine': motorFormSqlDb.engine,
              'fuelType': motorFormSqlDb.fuelType,
              'options': motorFormSqlDb.options,
              'subModel': motorFormSqlDb.subModel,
              'numberOfCylinders': motorFormSqlDb.numberOfCylinders,
              'safetyFeatures': motorFormSqlDb.safetyFeatures,
              'driveType': motorFormSqlDb.driveType,
              'interiorColor': motorFormSqlDb.interiorColor,
              'bodyType': motorFormSqlDb.bodyType,
              'forSaleBy': motorFormSqlDb.forSaleBy,
              'warranty': motorFormSqlDb.warranty,
              'exteriorColor': motorFormSqlDb.exteriorColor,
              'trim': motorFormSqlDb.trim,
              'transmission': motorFormSqlDb.transmission,
              'steeringLocation': motorFormSqlDb.steeringLocation,
            });
          });
          return batch.commit().then(
            (value) async {
              // _prodDocId = prodId;

              if (prodId.isNotEmpty) {
                for (var i = 0; i < prodImagesSqlDb.length; i++) {
                  if (prodImagesSqlDb[i].imageUrl.substring(0, 5) != 'https') {
                    final fileNameExt =
                        prodImagesSqlDb[i].imageUrl.split('/').last;
                    final fileName = fileNameExt.split('.').first;

                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('product_images/${user.uid}')
                        // 'product_images/$prodId')
                        .child(motorFormSqlDb.make +
                            motorFormSqlDb.model +
                            fileName +
                            '.jpg');

                    await ref.putFile(File(prodImagesSqlDb[i].imageUrl));

                    _imageUrl = await ref.getDownloadURL();

                    prodImagesSqlDb[i].imageUrl = _imageUrl;
                  }
                }

                print('All images are loaded into storage');
                _addMake();
                _addModel();
                if (prodImagesSqlDb.length > 0) {
                  if (prodImagesSqlDb.any((e) => e.featuredImage == "true")) {
                  } else {
                    prodImagesSqlDb[0].featuredImage = "true";
                  }
                }

                // Product Image delete

                batch = FirebaseFirestore.instance.batch();

                await FirebaseFirestore.instance
                    .collection('ProdImages')
                    .where('prodDocId', isEqualTo: prodId)
                    .get()
                    .then((querySnapshot) {
                  querySnapshot.docs.forEach((document) {
                    batch.delete(document.reference);
                  });

                  return batch.commit().catchError((error) =>
                      print("Failed to delete products in ProdImages: $error"));
                });

                //
                _featuredImage = false;
                for (var i = 0; i < prodImagesSqlDb.length; i++) {
                  if (prodImagesSqlDb[i].featuredImage == 'true') {
                    if (!_featuredImage) {
                      _featuredImage = true;
                    } else {
                      prodImagesSqlDb[i].featuredImage = 'false';
                    }
                  }
                  await FirebaseFirestore.instance
                      .collection('ProdImages')
                      .add({
                    'prodDocId': prodId,
                    'imageType': prodImagesSqlDb[i].imageType,
                    'imageUrl': prodImagesSqlDb[i].imageUrl,
                    'featuredImage': prodImagesSqlDb[i].featuredImage == 'true'
                        ? true
                        : false,
                  }).then(
                    (value) async {
                      if (prodImagesSqlDb[i].featuredImage == 'true' &&
                          prodImagesSqlDb[i].imageUrl.isNotEmpty) {
                        motorFormSqlDb.imageUrlFeatured =
                            prodImagesSqlDb[i].imageUrl;
                        _prodUpdated = 'Uncompleted';

                        await _updateProdFeaturedImage(
                                prodId, motorFormSqlDb.imageUrlFeatured)
                            .then(
                          (value) {
                            _prodUpdated = value;
                          },
                        );
                      }
                    },
                  );
                }
              }
            },
          ).catchError((error) =>
              print("Failed to update data in CtmSpecialInfo batch: $error"));
        }).catchError((error) => print(
                "Failed to get data in CtmSpecialInfo for update: $error"));
      }).catchError((onError) {
        print('Unable to update your add please try again!!');
      });

      // return _prodUpdated;
    } else {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(prodId)
          .update({
        'prodName': motorFormSqlDb.prodName,
        'catName': motorFormSqlDb.catName,
        'subCatType': motorFormSqlDb.subCatType,
        'prodDes': motorFormSqlDb.prodDes,
        'sellerNotes': motorFormSqlDb.sellerNotes,
        'year': motorFormSqlDb.year,
        'make': motorFormSqlDb.make,
        'model': motorFormSqlDb.model,
        'prodCondition': motorFormSqlDb.prodCondition,
        'price': motorFormSqlDb.price,
        'stockInHand': motorFormSqlDb.stockInHand,
        'currencyName': _currencyName,
        'currencySymbol': _currencySymbol,
        'imageUrlFeatured': motorFormSqlDb.imageUrlFeatured,
        'addressLocation': _addressLocation,
        'countryCode': _countryCode,
        'latitude': _latitude,
        'longitude': _longitude,
        'userDetailDocId': _userDetailDocId,
        'deliveryInfo': motorFormSqlDb.deliveryInfo,
        'typeOfAd': motorFormSqlDb.typeOfAd,
        'distance': '',
        'status': 'Pending',
        'forSaleBy': motorFormSqlDb.forSaleBy,
        'listingStatus': 'Available',
        'createdAt': Timestamp.now(),
        'subscription': 'Free',
      }).then((p) async {
        // _prodDocId = prodId;

        if (prodId.isNotEmpty) {
          for (var i = 0; i < prodImagesSqlDb.length; i++) {
            if (prodImagesSqlDb[i].imageUrl.substring(0, 5) != 'https') {
              final fileNameExt = prodImagesSqlDb[i].imageUrl.split('/').last;
              final fileName = fileNameExt.split('.').first;

              final ref = FirebaseStorage.instance
                  .ref()
                  .child('product_images/${user.uid}')
                  // 'product_images/$_prodDocId')
                  .child(motorFormSqlDb.make +
                      motorFormSqlDb.model +
                      fileName +
                      '.jpg');

              await ref.putFile(File(prodImagesSqlDb[i].imageUrl));

              _imageUrl = await ref.getDownloadURL();

              prodImagesSqlDb[i].imageUrl = _imageUrl;
            }
          }

          print('All images are loaded into storage');

          if (prodImagesSqlDb.length > 0) {
            if (prodImagesSqlDb.any((e) => e.featuredImage == "true")) {
            } else {
              prodImagesSqlDb[0].featuredImage = "true";
            }
          }

          // Product Image delete

          batch = FirebaseFirestore.instance.batch();

          await FirebaseFirestore.instance
              .collection('ProdImages')
              .where('prodDocId', isEqualTo: prodId)
              .get()
              .then((querySnapshot) {
            querySnapshot.docs.forEach((document) {
              batch.delete(document.reference);
            });

            return batch.commit().catchError((error) =>
                print("Failed to delete products in ProdImages: $error"));
          });

          //

          _featuredImage = false;
          for (var i = 0; i < prodImagesSqlDb.length; i++) {
            if (prodImagesSqlDb[i].featuredImage == 'true') {
              if (!_featuredImage) {
                _featuredImage = true;
              } else {
                prodImagesSqlDb[i].featuredImage = 'false';
              }
            }
            await FirebaseFirestore.instance.collection('ProdImages').add({
              'prodDocId': prodId,
              'imageType': prodImagesSqlDb[i].imageType,
              'imageUrl': prodImagesSqlDb[i].imageUrl,
              'featuredImage':
                  prodImagesSqlDb[i].featuredImage == 'true' ? true : false,
            }).then((value) async {
              if (prodImagesSqlDb[i].featuredImage == 'true' &&
                  prodImagesSqlDb[i].imageUrl.isNotEmpty) {
                motorFormSqlDb.imageUrlFeatured = prodImagesSqlDb[i].imageUrl;
                _prodUpdated = 'Uncompleted';

                await _updateProdFeaturedImage(
                        prodId, motorFormSqlDb.imageUrlFeatured)
                    .then(
                  (value) {
                    _prodUpdated = value;
                  },
                );
              }
            });
          }
        }
      }).catchError((onError) {
        print('Unable to post your add please try again!!');
      });
    }

    return _prodUpdated;
  }

  Future<void> _deleteProduct(
      String prodId, String category, String subCategory) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    return await FirebaseFirestore.instance
        .collection('products')
        .doc(prodId)
        .delete()
        .then((value) async {
      if (category.trim() == 'Vehicle' &&
          !subCategory.contains('Accessories') &&
          !subCategory.contains('Others')) {
        await FirebaseFirestore.instance
            .collection('CtmSpecialInfo')
            .where('prodDocId', isEqualTo: prodId)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((document) {
            batch.delete(document.reference);
            print('ctm delete success!');
          });
          return batch.commit().catchError((error) => print(
              "Failed to delete products in CtmSpecialInfo batch: $error"));
        }).catchError((error) =>
                print("Failed to get product in CtmSpecialInfo: $error"));
      }

      batch = FirebaseFirestore.instance.batch();

      await FirebaseFirestore.instance
          .collection('favoriteProd')
          .where('prodDocId', isEqualTo: prodId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((document) {
          batch.delete(document.reference);
        });

        return batch.commit().catchError((error) =>
            print("Failed to delete products in FavoriteProd: $error"));
      });

      batch = FirebaseFirestore.instance.batch();

      await FirebaseFirestore.instance
          .collection('ProdImages')
          .where('prodDocId', isEqualTo: prodId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((document) {
          batch.delete(document.reference);
        });

        return batch.commit().catchError((error) =>
            print("Failed to delete products in ProdImages: $error"));
      });

      final refDel =
          FirebaseStorage.instance.ref().child('product_images/${user.uid}');
      // 'product_images/$prodId');

      // var url = await refDel.getDownloadURL();

      // print('url - $url');

      await refDel.delete().then((value) => 'Product Deleted in storage');
    }).catchError((error) => print("Failed to delete product: $error"));
  }

  Future<String> _updateProdFeaturedImage(
      String prodDocId, String featuredImageUrl) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(prodDocId)
        .update(
      {
        'imageUrlFeatured': '$featuredImageUrl',
      },
    ).then(
      (value) {
        _prodUpdated = 'Success';
        print("Product Updated - $_prodUpdated");
      },
    ).catchError(
      (error) {
        print("Failed to update product: $error");
        _prodUpdated = 'Error';
      },
    ).whenComplete(
      () {
        print('update completed - $_prodUpdated');
      },
    );

    return _prodUpdated;
  }

  // Functions to operate prod images

  Future _saveImage(ProdImagesSqlDb prodImageSqlDb) async {
    await prodImageProvider.addImages(prodImageSqlDb);
    int countE = await prodImageProvider.countEProdImages();
    int countI = await prodImageProvider.countIProdImages();
    setState(() {
      _eImageCount = countE;
      _iImageCount = countI;
    });
  }

  Future _deleteImage(String id, String imageType) async {
    print("count in deleteImage1");
    await prodImageProvider.deleteImages(id, imageType);

    int countE = await prodImageProvider.countEProdImages();
    int countI = await prodImageProvider.countIProdImages();
    int count = countE + countI;
    setState(() {
      _eImageCount = countE;
      _iImageCount = countI;
    });

    print("count in deleteImage - $count");

    if (count == 0) {
      await _deleteMotorFormAll();
      await _initialLoadMotorForm();
    }
  }

  Future<void> _deleteImageAll() async {
    await Provider.of<ProdImagesSqlDbProvider>(context, listen: false)
        .deleteImagesAll();
  }

  // Functions to operate motor form data

  Future<void> _initialLoadMotorForm() async {
    print("motorFormSqlDb.forsaleby - ${motorFormSqlDb.forSaleBy}");
    // _initializeMotorVariables();
    int count = await motorFormProvider.countMotorForm();

    setState(() {
      _motorFormCount = count;
    });

    if (_motorFormCount > 0) {
      List<MotorFormSqlDb> motorFormSqlDbL =
          await motorFormProvider.fetchMotorForm();

      // _initializeMotorVariables();
      motorFormSqlDb = motorFormSqlDbL[0];

      _specialVehicle = false;
      if (motorFormSqlDb.subCatType == 'Cars' ||
          motorFormSqlDb.subCatType == 'Trucks' ||
          motorFormSqlDb.subCatType == 'Caravans') {
        _specialVehicle = true;
      }

      // Asign values to the controllers
      if (_specialVehicle) {
        controllerEC.text = motorFormSqlDb.exteriorColor;
        controllerIC.text = motorFormSqlDb.interiorColor;
      } else {
        controllerEC.text = motorFormSqlDb.exteriorColor;
      }
    }
    // if (_motorFormCount == 0) {
    //   motorFormSqlDb = MotorFormSqlDb();
    // }
  }

  _initializeMotorVariables() {
    motorFormSqlDb = MotorFormSqlDb(
      id: '',
      catName: '',
      subCatType: '',
      prodName: '',
      prodDes: '',
      sellerNotes: '',
      prodCondition: '',
      price: '',
      stockInHand: '',
      imageUrlFeatured: '',
      deliveryInfo: '',
      typeOfAd: '',
      year: '',
      make: '',
      model: '',
      vehicleType: '',
      mileage: '',
      vin: '',
      engine: '',
      fuelType: '',
      options: '',
      subModel: '',
      numberOfCylinders: '',
      safetyFeatures: '',
      driveType: '',
      interiorColor: '',
      bodyType: '',
      exteriorColor: '',
      forSaleBy: '',
      warranty: '',
      trim: '',
      transmission: '',
      steeringLocation: '',
      vehicleTypeYear: '',
      editPost: '',
    );
  }

  Future<void> _saveMotorForm(MotorFormSqlDb motorFormSqlDb) async {
    await motorFormProvider.addMotorForm(motorFormSqlDb);
    await _initialLoadMotorForm();
  }

  Future<void> _updateMotorForm(
      String id, String columnName, String columnValue) async {
    await motorFormProvider.updateMotorForm(id, columnName, columnValue);
    if (columnName == 'catName') {
      await motorFormProvider.updateMotorForm(id, "subCatType", "Unspecified");
    }
    await _initialLoadMotorForm();
  }

  Future<void> _deleteMotorFormAll() async {
    await motorFormProvider.deleteMotorFormAll();
  }

  Future<void> _dropMotorForm() async {
    await motorFormProvider.dropMotorForm();
  }
}
