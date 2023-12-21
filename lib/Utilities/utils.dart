import 'dart:developer';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class Utils{
  static Future<bool> checkInternetConnection(BuildContext buildContext) async{
    var result = await Connectivity().checkConnectivity();
    if(result!= ConnectivityResult.mobile && result != ConnectivityResult.wifi){
      displaySnack("Internet connection is not available. Check your connection and try again!", buildContext);
      return false;
    }
    return true;
  }

  static displaySnack(String messageText, BuildContext buildContext){
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(buildContext).showSnackBar(snackBar);
  }

  static displayToast(String messageText, BuildContext buildContext, {Toast? toastLength = Toast.LENGTH_SHORT, ToastGravity? gravity, Color? backgroundColor, Color? textColor, double? fontSize}){
    Fluttertoast.showToast(
      msg: messageText,
      toastLength: toastLength,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.blueAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    FlutterPhoneDirectCaller.callNumber(phoneNumber);
  }


  static toRadians(double degree){
    return degree * (pi/180);
  }

  static String formatDate(DateTime date){
    return DateFormat('E dd-MM-yyyy').format(date);
  }

}