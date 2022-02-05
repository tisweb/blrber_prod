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

//Imports for Models
import '../models/user_detail.dart';

//Imports for Providers
import '../provider/get_current_location.dart';

//Imports for Screens
import '../screens/dashboard.dart';
import '../screens/edit_profile.dart';
import '../screens/customer_support.dart';
import '../screens/settings_screen.dart';

//Imports for Widgets
import '../widgets/display_product_catalog.dart';

class DisplayAdminProfile extends StatefulWidget {
  const DisplayAdminProfile({Key key}) : super(key: key);

  @override
  _DisplayAdminProfileState createState() => _DisplayAdminProfileState();
}

class _DisplayAdminProfileState extends State<DisplayAdminProfile> {
  List<UserDetail> userDetails = [];
  List<UserSubDetails> userSubDetails = [];
  List<AdminUser> adminUsers = [];
  List<Product> products = [];
  List<ProductOrder> productOrders = [];
  int prodCount = 0;
  int prodReceivedOrderCount = 0;
  int prodYourOrderCount = 0;
  User user;
  bool _displayMemberShip = false;
  GetCurrentLocation getCurrentLocation = GetCurrentLocation();
  String currentUserName = "";
  AdminUser adminUser = AdminUser();
  static const double flagHeight = 20.0;
  static const double flagWidth = 25.0;

  @override
  void didChangeDependencies() {
    userDetails = [];
    adminUsers = [];
    userDetails = Provider.of<List<UserDetail>>(context);
    userSubDetails = Provider.of<List<UserSubDetails>>(context);
    adminUsers = Provider.of<List<AdminUser>>(context);
    user = FirebaseAuth.instance.currentUser;
    getCurrentLocation = Provider.of<GetCurrentLocation>(context);
    products = Provider.of<List<Product>>(context);

    productOrders = Provider.of<List<ProductOrder>>(context);

    if (adminUsers.length > 0) {
      adminUsers =
          adminUsers.where((e) => e.userId.trim() == user.uid.trim()).toList();
    }

    if (userDetails.length > 0 && user != null) {
      userDetails = userDetails
          .where((e) => e.email.trim() == user.email.trim())
          .toList();
      if (userDetails.length > 0) {
        currentUserName = userDetails[0].userName;
        if (products.length > 0) {
          prodCount = products
              .where((e) =>
                  e.userDetailDocId == userDetails[0].userDetailDocId &&
                  e.status == 'Verified' &&
                  e.listingStatus == 'Available')
              .length;
        }
        if (productOrders.length > 0) {
          prodYourOrderCount = productOrders
              .where((e) => e.buyerUserId == userDetails[0].userDetailDocId)
              .length;

          prodReceivedOrderCount = productOrders
              .where((e) => e.sellerUserId == userDetails[0].userDetailDocId)
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

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return userDetails.length > 0
        ? SingleChildScrollView(
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
                  padding: EdgeInsets.only(left: 8),
                  color: bBackgroundColor,
                  child: Row(
                    children: [
                      // CircleAvatar(
                      //   radius: 25,
                      //   backgroundImage: userDetails[0].userImageUrl == ""
                      //       ? AssetImage('assets/images/default_user_image.png')
                      //       : NetworkImage(userDetails[0].userImageUrl),
                      // ),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bScaffoldBackgroundColor,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: userDetails[0].userImageUrl == ""
                                ? AssetImage(
                                    'assets/images/default_user_image.png')
                                : NetworkImage(userDetails[0].userImageUrl),
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
                              userDetails[0].displayName,
                              style: TextStyle(
                                  fontSize: 20, color: bDisabledColor),
                            ),
                            Text(
                              userDetails[0].userType,
                              style: TextStyle(
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
                      style: TextStyle(fontSize: 18, color: bDisabledColor),
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
                      style: TextStyle(fontSize: 18, color: bDisabledColor),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) {
                              return DisplayProductCatalog(
                                adminUserPermission: adminUsers[0].permission,
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
                                    userDocId: userDetails[0].userDetailDocId);
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
                                    userId: userDetails[0].userDetailDocId);
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
                                  userId: userDetails[0].userDetailDocId,
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
                                  userId: userDetails[0].userDetailDocId,
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
                      Icons.dashboard,
                      color: bPrimaryColor,
                    ),
                    title: const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 18, color: bDisabledColor),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) {
                              return Dashboard(
                                adminUserPermission: adminUsers[0].permission,
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
                Container(
                  color: bBackgroundColor,
                  child: ListTile(
                    leading: const Icon(
                      Icons.support_agent,
                      color: bPrimaryColor,
                    ),
                    title: const Text(
                      'Customer Support',
                      style: TextStyle(fontSize: 18, color: bDisabledColor),
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
                      style: TextStyle(fontSize: 18, color: bDisabledColor),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed(SettingsScreen.routeName);
                    },
                  ),
                ),
                const Divider(
                  thickness: 2,
                ),
              ],
            ),
          )
        : const Center(
            child: CupertinoActivityIndicator(),
          );
  }
}
