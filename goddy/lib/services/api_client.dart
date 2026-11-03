import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static String? _workingBaseUrl;
  static String? memoryToken;

  List<String> get _candidateHosts {
    if (_workingBaseUrl != null) {
      return [_workingBaseUrl!];
    }
    return ApiConfig.candidateHosts;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = StorageService.getString('jwt_token') ?? memoryToken;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response?> get(String endpoint) async {
    final headers = await _getHeaders();
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host$endpoint');
        final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 3));
        _workingBaseUrl = host;
        return response;
      } catch (e) {
        debugPrint('GET $host$endpoint failed: $e');
      }
    }
    return null;
  }

  Future<http.Response?> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final bodyJson = jsonEncode(body);
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host$endpoint');
        final response = await http.post(url, headers: headers, body: bodyJson).timeout(const Duration(seconds: 3));
        _workingBaseUrl = host;
        return response;
      } catch (e) {
        debugPrint('POST $host$endpoint failed: $e');
      }
    }
    return null;
  }

  Future<http.Response?> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final bodyJson = jsonEncode(body);
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host$endpoint');
        final response = await http.put(url, headers: headers, body: bodyJson).timeout(const Duration(seconds: 3));
        _workingBaseUrl = host;
        return response;
      } catch (e) {
        debugPrint('PUT $host$endpoint failed: $e');
      }
    }
    return null;
  }

  Future<http.Response?> delete(String endpoint) async {
    final headers = await _getHeaders();
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host$endpoint');
        final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 3));
        _workingBaseUrl = host;
        return response;
      } catch (e) {
        debugPrint('DELETE $host$endpoint failed: $e');
      }
    }
    return null;
  }
}
