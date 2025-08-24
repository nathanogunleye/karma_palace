// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

/// A palette of colors to be used in the game.
///
/// The reason we're not going with something like Material Design's
/// `Theme` is simply that this is simpler to work with and yet gives
/// us everything we need for a game.
///
/// Games generally have more radical color palettes than apps. For example,
/// every level of a game can have radically different colors.
/// At the same time, games rarely support dark mode.
///
/// Updated palette to match the new logo design with a modern, sophisticated look
/// while maintaining the playful card game aesthetic.
///
/// Colors here are implemented as getters so that hot reloading works.
/// In practice, we could just as easily implement the colors
/// as `static const`. But this way the palette is more malleable:
/// we could allow players to customize colors, for example,
/// or even get the colors from the network.
class Palette {
  // Primary brand colors - can be adjusted based on your logo
  Color get pen => const Color(0xFFEF4444); // Red from logo as primary
  Color get darkPen => const Color(0xFFDC2626); // Darker red for emphasis
  Color get redPen => const Color(0xFFEF4444); // Modern red
  
  // Text colors - light for black background
  Color get inkFullOpacity => const Color(0xFFFFFFFF); // White
  Color get ink => const Color(0xEEFFFFFF); // White with transparency
  Color get cardInk => const Color(0xFF555555); // White with transparency

  // Input text color - dark for white input fields
  Color get inputText => const Color(0xFF1F2937); // Dark gray for input text
  
  // Success/acceptance color
  Color get accept => const Color(0xFF10B981); // Modern green
  
  // Background colors - black to match logo
  Color get backgroundMain => const Color(0xFF000000); // Black background
  Color get backgroundLevelSelection => const Color(0xFF000000); // Black background
  Color get backgroundPlaySession => const Color(0xFF000000); // Black background
  Color get background4 => const Color(0xFF000000); // Black background
  Color get backgroundSettings => const Color(0xFF000000); // Black background
  
  // Pure white for cards and highlights
  Color get trueWhite => const Color(0xFFFFFFFF);
}
