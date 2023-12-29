import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: <Widget>[
        SizedBox(
          width: 250,
          height: 50,
          child: Image.asset('assets/icon.png'),
        ),
        const Text(
          'BHIMA Stock',
          style: TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        )
      ],
    ));
  }
}
