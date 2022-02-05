import 'package:blrber/constants.dart';
import 'package:flutter/material.dart';

import '../widgets/auth/auth_form_new.dart';

class AuthScreenNew extends StatefulWidget {
  const AuthScreenNew({Key key}) : super(key: key);

  @override
  _AuthScreenNewState createState() => _AuthScreenNewState();
}

class _AuthScreenNewState extends State<AuthScreenNew> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bBackgroundColor,
      body: AuthFormNew(),
    );
  }
}
