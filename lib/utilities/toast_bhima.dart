import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

handleError(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.red[500],
      textColor: Colors.white,
      fontSize: 16);
}

handleSuccess(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromARGB(255, 62, 197, 131),
      textColor: Colors.white,
      fontSize: 16);
}
