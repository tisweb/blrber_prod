import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UpdateProduct {
  Future<void> updatePostNoOfDays(
      String prodDocId, String listingStatus) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(prodDocId)
        .update({'listingStatus': listingStatus})
        .then((value) => print("product Listing Status Updated"))
        .catchError((error) => print("Failed to update product: $error"));
  }

  static Future<String> supdatePostNoOfDays() async {
    var connectivityStatus = "";
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      // I am connected to a mobile network.
      try {
        final result = await InternetAddress.lookup('example.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('Connected to Mobile Internet');
          connectivityStatus = "MobileInternet";
        }
      } on SocketException catch (_) {
        print('not connected');
        connectivityStatus = "NoConnectivity";
      }
    } else if (connectivityResult == ConnectivityResult.wifi) {
      // I am connected to a wifi network.
      try {
        final result = await InternetAddress.lookup('example.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('Connected to Wifi Internet');
          connectivityStatus = "WifiInternet";
        }
      } on SocketException catch (_) {
        print('not connected - $connectivityResult');
        connectivityStatus = "NoConnectivity";
      }
    } else if (connectivityResult == ConnectivityResult.none) {
      print('not connected - $connectivityResult');
      connectivityStatus = "NoConnectivity";
    } else {
      print('not connected - $connectivityResult');
      connectivityStatus = "NoConnectivity";
    }

    return connectivityStatus;
  }
}
