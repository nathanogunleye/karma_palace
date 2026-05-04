// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<String> soundTypeToFilename(SfxType type) => switch (type) {
      SfxType.huhsh => const [
          'sfx/hash1.mp3',
          'sfx/hash2.mp3',
          'sfx/hash3.mp3',
        ],
      SfxType.wssh => const [
          'sfx/wssh1.mp3',
          'sfx/wssh2.mp3',
          'sfx/dsht1.mp3',
          'sfx/ws1.mp3',
          'sfx/spsh1.mp3',
          'sfx/hh1.mp3',
          'sfx/hh2.mp3',
          'sfx/kss1.mp3',
        ],
      SfxType.buttonTap => const [
          'sfx/k1.mp3',
          'sfx/k2.mp3',
          'sfx/p1.mp3',
          'sfx/p2.mp3',
        ],
      SfxType.congrats => const [
          'sfx/yay1.mp3',
          'sfx/wehee1.mp3',
          'sfx/oo1.mp3',
        ],
      SfxType.erase => const [
          'sfx/fwfwfwfwfw1.mp3',
          'sfx/fwfwfwfw1.mp3',
        ],
      SfxType.swishSwish => const [
          'sfx/swishswish1.mp3',
        ],
      SfxType.wrongAnswer => const [
          'audio/wrong_answer.mp3',
        ],
      SfxType.faaah => const [
          'audio/faaah.mp3',
        ],
      SfxType.takingPlayingCard => const [
          'audio/taking_playing_card.mp3',
          'audio/taking_playing_card_2.mp3',
          'audio/taking_playing_card_3.mp3',
        ],
      SfxType.vineBoom => const [
          'audio/vine_boom.mp3',
        ],
    };

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.huhsh:
      return 0.4;
    case SfxType.wssh:
      return 0.2;
    case SfxType.buttonTap:
    case SfxType.congrats:
    case SfxType.erase:
    case SfxType.swishSwish:
    case SfxType.wrongAnswer:
    case SfxType.faaah:
    case SfxType.takingPlayingCard:
    case SfxType.vineBoom:
      return 1.0;
  }
}

enum SfxType {
  huhsh,
  wssh,
  buttonTap,
  congrats,
  erase,
  swishSwish,
  wrongAnswer,
  faaah,
  takingPlayingCard,
  vineBoom,
}
