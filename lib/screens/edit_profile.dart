//Imports for pubspec Packages
import 'dart:io';

import 'package:blrber/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:search_map_place/search_map_place.dart';

//Imports for Constants
import '../constants.dart';

//Imports for Models
import '../models/user_detail.dart';

//Imports for Providers
import '../provider/get_current_location.dart';

//Imports for Services
import '../services/api_keys.dart';

//Imports for Widgets
import '../widgets/search_place_auto_complete_widget_custom.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  UserDetail userDataUpdated = UserDetail();
  // UserDetail userData = UserDetail();
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();
  List<DropdownMenuItem<String>> _userTypes = [];
  User user;
  File pickedImage, pickedLogoImage;
  String _countryCode = "";
  String _addressLocation = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _imageUrl = "";
  bool _fetchingLocation = false;
  String _updateProfile = '';
  var _initialSelectedItem = 'Unspecified';

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser;

    getCurrentLocation =
        Provider.of<GetCurrentLocation>(context, listen: false);

    setState(() {
      _countryCode = getCurrentLocation.countryCode;
    });
    _checkLocationPermission();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    // await _checkLocationPermission();
    List<UserDetail> userDetails = Provider.of<List<UserDetail>>(context);
    if (userDetails.length > 0 && user != null) {
      userDetails = userDetails
          .where((e) => e.email.trim() == user.email.trim())
          .toList();
      if (userDetails.length > 0) {
        userDataUpdated = userDetails[0];
      }
    }
    // List<UserType> userTypes = Provider.of<List<UserType>>(context);
    List<ForSaleBy> userTypes = Provider.of<List<ForSaleBy>>(context);

    _userTypes = [];
    if (userTypes != null) {
      for (ForSaleBy userType in userTypes) {
        _userTypes.add(
          DropdownMenuItem(
            value: userType.forSaleBy,
            child: Text(userType.forSaleBy),
          ),
        );
      }
    }
    super.didChangeDependencies();
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
    // else {
    //   getCurrentLocation =
    //       Provider.of<GetCurrentLocation>(context, listen: false);

    //   setState(() {
    //     _countryCode = getCurrentLocation.countryCode;
    //   });
    // }
  }

  Future<void> _trySubmit() async {
    final isValid = _formKey.currentState.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState.save();
      _showUpdateDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please Enter Mandatory Fields!'),
        ),
      );
    }
  }

  Future<void> _updateProfileRecord() async {
    if (pickedImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child(userDataUpdated.userDetailDocId + '.jpg');

      await ref.putFile(pickedImage);

      _imageUrl = await ref.getDownloadURL();

      userDataUpdated.userImageUrl = _imageUrl;
    }

    if (pickedLogoImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child(userDataUpdated.userDetailDocId + 'Logo' + '.jpg');

      await ref.putFile(pickedLogoImage);

      _imageUrl = await ref.getDownloadURL();

      userDataUpdated.companyLogoUrl = _imageUrl;
    }

    if (_addressLocation.isNotEmpty) {
      userDataUpdated.addressLocation = _addressLocation;
      userDataUpdated.latitude = _latitude;
      userDataUpdated.longitude = _longitude;
    }

    await FirebaseFirestore.instance
        .collection('userDetails')
        .doc(userDataUpdated.userDetailDocId.trim())
        .update({
      'userImageUrl': userDataUpdated.userImageUrl,
      'displayName': userDataUpdated.displayName,
      'addressLocation': userDataUpdated.addressLocation,
      'latitude': userDataUpdated.latitude,
      'longitude': userDataUpdated.longitude,
      'phoneNumber': userDataUpdated.phoneNumber,
      'alternateNumber': userDataUpdated.alternateNumber,
      'countryCode': _countryCode,
      'buyingCountryCode': _countryCode,
      'userType': userDataUpdated.userType,
      'licenceNumber': userDataUpdated.licenceNumber,
      'companyName': userDataUpdated.companyName,
      'companyLogoUrl': userDataUpdated.companyLogoUrl,
      'isProfileUpdated': true,
    }).then((value) {
      print("User Updated");
      setState(() {
        _updateProfile = "Success";
      });
    }).catchError((error) => print("Failed to update User Details: $error"));
  }

  Future _pickImage(String sourceType) async {
    try {
      final picker = ImagePicker();
      final imageFile = await picker.getImage(
        source: sourceType == 'G' ? ImageSource.gallery : ImageSource.camera,
      );
      if (imageFile == null) {
        return null;
      }
      setState(() {
        pickedImage = File(imageFile.path);
      });

      if (pickedImage != null) {
        File croppedFile = await ImageCropper.cropImage(
            maxHeight: 300,
            maxWidth: 300,
            sourcePath: imageFile.path,
            aspectRatioPresets: Platform.isAndroid
                ? [
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9
                  ]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio5x3,
                    CropAspectRatioPreset.ratio5x4,
                    CropAspectRatioPreset.ratio7x5,
                    CropAspectRatioPreset.ratio16x9
                  ],
            androidUiSettings: AndroidUiSettings(
                toolbarTitle: 'Cropper',
                toolbarColor: bPrimaryColor,
                toolbarWidgetColor: bBackgroundColor,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false),
            iosUiSettings: IOSUiSettings(
              title: 'Cropper',
            ));
        if (croppedFile != null) {
          setState(() {
            pickedImage = croppedFile;
          });
        }
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

  Future _pickLogoImage(String sourceType) async {
    try {
      final pickerL = ImagePicker();
      final imageFileL = await pickerL.getImage(
        source: sourceType == 'G' ? ImageSource.gallery : ImageSource.camera,
      );
      if (imageFileL == null) {
        return null;
      }

      pickedLogoImage = File(imageFileL.path);

      if (pickedLogoImage != null) {
        File croppedFileL = await ImageCropper.cropImage(
            maxHeight: 300,
            maxWidth: 300,
            sourcePath: imageFileL.path,
            aspectRatioPresets: Platform.isAndroid
                ? [
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9
                  ]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio5x3,
                    CropAspectRatioPreset.ratio5x4,
                    CropAspectRatioPreset.ratio7x5,
                    CropAspectRatioPreset.ratio16x9
                  ],
            androidUiSettings: AndroidUiSettings(
                toolbarTitle: 'Cropper',
                toolbarColor: bPrimaryColor,
                toolbarWidgetColor: bBackgroundColor,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false),
            iosUiSettings: IOSUiSettings(
              title: 'Cropper',
            ));
        if (croppedFileL != null) {
          setState(() {
            pickedLogoImage = croppedFileL;
          });
        }
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

  void _showUpdateDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Update User Profile"),
              content: Container(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _updateProfile == ''
                          ? const Text(
                              'Do you want to update?',
                              style: TextStyle(color: Colors.blue),
                            )
                          : CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  bScaffoldBackgroundColor),
                              backgroundColor: bPrimaryColor,
                            ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                if (_updateProfile == '')
                  TextButton(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                if (_updateProfile == '')
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      setState(() {
                        _updateProfile = 'Start';
                      });

                      _updateProfileRecord().then((value) {
                        Navigator.of(context).pop();
                        if (_updateProfile == 'Success') {
                          // setState(() {
                          _updateProfile = '';
                          // });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User Updated Successfully!'),
                            ),
                          );
                        }
                      });
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusNode = FocusScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: userDataUpdated.userDetailDocId != null
          ? GestureDetector(
              onTap: () {
                focusNode.unfocus();
              },
              child: Container(
                width: double.infinity,
                color: bBackgroundColor,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.grey,
                                backgroundImage: pickedImage != null
                                    ? FileImage(pickedImage)
                                    : userDataUpdated.userImageUrl == ""
                                        ? AssetImage(
                                            'assets/images/default_user_image.png')
                                        : NetworkImage(
                                            userDataUpdated.userImageUrl),
                              ),
                              Positioned(
                                bottom: -10,
                                right: -10,
                                child: IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.camera),
                                  onPressed: () async {
                                    var status = await Permission.photos.status;

                                    if (status.isGranted) {
                                      await _pickImage('G');
                                    } else {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              CupertinoAlertDialog(
                                                title:
                                                    Text('Camera Permission'),
                                                content: Text(
                                                    'This app needs camera access to take / choose pictures'),
                                                actions: <Widget>[
                                                  CupertinoDialogAction(
                                                    child: Text('Deny'),
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                  ),
                                                  CupertinoDialogAction(
                                                    child: Text('Settings'),
                                                    onPressed: () =>
                                                        openAppSettings(),
                                                  ),
                                                ],
                                              ));
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('Email : '),
                              Text(userDataUpdated.email)
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('User Name : '),
                              Text(userDataUpdated.userName)
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            initialValue: userDataUpdated.displayName,
                            key: ValueKey('displayName'),
                            onEditingComplete: () => focusNode.nextFocus(),
                            validator: (value) {
                              if (value.isEmpty || value.length < 7) {
                                return 'Must be at lease 7 characters long.';
                              }
                              if (value.length > 20) {
                                return 'Should not be more than 20 characters long.';
                              }
                              return null;
                            },
                            decoration:
                                InputDecoration(labelText: 'Display Name'),
                            onSaved: (value) {
                              userDataUpdated.displayName = value;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            initialValue: userDataUpdated.phoneNumber,
                            key: ValueKey('phoneNumber'),
                            onEditingComplete: () => focusNode.nextFocus(),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Phone number must not be empty';
                              }
                              if (value.length > 10) {
                                return 'Phone number 10 digits';
                              }

                              return null;
                            },
                            decoration: const InputDecoration(
                                labelText: 'Phone Number'),
                            onSaved: (value) {
                              userDataUpdated.phoneNumber = value;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            initialValue: userDataUpdated.alternateNumber,
                            key: ValueKey('alternateNumber'),
                            onEditingComplete: () => focusNode.nextFocus(),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Phone number must not be empty';
                              }
                              if (value.length > 10) {
                                return 'Phone number 10 digits';
                              }

                              return null;
                            },
                            decoration: const InputDecoration(
                                labelText: 'Alternate Phone Number'),
                            onSaved: (value) {
                              userDataUpdated.alternateNumber = value;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: const Text('User Type'),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          DropdownButtonFormField<String>(
                              items: _userTypes,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) async {
                                setState(() {
                                  userDataUpdated.userType = value;
                                });
                              },
                              onSaved: (value) {
                                userDataUpdated.userType = value;
                              },
                              validator: (value) {
                                if (value == 'Unspecified') {
                                  return 'Please select User Type!';
                                }
                                return null;
                              },
                              value: userDataUpdated.userType.isEmpty
                                  ? _initialSelectedItem
                                  : userDataUpdated.userType),
                          const SizedBox(
                            height: 10,
                          ),
                          if (userDataUpdated.userType != 'Private Seller')
                            Column(
                              children: [
                                TextFormField(
                                  initialValue: userDataUpdated.companyName,
                                  key: ValueKey('companyName'),
                                  onEditingComplete: () =>
                                      focusNode.nextFocus(),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please provide company name!';
                                    }
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                      labelText: 'Company Name'),
                                  onSaved: (value) {
                                    userDataUpdated.companyName = value;
                                  },
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  initialValue: userDataUpdated.licenceNumber,
                                  key: ValueKey('licenceNumber'),
                                  onEditingComplete: () =>
                                      focusNode.nextFocus(),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please provide Licence Number!';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                      labelText: 'Licence Number'),
                                  onSaved: (value) {
                                    userDataUpdated.licenceNumber = value;
                                  },
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                // Row(
                                //   children: [
                                //     const Text('Company Logo'),
                                //     const SizedBox(
                                //       width: 20,
                                //     ),
                                //     Stack(
                                //       children: [
                                //         CircleAvatar(
                                //           radius: 40,
                                //           backgroundColor: Colors.grey,
                                //           backgroundImage: pickedLogoImage !=
                                //                   null
                                //               ? FileImage(pickedLogoImage)
                                //               : userDataUpdated
                                //                           .companyLogoUrl ==
                                //                       ""
                                //                   ? AssetImage(
                                //                       'assets/images/default_user_image.png')
                                //                   : NetworkImage(userDataUpdated
                                //                       .companyLogoUrl),
                                //         ),
                                //         Positioned(
                                //           bottom: -10,
                                //           right: -10,
                                //           child: IconButton(
                                //             icon:
                                //                 FaIcon(FontAwesomeIcons.camera),
                                //             onPressed: () async {
                                //               await _pickLogoImage('G');
                                //             },
                                //           ),
                                //         )
                                //       ],
                                //     ),
                                //   ],
                                // ),
                              ],
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: const Text('Present Address'),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(userDataUpdated.addressLocation),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: const Text('New Location'),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SearchPlaceAutoCompleteWidgetCustom(
                              apiKey: placeApiKey,
                              components: _countryCode,
                              placeType: PlaceType.address,
                              onSelected: (place) async {
                                setState(() {
                                  _addressLocation = '';
                                  _latitude = 0.0;
                                  _longitude = 0.0;
                                  _fetchingLocation = true;
                                });
                                await getCurrentLocation
                                    .getselectedPosition(place);

                                setState(() {
                                  _addressLocation =
                                      getCurrentLocation.addressLocation;
                                  _latitude = getCurrentLocation.latitude;
                                  _longitude = getCurrentLocation.longitude;
                                  _fetchingLocation = false;
                                  // userDataUpdated.addressLocation =
                                  //     _addressLocation;
                                  // userDataUpdated.latitude = _latitude;
                                  // userDataUpdated.longitude = _longitude;
                                  print(
                                      'Address Location - ${userDataUpdated.addressLocation}');
                                });
                              },
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () async {
                                setState(() {
                                  _addressLocation = '';
                                  _latitude = 0.0;
                                  _longitude = 0.0;
                                  _fetchingLocation = true;
                                });

                                await getCurrentLocation.getCurrentPosition();
                                setState(() {
                                  _addressLocation =
                                      getCurrentLocation.addressLocation;
                                  _latitude = getCurrentLocation.latitude;
                                  _longitude = getCurrentLocation.longitude;
                                  _fetchingLocation = false;
                                  // userDataUpdated.addressLocation =
                                  //     _addressLocation;
                                  // userDataUpdated.latitude = _latitude;
                                  // userDataUpdated.longitude = _longitude;
                                });
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text("Current Location"),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('New Address'),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_addressLocation),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          !_fetchingLocation
                              ? ElevatedButton.icon(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.blueGrey[700],
                                    ),
                                  ),
                                  onPressed: () async {
                                    await _trySubmit();
                                  },
                                  icon: const Icon(Icons.update),
                                  label: const Text('Update'),
                                )
                              : Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              child: const Center(
                child: const Text(
                    'Something went wrong while getting user details!!'),
              ),
            ),
    );
  }
}
