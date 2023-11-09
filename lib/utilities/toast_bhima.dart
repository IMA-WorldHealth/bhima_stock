import 'package:flutter/material.dart';
import 'package:flutter_toastify/components/enums.dart' as enums;
import 'package:flutter_toastify/flutter_toastify.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

handleError(String msg, BuildContext context) {
  FlutterToastify.success(
    width: 360,
    notificationPosition: enums.NotificationPosition.topLeft,
    animation: enums.AnimationType.fromTop,
    title: const Text('Success'),
    description: Text(msg),
    background: const Color.fromARGB(255, 205, 63, 63),
    onDismiss: () {},
  ).show(context);
  // Fluttertoast.showToast(
  //     msg: msg,
  //     toastLength: Toast.LENGTH_LONG,
  //     gravity: ToastGravity.TOP,
  //     timeInSecForIosWeb: 3,
  //     backgroundColor: Colors.red[500],
  //     textColor: Colors.white,
  //     fontSize: 16);
}

handleSuccess(String msg, BuildContext context) {
  FlutterToastify.success(
    width: 360,
    notificationPosition: enums.NotificationPosition.topLeft,
    animation: enums.AnimationType.fromRight,
    title: const Text('Success'),
    description: Text(msg),
    background: const Color.fromARGB(255, 63, 205, 170),
    onDismiss: () {},
  ).show(context);
  // Fluttertoast.showToast(
  //     msg: msg,
  //     toastLength: Toast.LENGTH_LONG,
  //     gravity: ToastGravity.TOP,
  //     timeInSecForIosWeb: 1,
  //     backgroundColor: const Color.fromARGB(255, 62, 197, 131),
  //     textColor: Colors.white,
  //     fontSize: 16);
}

alertError(BuildContext context, String msg) {
  Alert(
    context: context,
    type: AlertType.error,
    title: "Erreur",
    desc: msg,
    closeFunction: () => Navigator.pop(context),
    buttons: [
      DialogButton(
        onPressed: () => Navigator.pop(context),
        color: const Color.fromARGB(255, 179, 0, 42),
        radius: BorderRadius.circular(0.0),
        child: const Text(
          "Fermer",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    ],
  ).show();
}

alertSuccess(BuildContext context, String msg) {
  Alert(
    context: context,
    type: AlertType.success,
    closeFunction: () => Navigator.pop(context),
    title: "Success",
    desc: msg,
    buttons: [
      DialogButton(
        onPressed: () => Navigator.pop(context),
        color: const Color.fromARGB(255, 24, 179, 0),
        radius: BorderRadius.circular(0.0),
        child: const Text(
          "Fermer",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    ],
  ).show();
}
