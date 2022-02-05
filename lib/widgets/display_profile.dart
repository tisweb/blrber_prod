//Imports for pubspec Packages
import 'package:blrber/models/product.dart';
import 'package:blrber/models/product_order.dart';
import 'package:blrber/models/userSubDetails.dart';
import 'package:blrber/screens/membership.dart';
import 'package:blrber/screens/product_order_list.dart';
import 'package:blrber/screens/user_shop_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag/flag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Imports for Constants
import '../constants.dart';

//Imports for Widgets
import './display_product_catalog.dart';

//Imports for Models
import '../models/user_detail.dart';

//Imports for Provider
import '../provider/get_current_location.dart';

//Imports for Screens
import '../screens/edit_profile.dart';
import '../screens/customer_support.dart';
import '../screens/settings_screen.dart';

class DisplayProfile extends StatefulWidget {
  @override
  _DisplayProfileState createState() => _DisplayProfileState();
}

class _DisplayProfileState extends State<DisplayProfile> {
  List<UserDetail> userDetails = [];
  List<UserSubDetails> userSubDetails = [];
  List<Product> products = [];
  List<ProductOrder> productOrders = [];
  int prodCount = 0;
  int prodReceivedOrderCount = 0;
  int prodYourOrderCount = 0;
  User user;
  bool _displayMemberShip = false;
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();
  String currentUserName = "";
  List<UserDetail> userDetailsCU = [];
  bool _initialData = false;

  static const double flagHeight = 20.0;
  static const double flagWidth = 25.0;

