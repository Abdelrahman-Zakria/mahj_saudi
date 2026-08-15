import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/domain/entities/educational_node.dart';

class LocalStorageService {
  static const String _favoritesKey = 'favorites_nodes';
  static const String _downloadsKey = 'downloaded_nodes';
  static const String _timerKey = 'study_timers';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _notificationsHistoryKey = 'notifications_history';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsKey, enabled);
  }

  bool areNotificationsEnabled() {
    return _prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> saveNotificationLog(Map<String, dynamic> notification) async {
    final history = getNotificationHistory();
    // Add to start of list (newest first)
    history.insert(0, {
      ...notification,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // Keep last 50 notifications
    if (history.length > 50) history.removeLast();
    await _prefs.setString(_notificationsHistoryKey, jsonEncode(history));
  }

  List<Map<String, dynamic>> getNotificationHistory() {
    final String? data = _prefs.getString(_notificationsHistoryKey);
    if (data == null) return [];
    try {
      final List decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearNotificationHistory() async {
    await _prefs.remove(_notificationsHistoryKey);
  }

  // Favorites
  Future<void> toggleFavorite(EducationalNode node) async {
    final favorites = getFavorites();
    final index = favorites.indexWhere((e) => e.id == node.id);
    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add(node);
    }
    // Clean before saving
    final seen = <String>{};
    final unique = favorites.where((n) => seen.add(n.id)).toList();
    await _prefs.setString(_favoritesKey, jsonEncode(unique.map((e) => e.toMap()).toList()));
  }

  List<EducationalNode> getFavorites() {
    final String? data = _prefs.getString(_favoritesKey);
    if (data == null) return [];
    try {
      final List decoded = jsonDecode(data);
      final list = decoded.map((e) => EducationalNode.fromMap(e['id'], Map<String, dynamic>.from(e))).toList();
      
      final seen = <String>{};
      return list.where((node) => seen.add(node.id)).toList();
    } catch (e) {
      return [];
    }
  }

  bool isFavorite(String id) {
    return getFavorites().any((e) => e.id == id);
  }

  // Downloads (مكتبتي)
  Future<void> saveToLibrary(EducationalNode node) async {
    final list = getLibraryNodes();
    if (!list.any((e) => e.id == node.id)) {
      list.add(node);
      // Clean before saving
      final seen = <String>{};
      final unique = list.where((n) => seen.add(n.id)).toList();
      await _prefs.setString(_downloadsKey, jsonEncode(unique.map((e) => e.toMap()).toList()));
    }
  }

  List<EducationalNode> getLibraryNodes() {
    final String? data = _prefs.getString(_downloadsKey);
    if (data == null) return [];
    try {
      final List decoded = jsonDecode(data);
      final list = decoded.map((e) => EducationalNode.fromMap(e['id'], Map<String, dynamic>.from(e))).toList();
      
      final seen = <String>{};
      return list.where((node) => seen.add(node.id)).toList();
    } catch (e) {
      return [];
    }
  }

  // Timer Feature
  Future<void> saveTimer(Map<String, dynamic> timerData) async {
    final timers = getTimers();
    timers.add(timerData);
    await _prefs.setString(_timerKey, jsonEncode(timers));
  }

  Future<void> deleteTimer(int index) async {
    final timers = getTimers();
    if (index >= 0 && index < timers.length) {
      timers.removeAt(index);
      await _prefs.setString(_timerKey, jsonEncode(timers));
    }
  }

  Future<void> clearAllTimers() async {
    await _prefs.remove(_timerKey);
  }

  List<Map<String, dynamic>> getTimers() {
    final String? data = _prefs.getString(_timerKey);
    if (data == null) return [];
    try {
      final List decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
