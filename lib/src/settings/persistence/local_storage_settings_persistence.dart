// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_persistence.dart';

/// An implementation of [SettingsPersistence] that uses
/// `package:shared_preferences`.
class LocalStorageSettingsPersistence extends SettingsPersistence {
  final Future<SharedPreferences> instanceFuture =
      SharedPreferences.getInstance();

  @override
  Future<bool> getAudioOn({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('audioOn') ?? defaultValue;
  }

  @override
  Future<bool> getMusicOn({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('musicOn') ?? defaultValue;
  }

  @override
  Future<String> getPlayerName() async {
    final prefs = await instanceFuture;
    return prefs.getString('playerName') ?? 'Player';
  }

  @override
  Future<bool> getSoundsOn({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('soundsOn') ?? defaultValue;
  }

  @override
  Future<bool> getHapticsOn({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('hapticsOn') ?? defaultValue;
  }

  @override
  Future<void> saveAudioOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('audioOn', value);
  }

  @override
  Future<void> saveMusicOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('musicOn', value);
  }

  @override
  Future<void> savePlayerName(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('playerName', value);
  }

  @override
  Future<void> saveSoundsOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('soundsOn', value);
  }

  @override
  Future<void> saveHapticsOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('hapticsOn', value);
  }

  @override
  Future<int> getLastAiPlayerCount({required int defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getInt('lastAiPlayerCount') ?? defaultValue;
  }

  @override
  Future<String> getLastAiDifficulty({required String defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getString('lastAiDifficulty') ?? defaultValue;
  }

  @override
  Future<void> saveLastAiPlayerCount(int value) async {
    final prefs = await instanceFuture;
    await prefs.setInt('lastAiPlayerCount', value);
  }

  @override
  Future<void> saveLastAiDifficulty(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('lastAiDifficulty', value);
  }
}
