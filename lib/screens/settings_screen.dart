//Imports for pubspec Packages

import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:package_info/package_info.dart';
import 'package:darq/darq.dart';

//Imports for Models
import '../models/product.dart';
import '../models/user_detail.dart';

//Imports for Providers
import '../provider/get_current_location.dart';

//Imports for Constants
import '../constants.dart';

//Imports for Services
import '../services/new_version_check.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settngs_screen';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
  // UserDetail userDataUpdated = UserDetail();
  // UserDetail userData = UserDetail();
  List<UserDetail> userDetails = [];
  User user;
  String _deleteAccount = '';

  bool _versionCheck = false;
  int prodCount = 0;
  List<String> availableProdCC = [];
  final googleSignIn = GoogleSignIn();
  final TextEditingController _password = TextEditingController();

  String dismissText = 'Maybe Later';
  String updateText = 'Update';
  String dialogText;
  String dialogTitle = 'Update Available';
  String _providerId = "";

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  void showSnack(String text) {
    if (_scaffoldKey.currentContext != null) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser;
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  void didChangeDependencies() {
    userDetails = Provider.of<List<UserDetail>>(context);

    final products = Provider.of<List<Product>>(context);

    if (userDetails.length > 0 && user != null) {
      userDetails = userDetails
          .where((e) => e.userDetailDocId.trim() == user.uid.trim())
          .toList();
      print("userDataUpdated.providerId 0- ${_providerId}");

      // userDataUpdated = UserDetail();
      if (userDetails.length > 0) {
        // userDataUpdated = userDetails[0];
        _providerId = userDetails[0].providerId;
        prodCount = products
            .where((e) => e.userDetailDocId == userDetails[0].userDetailDocId)
            .length;
      }
    }

    // if (userDataUpdated != null) {
    //   prodCount = products
    //       .where((e) => e.userDetailDocId == userDataUpdated.userDetailDocId)
    //       .length;
    // }

    print("userDataUpdated.providerId 1- ${_providerId}");

    var distinctProductsCC = products.distinct((d) => d.countryCode).toList();

    availableProdCC = [];
    if (distinctProductsCC.length > 0) {
      for (var item in distinctProductsCC) {
        availableProdCC.add(item.countryCode);
      }
    }

    super.didChangeDependencies();
  }

  void _showDeleteDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Delete Account"),
              content: Container(
                height: MediaQuery.of(context).size.height / 4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _deleteAccount == ''
                          ?
                          // Text(
                          //     'Do you want to Delete Account? ${user.displayName}',
                          //     style: TextStyle(color: Colors.blue),
                          //   )
                          // : _deleteAccount == 'ReAuth'
                          //     ?
                          _providerId == "password"
                              ? Column(
                                  children: [
                                    const Text(
                                        "Enter Password to Delete Account"),
                                    TextFormField(
                                      controller: _password,
                                      obscureText: true,
                                      // key: ValueKey('password'),
                                      // validator: (value) {
                                      //   if (value.isEmpty || value.length < 7) {

                                      //     return 'Password must be at lease 7 characters long.';
                                      //   }
                                      //   return null;
                                      // },
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        icon: Icon(
                                          Icons.lock,
                                          color: bPrimaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Do you want to Delete Account? ${userDetails[0].displayName}',
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
                if (_deleteAccount == '')
                  TextButton(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                if (_deleteAccount == '')
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      setState(() {
                        _deleteAccount = 'Start';
                      });

                      _deleteAccountDetails().then((value) {
                        // if (_reAuth) {
                        //   setState(() {
                        //     _deleteAccount = 'ReAuth';
                        //   });
                        // } else {
                        // Navigator.of(context).pop();

                        if (_deleteAccount == 'Success') {
                          _deleteAccount = '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account deleted!'),
                            ),
                          );

                          Navigator.of(context).pop();
                        }
                        Navigator.of(context).pop();
                        // }
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

  void _showInfoDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Products exist"),
              content: Container(
                height: MediaQuery.of(context).size.height / 4,
                child: Center(
                    child: Text(
                        "You have posted $prodCount product(s). Please remove before delete the account")),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // functions for product catalog
  Future<void> _deleteAccountDetails() async {
    try {
      await _deleteUserDetails();
      await _deleteUserDeviceToken();
      await _deleteChatsFrom();
      await _deleteChatsTo();
      await _deleteReceivedMsgCountFrom();
      await _deleteReceivedMsgCountTo();

      print("userDataUpdated.providerId 2- ${_providerId}");

      if (_providerId == "password") {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email,
          password: _password.text,
        );

        await user.reauthenticateWithCredential(credential);
        await FirebaseAuth.instance.currentUser.delete();
      } else if (_providerId == "google.com") {
        await _signInWithGoogle();
        await FirebaseAuth.instance.currentUser.delete();
      }

      // await _deleteUserDetails();
      // await _deleteUserDeviceToken();
      // await _deleteChatsFrom();
      // await _deleteChatsTo();
      // await _deleteReceivedMsgCountFrom();
      // await _deleteReceivedMsgCountTo();

      if (_providerId == "google.com") {
        // await googleSignIn.disconnect();
        await googleSignIn.signOut();
      }
      FirebaseAuth.instance.signOut();

      _deleteAccount = "Success";
    } on FirebaseAuthException catch (e) {
      // if (e.code == 'requires-recent-login') {
      //   _reAuth = true;
      //   print(
      //       'The user must reauthenticate before this operation can be executed.');
      // }

      print('Firebase Auth Exception $e');
      _deleteAccount = '';
      if (e.code == 'wrong-password') {
        print('wrong-password');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wrong password provided for that user.'),
          ),
        );
      } else {
        print('Exception $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Try again!'),
          ),
        );
      }
    } catch (e) {
      print('Exception $e');
      _deleteAccount = '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong. Try again!'),
        ),
      );
    }

    // WriteBatch batch = FirebaseFirestore.instance.batch();

    // return await FirebaseFirestore.instance
    //     .collection('products')
    //     .doc(prodId)
    //     .delete()
    //     .then((value) async {
    //   if (category.toLowerCase().trim() == 'vehicle'.trim() &&
    //       !subCategory.contains('Accessories')) {
    //     await FirebaseFirestore.instance
    //         .collection('CtmSpecialInfo')
    //         .where('prodDocId', isEqualTo: prodId)
    //         .get()
    //         .then((querySnapshot) {
    //       querySnapshot.docs.forEach((document) {
    //         batch.delete(document.reference);
    //       });
    //       return batch.commit().catchError((error) => print(
    //           "Failed to delete products in CtmSpecialInfo batch: $error"));
    //     }).catchError((error) =>
    //             print("Failed to get product in CtmSpecialInfo: $error"));
    //   }

    //   batch = FirebaseFirestore.instance.batch();

    //   await FirebaseFirestore.instance
    //       .collection('favoriteProd')
    //       .where('prodDocId', isEqualTo: prodId)
    //       .get()
    //       .then((querySnapshot) {
    //     querySnapshot.docs.forEach((document) {
    //       batch.delete(document.reference);
    //     });
    //     return batch.commit().catchError((error) =>
    //         print("Failed to delete products in favoriteProd: $error"));
    //   });

    //   batch = FirebaseFirestore.instance.batch();

    //   await FirebaseFirestore.instance
    //       .collection('ProdImages')
    //       .where('prodDocId', isEqualTo: prodId)
    //       .get()
    //       .then((querySnapshot) {
    //     querySnapshot.docs.forEach((document) {
    //       batch.delete(document.reference);
    //     });
    //     setState(() {
    //       _prodDeleted = 'true';
    //     });
    //     return batch.commit().catchError((error) =>
    //         print("Failed to delete products in ProdImages: $error"));
    //   });

    //   final refDel = FirebaseStorage.instance.ref().child(
    //       // 'product_images/${user.uid}/${motorFormSqlDb.catName}/${motorFormSqlDb.make}')
    //       'product_images/$prodId');

    //   await refDel.delete().then((value) => 'Product Deleted in storage');
    // }).catchError((error) => print("Failed to delete product: $error"));
  }

  Future<void> _signInWithGoogle() async {
    try {
      UserCredential userCredential;

      final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final googleAuthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await FirebaseAuth.instance
          .signInWithCredential(googleAuthCredential);
    } catch (e) {
      print('Failed to sign in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google:'),
        ),
      );
    }
  }

  Future<void> _deleteUserDetails() async {
    CollectionReference userDetails =
        FirebaseFirestore.instance.collection('userDetails');

    print('user.uid.trim() - ${user.uid.trim()}');

    return userDetails
        .doc(user.uid.trim())
        .delete()
        .then((value) => print("User Details Deleted"))
        .catchError((error) => print("Failed to delete user details: $error"));
  }

  Future<void> _deleteUserDeviceToken() async {
    CollectionReference usersDeviceToken =
        FirebaseFirestore.instance.collection('userDeviceToken');

    return usersDeviceToken
        .doc(user.uid.trim())
        .delete()
        .then((value) => print("User Device Token Deleted"))
        .catchError(
            (error) => print("Failed to delete user device token: $error"));
  }

  Future<void> _deleteChatsFrom() async {
    WriteBatch chatDeletebatch = FirebaseFirestore.instance.batch();

    CollectionReference chats = FirebaseFirestore.instance.collection('chats');

    await chats
        .where('userIdFrom', isEqualTo: user.uid.trim())
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        chatDeletebatch.delete(document.reference);
      });
      return chatDeletebatch
          .commit()
          .then((value) => print("User From chats Deleted"))
          .catchError(
              (error) => print("Failed to delete user From chats: $error"));
    });
  }

  Future<void> _deleteChatsTo() async {
    WriteBatch chatDeletebatch = FirebaseFirestore.instance.batch();

    CollectionReference chats = FirebaseFirestore.instance.collection('chats');

    await chats
        .where('userIdTo', isEqualTo: user.uid.trim())
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        chatDeletebatch.delete(document.reference);
      });
      return chatDeletebatch
          .commit()
          .then((value) => print("User To chats Deleted"))
          .catchError(
              (error) => print("Failed to delete user To chats: $error"));
    });
  }

  Future<void> _deleteReceivedMsgCountFrom() async {
    WriteBatch chatDeletebatch = FirebaseFirestore.instance.batch();

    CollectionReference chats =
        FirebaseFirestore.instance.collection('receivedMsgCount');

    await chats
        .where('sentUserId', isEqualTo: user.uid.trim())
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        chatDeletebatch.delete(document.reference);
      });
      return chatDeletebatch
          .commit()
          .then((value) => print("Received Msg Count From Deleted"))
          .catchError((error) =>
              print("Failed to delete Received Msg Count From: $error"));
    });
  }

  Future<void> _deleteReceivedMsgCountTo() async {
    WriteBatch chatDeletebatch = FirebaseFirestore.instance.batch();

    CollectionReference chats =
        FirebaseFirestore.instance.collection('receivedMsgCount');

    await chats
        .where('receivedUserId', isEqualTo: user.uid.trim())
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        chatDeletebatch.delete(document.reference);
      });
      return chatDeletebatch
          .commit()
          .then((value) => print("Received Msg Count To Deleted"))
          .catchError((error) =>
              print("Failed to delete Received Msg Count To: $error"));
    });
  }

  Future<void> _updateBuyingCountry(String countryCode) async {
    await FirebaseFirestore.instance
        .collection('userDetails')
        .doc(userDetails[0].userDetailDocId.trim())
        .update({
      'buyingCountryCode': countryCode,
    }).then((value) {
      print("User Updated with Selected Buying Country");
    }).catchError((error) =>
            print("Failed to update User\'s Buying Country: $error"));
  }

  Future<void> _checkVersion() async {
    setState(() {
      _versionCheck = true;
    });

    await FirebaseFirestore.instance
        .collection('packageInfo')
        .limit(1)
        .get()
        .then((QuerySnapshot querySnapshot) async {
      final packageData = querySnapshot.docs
          .firstWhere((element) => element["appName"] == "blrber");

      final prodAppVersion = packageData['version'];
      final prodAppBuild = packageData['buildNumber'];

      final newVersionCheck = NewVersionCheck(
          context: context,
          androidId: packageData['packageName'],
          iOSId: packageData['packageName'],
          storeVersion: prodAppVersion,
          storeBuild: prodAppBuild);
      final status = await newVersionCheck.getVersionStatus();

      if (prodAppVersion == _packageInfo.version &&
          prodAppBuild == _packageInfo.buildNumber) {
        Fluttertoast.showToast(
          msg: "Your app is UpToDate!!",
          toastLength: Toast.LENGTH_SHORT,
        );
      } else {
        await newVersionCheck.showAlertIfNecessary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final getCurrentLocation = Provider.of<GetCurrentLocation>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: bDisabledColor,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: bDisabledColor),
        ),
        backgroundColor: bBackgroundColor,
      ),
      backgroundColor: bBackgroundColor,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height - 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    ListTile(
                      leading: Text(
                        'Country',
                        style: TextStyle(fontSize: 18, color: bDisabledColor),
                      ),
                      trailing: Flag(
                        getCurrentLocation.countryCode,
                        height: 20,
                        width: 25,
                        fit: BoxFit.fill,
                      ),
                      onTap: () {},
                    ),
                    if (availableProdCC.length > 0)
                      ListTile(
                        leading: Text(
                          'Buying Country',
                          style: TextStyle(fontSize: 18, color: bDisabledColor),
                        ),
                        trailing: userDetails.length > 0
                            ? Flag(
                                userDetails[0].buyingCountryCode.isNotEmpty
                                    ? userDetails[0].buyingCountryCode
                                    : getCurrentLocation.countryCode,
                                height: 20,
                                width: 25,
                                fit: BoxFit.fill,
                              )
                            : Container(
                                height: 0,
                                width: 0,
                              ),
                        onTap: () {
                          // Following block of code is used to find products from other country.
                          // This block of code is commented because now plan to market the app in thier own contry.
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
                          //             color: const Color(0xFF8C98A8)
                          //                 .withOpacity(0.2),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   );
                        },
                      ),
                    ListTile(
                      leading: const Text(
                        'Currency',
                        style: TextStyle(fontSize: 18, color: bDisabledColor),
                      ),
                      trailing: Text(
                        getCurrentLocation.currencyCode,
                        style: TextStyle(fontSize: 15, color: bDisabledColor),
                      ),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Text(
                        'Language',
                        style: TextStyle(fontSize: 18, color: bDisabledColor),
                      ),
                      trailing: const Text(
                        'English',
                        style: TextStyle(fontSize: 15, color: bDisabledColor),
                      ),
                      onTap: () {
                        print('Language');
                      },
                    ),
                    ListTile(
                      leading: const Text(
                        'Delete Account',
                        style: TextStyle(fontSize: 18, color: bDisabledColor),
                      ),
                      onTap: () {
                        if (prodCount == 0) {
                          _showDeleteDialog();
                        } else {
                          _showInfoDialog();
                        }
                      },
                    ),
                    ListTile(
                      leading: const Text(
                        'Check for Update',
                        style: TextStyle(fontSize: 18, color: bDisabledColor),
                      ),
                      trailing: _versionCheck
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  bScaffoldBackgroundColor),
                              backgroundColor: bPrimaryColor,
                            )
                          : Text(""),
                      onTap: () {
                        _checkVersion().whenComplete(
                          () => setState(() {
                            _versionCheck = false;
                          }),
                        );
                      },
                    ),

                    // ListTile(
                    //   leading: Text(
                    //     'Help Center',
                    //     style: TextStyle(
                    //         fontSize: 18, color: bDisabledColor),
                    //   ),
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (_) {
                    //             return HelpCenter();
                    //           },
                    //           fullscreenDialog: true),
                    //     );
                    //   },
                    // ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_providerId == "google.com") {
                          await googleSignIn.signOut();
                        }

                        FirebaseAuth.instance.signOut();

                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          bScaffoldBackgroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                child: Text(
                    'Version : ${_packageInfo.version} (${_packageInfo.buildNumber})',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
