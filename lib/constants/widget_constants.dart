import 'package:flutter/material.dart';

// Image appIcon = Image.asset('assets/images/ise_icon_no_bg.png');

const Color kBackgroundColor = Color(0xFFFF7600);

// const TextStyle kListTextStyle = TextStyle(
//   fontSize: 30.0,
// );

// TextStyle Function({bool isBold}) listTextStyleWithOptions =
//     ({bool isBold = false}) {
//   return TextStyle(
//     fontSize: 30.0,
//     fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//   );
// };

FloatingActionButton Function(BuildContext) backFloatingActionButton =
    (BuildContext context) {
  return FloatingActionButton(
    child: const Icon(Icons.arrow_back_rounded),
    onPressed: () => Navigator.pop(context),
  );
};
