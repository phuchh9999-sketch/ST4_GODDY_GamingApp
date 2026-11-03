import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class ApiConfig {
  static String? _customBaseUrl;

  static Future<void> init() async {
    try {
      await StorageService.init();
      final savedUrl = StorageService.getString('custom_base_url');
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _customBaseUrl = _normalizeUrl(savedUrl.trim());
      }
    } catch (e) {
      debugPrint('Lỗi tải URL tùy chỉnh: $e');
    }
  }

  static String _normalizeUrl(String url) {
    var formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (!formatted.endsWith('/')) {
      formatted = '$formatted/';
    }
    if (!formatted.endsWith('api/')) {
      formatted = '${formatted}api/';
    }
    return formatted;
  }

  static Future<void> setCustomBaseUrl(String url) async {
    if (url.trim().isEmpty) {
      _customBaseUrl = null;
      await StorageService.remove('custom_base_url');
      return;
    }
    final formatted = _normalizeUrl(url);
    _customBaseUrl = formatted;
    await StorageService.setString('custom_base_url', formatted);
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:5271/api/';
    }
    if (Platform.isAndroid) {
      // Default to Conveyor Remote URL
      return 'http://192.168.50.80:45455/api/';
    }
    return 'http://localhost:5271/api/';
  }

  static List<String> get candidateHosts {
    final list = <String>[];
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      list.add(_customBaseUrl!);
    }
    list.addAll(const [
      'http://192.168.50.80:45455/api/',
      'http://192.168.50.80:5271/api/',
      'https://192.168.50.80:45455/api/',
      'https://192.168.50.80:7061/api/',
      'http://10.0.2.2:5271/api/',
      'http://10.0.2.2:45455/api/',
      'http://127.0.0.1:5271/api/',
      'http://localhost:5271/api/',
    ]);
    return list;
  }
}