  @override
  void didChangeDependencies() {
    userDetails = Provider.of<List<UserDetail>>(context);
    userSubDetails = Provider.of<List<UserSubDetails>>(context);
    getCurrentLocation = Provider.of<GetCurrentLocation>(context);
    products = Provider.of<List<Product>>(context);

    productOrders = Provider.of<List<ProductOrder>>(context);

    user = FirebaseAuth.instance.currentUser;

    _initialData = false;

    if (userDetails != null) {
      if (userDetails.length > 0 && user != null) {
        userDetailsCU = [];
        userDetailsCU = userDetails
            .where((e) => e.userDetailDocId.trim() == user.uid.trim())
            .toList();
        if (userDetailsCU.length > 0) {
          currentUserName = userDetailsCU[0].userName;
          _initialData = true;
          if (products.length > 0) {
            prodCount = products
                .where((e) =>
                    e.userDetailDocId == userDetailsCU[0].userDetailDocId &&
                    e.status == 'Verified' &&
                    e.listingStatus == 'Available')
                .length;
          }
          if (productOrders.length > 0) {
            prodYourOrderCount = productOrders
                .where((e) => e.buyerUserId == userDetailsCU[0].userDetailDocId)
                .length;

            prodReceivedOrderCount = productOrders
                .where(
                    (e) => e.sellerUserId == userDetailsCU[0].userDetailDocId)
                .length;
          }
        }
        if (userSubDetails.length > 0) {
          userSubDetails = userSubDetails
              .where((e) => e.userId.trim() == user.uid.trim())
              .toList();
          if (userSubDetails.length > 0) {
            if (userSubDetails[0].planName != "Free") {
              _displayMemberShip = true;
            }
          }
        }
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _initialData
        ? SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Container(
                    color: bBackgroundColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flag(
                          getCurrentLocation.countryCode,
                          height: flagHeight,
                          width: flagWidth,
                          fit: BoxFit.fill,
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(SettingsScreen.routeName);
                          },
                        )
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: bBackgroundColor,
                    child: Row(
                      children: [
                        // CircleAvatar(
                        //   radius: 25,
                        //   backgroundImage: userDetailsCU[0].userImageUrl == ""
                        //       ? AssetImage('assets/images/default_user_image.png')
                        //       : NetworkImage(userDetailsCU[0].userImageUrl),
                        // ),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bScaffoldBackgroundColor,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: userDetailsCU[0].userImageUrl == ""
                                  ? AssetImage(
                                      'assets/images/default_user_image.png')
                                  : NetworkImage(userDetailsCU[0].userImageUrl),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                userDetailsCU[0].displayName,
                                style: const TextStyle(
                                    fontSize: 20, color: bDisabledColor),
                              ),
                              Text(
                                userDetailsCU[0].userType,
                                style: const TextStyle(
                                    fontSize: 15, color: bDisabledColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                  Container(
                    color: bBackgroundColor,
                    child: ListTile(
                      leading: const Icon(
                        Icons.edit,
                        color: bPrimaryColor,
                      ),
                      title: const Text(
                        'Update Profile',
                        style: const TextStyle(
                            fontSize: 18, color: bDisabledColor),
                      ),
                      onTap: () {
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
                  const Divider(
                    thickness: 2,
                  ),
                  Container(
                    color: bBackgroundColor,
                    child: ListTile(
                      leading: const Icon(
                        Icons.category_outlined,
                        color: bPrimaryColor,
                      ),
                      title: const Text(
                        'Product Catalog',
                        style: const TextStyle(
                            fontSize: 18, color: bDisabledColor),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) {
                                return DisplayProductCatalog(
                                  adminUserPermission: '',
                                );
                              },
                              fullscreenDialog: true),
                        );
                      },
                    ),
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                  if (prodCount > 0)
                    Container(
                      color: bBackgroundColor,
                      child: ListTile(
                        leading: const Icon(
                          Icons.shop_outlined,
                          color: bPrimaryColor,
                        ),
                        title: const Text(
                          'eShop',
                          style: TextStyle(fontSize: 18, color: bDisabledColor),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) {
                                  return UserShopScreen(
                                      userDocId:
                                          userDetailsCU[0].userDetailDocId);
                                },
                                fullscreenDialog: true),
                          );
                        },
                      ),
                    ),
                  if (prodCount > 0)
                    const Divider(
                      thickness: 2,
                    ),
                  if (prodCount > 0 && _displayMemberShip)
                    Container(
                      color: bBackgroundColor,
                      child: ListTile(
                        leading: const Icon(
                          Icons.card_membership,
                          color: bPrimaryColor,
                        ),
                        title: const Text(
                          'Membership',
                          style: TextStyle(fontSize: 18, color: bDisabledColor),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) {
                                  return Membership(
                                      userId: userDetailsCU[0].userDetailDocId);
                                },
                                fullscreenDialog: true),
                          );
                        },
                      ),
                    ),
                  if (prodCount > 0 && _displayMemberShip)
                    const Divider(
                      thickness: 2,
                    ),
                  if (prodYourOrderCount > 0)
                    Container(
                      color: bBackgroundColor,
                      child: ListTile(
                        leading: const Icon(
                          Icons.outbox_outlined,
                          color: bPrimaryColor,
                        ),
                        title: const Text(
                          'Ordered Products',
                          style: TextStyle(fontSize: 18, color: bDisabledColor),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) {
                                  return ProductOrderList(
                                    userId: userDetailsCU[0].userDetailDocId,
                                    displayType: "OP",
                                  );
                                },
                                fullscreenDialog: true),
                          );
                        },
                      ),
                    ),
                  if (prodYourOrderCount > 0)
                    const Divider(
                      thickness: 2,
                    ),
                  if (prodReceivedOrderCount > 0)
                    Container(
                      color: bBackgroundColor,
                      child: ListTile(
                        leading: const Icon(
                          Icons.inbox_outlined,
                          color: bPrimaryColor,
                        ),
                        title: const Text(
                          'Received Orders',
                          style: TextStyle(fontSize: 18, color: bDisabledColor),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) {
                                  return ProductOrderList(
                                    userId: userDetailsCU[0].userDetailDocId,
                                    displayType: "RO",
                                  );
                                },
                                fullscreenDialog: true),
                          );
                        },
                      ),
                    ),
                  if (prodReceivedOrderCount > 0)
                    const Divider(
                      thickness: 2,
                    ),
                  Container(
                    color: bBackgroundColor,
                    child: ListTile(
                      leading: const Icon(
                        Icons.support_agent,
                        color: bPrimaryColor,
                      ),
                      title: const Text(
                        'Customer Support',
                        style: const TextStyle(
                            fontSize: 18, color: bDisabledColor),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) {
                                return CustomerSupport();
                              },
                              fullscreenDialog: true),
                        );
                      },
                    ),
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                  Container(
                    color: bBackgroundColor,
                    child: ListTile(
                      leading: const Icon(
                        Icons.settings,
                        color: bPrimaryColor,
                      ),
                      title: const Text(
                        'Settings',
                        style: const TextStyle(
                            fontSize: 18, color: bDisabledColor),
                      ),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(SettingsScreen.routeName);
                      },
                    ),
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                ],
              ),
            ),
          )
        : const Center(
            child: CupertinoActivityIndicator(),
          );
  }
}
