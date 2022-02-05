//Imports for pubspec Packages
import 'package:blrber/helpers/ad_helper.dart';
import 'package:blrber/services/local_notification_service.dart';
import 'package:blrber/services/new_version_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

// Imports for Constants
import '../constants.dart';

// Imports for Models
import '../models/message.dart';
import '../models/user_detail.dart';

// Imports for Screens
import '../screens/explore_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/generate_post.dart';
import '../screens/user_shop_screen.dart';

// Imports for Services
import '../services/foundation.dart';

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
    print(data);
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
    print(notification);
  }

  // Or do other work.
}

class TabsScreen extends StatefulWidget {
  final int selectPageIndex;
  TabsScreen(
    this.selectPageIndex,
  );
  @override
  _TabsScreenState createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  List<dynamic> _tabs;
  int _selectPageIndex = 0;
  List<ReceivedMsgCount> receivedMsgCounts = [];

  String currentUserName = "";
  User user;
  UserDetail userData;
  int totalNewMsgCount = 0;
  final fcm = FirebaseMessaging();
  BannerAd _bottomBannerAd;
  bool _isBottomBannerAdLoaded = false;

  void _createBottomBannerAd() {
    _bottomBannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: AdHelper.bannerAdUnitId,
      listener: BannerAdListener(onAdLoaded: (_) {
        setState(() {
          _isBottomBannerAdLoaded = true;
        });
      }, onAdFailedToLoad: (ad, error) {
        ad.dispose();
      }),
      request: AdRequest(),
    );
    _bottomBannerAd.load();
  }

  @override
  void initState() {
    _selectPageIndex = widget.selectPageIndex;
    _tabs = [
      ExploreScreen(),
      FavoritesScreen(),
      GeneratePost(),
      ChatScreen(),
      ProfileScreen(),
    ];
    initDynamicLinks(context);
    _createBottomBannerAd();

    _checkVersion();

    fcm.requestNotificationPermissions();

    fcm.configure(
      onMessage: (message) {
        print("check onMessage Tab Screen");
        print(message);
        DialogBox("Notification", message, context, () {
          Navigator.pop(context);
        });
        LocalNotificationService.display(message);
        // final snackBar = SnackBar(
        //   content: Text(message['notification']['title'] +
        //       '-' +
        //       message['notification']['body']),
        // );
        // ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (message) {
        print("check onLaunch Tab Screen");
        print(message);
        return;
      },
      onResume: (message) {
        print("check onResume Tab Screen");
        print(message);
        return;
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _bottomBannerAd.dispose();
  }

  void DialogBox(
      String Title, Map<String, dynamic> message, context, Function action) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            backgroundColor: bBackgroundColor,
            title: Text(
              Title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[800], fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  message['notification']['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  message['notification']['body'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
                onPressed: action,
              ),
            ],
          );
        });
  }

// To Check version of the app
  Future<void> _checkVersion() async {
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

      await newVersionCheck.showAlertIfNecessary();
    });
  }

