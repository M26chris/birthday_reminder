import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdaySoundSelection {
  const BirthdaySoundSelection({required this.uri, required this.name});

  final String uri;
  final String name;
}

class BirthdaySound {
  static const _platform = MethodChannel('app.remindra/birthday_sound');

  static Future<BirthdaySoundSelection?> pick() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Custom notification sounds require Android.');
    }
    final result = await _platform.invokeMapMethod<String, String>('pickAudio');
    if (result == null) return null;
    final uri = result['uri'];
    final name = result['name'];
    if (uri == null || name == null) {
      throw const FormatException('The selected audio file was not readable.');
    }
    return BirthdaySoundSelection(uri: uri, name: name);
  }

  static Future<BirthdaySoundSelection?> load(String birthdayId) async {
    final preferences = await SharedPreferences.getInstance();
    final uri = preferences.getString(_uriKey(birthdayId));
    final name = preferences.getString(_nameKey(birthdayId));
    if (uri == null || name == null) return null;
    return BirthdaySoundSelection(uri: uri, name: name);
  }

  static Future<void> save(
    String birthdayId,
    String? uri,
    String? name,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    if (uri == null || name == null) {
      await clear(birthdayId);
      return;
    }
    await preferences.setString(_uriKey(birthdayId), uri);
    await preferences.setString(_nameKey(birthdayId), name);
  }

  static Future<void> clear(String birthdayId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_uriKey(birthdayId));
    await preferences.remove(_nameKey(birthdayId));
  }

  static String _uriKey(String birthdayId) => 'birthday_sound_uri_$birthdayId';
  static String _nameKey(String birthdayId) =>
      'birthday_sound_name_$birthdayId';
}
