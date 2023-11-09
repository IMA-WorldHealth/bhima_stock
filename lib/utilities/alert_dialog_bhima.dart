import 'package:flutter/material.dart';

alertSuccess(String message, BuildContext context) {
  return showDialog(
      context: context,
      builder: ((context) => AlertDialog(
            title: const Text('Success'),
            content: Column(
              children: <Widget>[
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.green,
                ),
                Text(message,
                    style: const TextStyle(fontSize: 18, color: Colors.green))
              ],
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Fermer'))
            ],
          )));
}

alertError(String message, BuildContext context) {
  return showDialog(
      context: context,
      builder: ((context) => AlertDialog(
            title: const Text('Error'),
            content: Column(
              children: <Widget>[
                const Icon(
                  Icons.dangerous,
                  size: 20,
                  color: Colors.red,
                ),
                Text(message,
                    style: TextStyle(fontSize: 18, color: Colors.red[200]))
              ],
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Fermer'))
            ],
          )));
}
