//Imports for pubspec Packages
import 'package:blrber/models/userSubDetails.dart';
import 'package:blrber/models/user_detail.dart';
import 'package:blrber/screens/edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

//Imports for Screens
import '../screens/auth_screen_new.dart';

//Imports for Widgets
import '../widgets/post_input_form.dart';

//Imports for Constants
import '../constants.dart';

class GeneratePost extends StatefulWidget {
  static const routeName = '/generate-post';

  @override
  _GeneratePostState createState() => _GeneratePostState();
}

class _GeneratePostState extends State<GeneratePost> {
  List<UserSubDetails> userSubDetails = [];
  List<UserDetail> userDetails = [];
  bool _userCanPost = false;
  bool _isProfileUpdated = false;

  @override
  void didChangeDependencies() {
    _initialDataLoad();
    super.didChangeDependencies();
  }

  _initialDataLoad() {
    userSubDetails = Provider.of<List<UserSubDetails>>(context);
    userDetails = Provider.of<List<UserDetail>>(context);
  }

  _checkUserSub(String userId) {
    if (userSubDetails.length > 0) {
      userSubDetails = userSubDetails.where((e) => e.userId == userId).toList();
      if (userSubDetails.length == 0) {
        _userCanPost = true;
      } else if (userSubDetails.length > 0 &&
          userSubDetails[0].paidStatus != "Unpaid") {
        _userCanPost = true;
      } else {
        _userCanPost = false;
      }
    }
    if (userDetails.length > 0) {
      userDetails = userDetails
          .where((e) => e.userDetailDocId.trim() == userId.trim())
          .toList();
      if (userDetails.length > 0) {
        _isProfileUpdated = userDetails[0].isProfileUpdated;
      }
    }
  }

  void showAlertDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text("Start Order?"),
            content: Text("Please update your profile with contact info!"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Generate Post',
          style: TextStyle(
              color: bDisabledColor, fontWeight: FontWeight.w600, fontSize: 25),
        ),
        elevation: 0.0,
        backgroundColor: bBackgroundColor,
      ),
      backgroundColor: bBackgroundColor,
      body: Container(
        child: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: 0,
                  height: 0,
                );
              }
              if (userSnapshot.hasData) {
                var user = FirebaseAuth.instance.currentUser;
                _checkUserSub(user.uid);
                if (_userCanPost) {
                  return PostInputForm(
                      // editPost: 'false',
                      );
                } else {
                  return Center(
                    child: Text(
                        "User\'s Plan expired!! Please renew to post ad.."),
                  );
                }
              }
              // return AuthScreen();
              return AuthScreenNew();
            }),
      ),
    );
  }
}
