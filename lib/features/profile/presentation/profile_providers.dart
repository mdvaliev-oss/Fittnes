import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/app_settings.dart';
import '../domain/user_profile.dart';

/// Reads/writes the [UserProfile] as JSON in SharedPreferences.
class ProfileController extends Notifier<UserProfile> {
  static const _key = 'profile.data';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  UserProfile build() {
    final raw = _prefs.getString(_key);
    if (raw == null) return UserProfile.empty;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.empty;
    }
  }

  Future<void> update(UserProfile profile) async {
    state = profile;
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}

final profileProvider =
    NotifierProvider<ProfileController, UserProfile>(ProfileController.new);
