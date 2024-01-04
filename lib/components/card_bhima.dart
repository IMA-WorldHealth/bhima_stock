import 'dart:core';
import 'package:flutter/material.dart';

// The card custom

class CardBhima extends StatelessWidget {
  const CardBhima(
      {super.key,
      this.height = 100,
      this.width = 300,
      required this.child,
      this.onTap,
      this.color,
      this.shadowColor,
      this.surfaceTintColor,
      this.elevation,
      this.shape,
      this.borderOnForeground = true,
      this.margin,
      this.clipBehavior,
      this.semanticContainer = true});

  final Widget child;
  final void Function()? onTap;
  final double height;
  final double width;
  final Color? color;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final bool semanticContainer;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
      shape: shape,
      borderOnForeground: borderOnForeground,
      semanticContainer: semanticContainer,
      clipBehavior: clipBehavior,
      child: InkWell(
        splashColor: const Color.fromARGB(255, 255, 255, 255).withAlpha(30),
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
    );
  }
}
