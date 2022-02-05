import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:async';

/// Information about the app's current version, and the most recent version
/// available in the Apple App Store or Google Play Store.
class VersionStatus {
  /// True if the there is a more recent version of the app in the store.
  bool canUpdate;

  /// The current version of the app.
  String localVersion;

  /// This field is added by Blrber
  String localBuild;

  /// The most recent version of the app in the store.
  String storeVersion;

  /// This field is added by Blrber
  String storeBuild;

  /// A link to the app store page where the app can be updated.
  String appStoreLink;

  VersionStatus(
      {this.canUpdate,
      this.localVersion,
      this.localBuild,
      this.storeVersion,
      this.storeBuild});
}

class NewVersionCheck {
  /// This is required to check the user's platform and display alert dialogs.
  BuildContext context;

  /// An optional value that can override the default packageName when
  /// attempting to reach the Google Play Store. This is useful if your app has
  /// a different package name in the Play Store for some reason.
  String androidId;

  /// An optional value that can override the default packageName when
  /// attempting to reach the Apple App Store. This is useful if your app has
  /// a different package name in the App Store for some reason.
  String iOSId;

  /// This field is added by Blrber
  String storeVersion;

  /// This field is added by Blrber
  String storeBuild;

  /// An optional value that can override the default callback to dismiss button
  VoidCallback dismissAction;

  /// An optional value that can override the default text to alert,
  /// you can ${versionStatus.localVersion} to ${versionStatus.storeVersion}
  /// to determinate in the text a versions.
  String dialogText;

  /// An optional value that can override the default title of alert dialog
  String dialogTitle;

  /// An optional value that can override the default text of dismiss button
  String dismissText;

  /// An optional value that can override the default text of update button
  String updateText;

  NewVersionCheck({
    this.androidId,
    this.iOSId,
    this.storeVersion,
    this.storeBuild,
    @required this.context,
    this.dismissAction,
    this.dismissText: 'Later',
    this.updateText: 'Update',
    this.dialogText,
    this.dialogTitle: 'Update Available',
  }) : assert(context != null);

  /// This checks the version status, then displays a platform-specific alert
  /// with buttons to dismiss the update alert, or go to the app store.
  showAlertIfNecessary() async {
    VersionStatus versionStatus = await getVersionStatus();
    if (versionStatus != null && versionStatus.canUpdate) {
      showUpdateDialog(versionStatus);
    }
  }

  /// This checks the version status and returns the information. This is useful
  /// if you want to display a custom alert, or use the information in a different
  /// way.
  Future<VersionStatus> getVersionStatus() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    VersionStatus versionStatus = VersionStatus(
      localVersion: packageInfo.version,
      localBuild: packageInfo.buildNumber,
    );
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
        final id = androidId ?? packageInfo.packageName;
        versionStatus = await _getAndroidStoreVersion(id, versionStatus);
        break;
      case TargetPlatform.iOS:
        final id = iOSId ?? packageInfo.packageName;
        versionStatus = await _getiOSStoreVersion(id, versionStatus);
        break;
      default:
        print('This target platform is not yet supported by this package.');
    }
    if (versionStatus == null) {
      return null;
    }

    versionStatus.storeVersion = storeVersion;
    versionStatus.storeBuild = storeBuild;

    print("versionStatus.storeVersion - ${versionStatus.storeVersion}");
    print("versionStatus.localVersion - ${versionStatus.localVersion}");
    print("versionStatus.storeBuild - ${versionStatus.storeBuild}");
    print("versionStatus.localBuild - ${versionStatus.localBuild}");

    String storeVersionNum = versionStatus.storeVersion.replaceAll(".", "");
    String localVersionNum = versionStatus.localVersion.replaceAll(".", "");
    versionStatus.canUpdate =
        int.parse(storeVersionNum) > int.parse(localVersionNum) ||
            double.parse(versionStatus.storeBuild) >
                double.parse(versionStatus.localBuild);

    return versionStatus;
  }

  /// iOS info is fetched by using the iTunes lookup API, which returns a
  /// JSON document.
  _getiOSStoreVersion(String id, VersionStatus versionStatus) async {
    final url = 'https://itunes.apple.com/lookup?bundleId=$id';
    final response = await http.get(url);
    if (response.statusCode != 200) {
      print('Can\'t find an app in the App Store with the id: $id');
      return null;
    }
    final jsonObj = json.decode(response.body);
    versionStatus.storeVersion = jsonObj['results'][0]['version'];
    versionStatus.appStoreLink = jsonObj['results'][0]['trackViewUrl'];
    return versionStatus;
  }

  /// Android info is fetched by parsing the html of the app store page.
  _getAndroidStoreVersion(String id, VersionStatus versionStatus) async {
    final url = 'https://play.google.com/store/apps/details?id=$id';
    final response = await http.get(url);
    if (response.statusCode != 200) {
      print('Can\'t find an app in the Play Store with the id: $id');
      return null;
    }
    final document = parse(response.body);
    final elements = document.getElementsByClassName('hAyfc');
    final versionElement = elements.firstWhere(
      (elm) => elm.querySelector('.BgcNfc').text == 'Current Version',
    );
    versionStatus.storeVersion = versionElement.querySelector('.htlgb').text;
    versionStatus.appStoreLink = url;
    return versionStatus;
  }

  /// Shows the user a platform-specific alert about the app update. The user
  /// can dismiss the alert or proceed to the app store.
  void showUpdateDialog(VersionStatus versionStatus) async {
    final title = Text(dialogTitle);
    final content = Text(
      this.dialogText ??
          'You can now update this app from ${versionStatus.localVersion}(${versionStatus.localBuild}) to ${versionStatus.storeVersion}(${versionStatus.storeBuild})',
    );
    final dismissText = Text(this.dismissText);
    final dismissAction = this.dismissAction ??
        () => Navigator.of(context, rootNavigator: true).pop();
    final updateText = Text(this.updateText);
    final updateAction = () {
      _launchAppStore(versionStatus.appStoreLink);
      Navigator.of(context, rootNavigator: true).pop();
    };
    final platform = Theme.of(context).platform;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return platform == TargetPlatform.android
            ? AlertDialog(
                title: title,
                content: content,
                actions: <Widget>[
                  FlatButton(
                    child: dismissText,
                    onPressed: dismissAction,
                  ),
                  FlatButton(
                    child: updateText,
                    onPressed: updateAction,
                  ),
                ],
              )
            : CupertinoAlertDialog(
                title: title,
                content: content,
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: dismissText,
                    onPressed: dismissAction,
                  ),
                  CupertinoDialogAction(
                    child: updateText,
                    onPressed: updateAction,
                  ),
                ],
              );
      },
    );
  }

  /// Launches the Apple App Store or Google Play Store page for the app.
  void _launchAppStore(String appStoreLink) async {
    if (await canLaunch(appStoreLink)) {
      await launch(appStoreLink);
    } else {
      throw 'Could not launch appStoreLink';
    }
  }
}