// To handel dynamic links
  Future<void> initDynamicLinks(BuildContext context) async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      // print("Deep link1 - ${deepLink.toString()}");
      print("Deep link1");

      if (deepLink != null) {
        var view = '${deepLink.queryParameters["view"]}';
        var routeName = '/$view';
        var id = '${deepLink.queryParameters["id"]}';
        // print('routeName - ${routeName}');
        // print('id link1- ${id}');

        if (view == "UserShopScreen") {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) {
                  return UserShopScreen(userDocId: id);
                },
                fullscreenDialog: true),
          );
        } else {
          Navigator.of(context).pushNamed(routeName, arguments: id);
        }
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();

    final Uri deepLink = data?.link;

    print("Deep link2");
    if (deepLink != null) {
      var view = '${deepLink.queryParameters["view"]}';
      var routeName = '/$view';
      var id = '${deepLink.queryParameters["id"]}';

      // print('id link2 - ${id}');

      if (view == "UserShopScreen") {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) {
                return UserShopScreen(userDocId: id);
              },
              fullscreenDialog: true),
        );
      } else {
        Navigator.of(context).pushNamed(routeName, arguments: id);
      }
    }
  }

  //

  void _selectPage(int index) {
    setState(() {
      _selectPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<ReceivedMsgCount> receivedMsgCounts =
        Provider.of<List<ReceivedMsgCount>>(context);

    final _bottomNavigationBarItems = [
      const BottomNavigationBarItem(
        icon: const Icon(Icons.explore),
        label: 'Explore',
      ),
      const BottomNavigationBarItem(
        icon: const Icon(Icons.favorite),
        label: 'Favorites',
      ),
      const BottomNavigationBarItem(
        icon: const Icon(Icons.add_box),
        label: 'Sell',
      ),
      BottomNavigationBarItem(
        icon: StreamBuilder<Object>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                user = FirebaseAuth.instance.currentUser;
                List<UserDetail> userDetails =
                    Provider.of<List<UserDetail>>(context);

                if (userDetails.length > 0 && user != null) {
                  // UserDetail userDetailsCU = UserDetail();

                  var userDetail = userDetails
                      .where((e) => e.email.trim() == user.email.trim())
                      .toList();

                  if (userDetail.length > 0) {
                    receivedMsgCounts = receivedMsgCounts
                        .where((e) =>
                            e.receivedUserName.trim() ==
                            userDetail[0].userName.trim())
                        .toList();
                    if (receivedMsgCounts.length > 0) {
                      totalNewMsgCount = 0;
                      for (int i = 0; i < receivedMsgCounts.length; i++) {
                        totalNewMsgCount = totalNewMsgCount +
                            receivedMsgCounts[i].receivedMsgCount;
                      }
                    }
                  } else {
                    totalNewMsgCount = 0;
                    // Following signOut is to sign out the user if he is deleted from the firebase manually.
                    // But it is not allowed to deleted the user manually if he is logged in.
                    // FirebaseAuth.instance.signOut();
                  }
                }
                return Stack(
                  children: [
                    const Icon(
                      Icons.chat,
                    ),
                    if (totalNewMsgCount > 0)
                      Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(
                            Icons.notifications,
                            color: Colors.red,
                            size: 20,
                          ))
                    // Positioned(
                    //   left: 0,
                    //   top: 0,
                    //   child: Container(
                    //     height: 22,
                    //     width: 22,
                    //     child: Badge(
                    //       child: Icon(Icons.notifications),
                    //       // badgeContent: Text(
                    //       //   totalNewMsgCount.toString(),
                    //       //   style: TextStyle(
                    //       //       color: bBackgroundColor, fontSize: 9),
                    //       // ),
                    //       // badgeColor: Colors.red,
                    //     ),
                    //   ),
                    // )
                  ],
                );
              } else {
                return const Icon(Icons.chat);
              }
            }),
        label: 'Chat',
      ),
      const BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: 'My Blrber',
      ),
    ];
    final _bottomNavigationBar = BottomNavigationBar(
      onTap: _selectPage,
      unselectedItemColor: bDisabledColor,
      selectedItemColor: bPrimaryColor,
      backgroundColor: bBackgroundColor,
      currentIndex: _selectPageIndex,
      // currentIndex: widget.selectPageIndex,
      type: BottomNavigationBarType.fixed,
      items: _bottomNavigationBarItems,
      elevation: 0.0,
    );
    return isIos
        ? CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
              activeColor: bPrimaryColor,
              inactiveColor: bDisabledColor,
              backgroundColor: bBackgroundColor,
              currentIndex: widget.selectPageIndex,
              items: _bottomNavigationBarItems,
            ),
            tabBuilder: (BuildContext context, int index) {
              switch (index) {
                case 0:
                  return ExploreScreen();
                case 1:
                  return FavoritesScreen();
                case 2:
                  return GeneratePost();
                case 3:
                  return ChatScreen();
                case 4:
                  return ProfileScreen();
                default:
                  return ExploreScreen();
              }
            },
          )
        : Scaffold(
            body: _tabs[_selectPageIndex],
            // persistentFooterButtons: [
            //   _isBottomBannerAdLoaded
            //       ? Container(
            //           height: _bottomBannerAd.size.height.toDouble(),
            //           width: _bottomBannerAd.size.width.toDouble(),
            //           child: AdWidget(
            //             ad: _bottomBannerAd,
            //           ),
            //         )
            //       : Container(),
            // ],
            bottomNavigationBar: _bottomNavigationBar,
          );
  }
}
