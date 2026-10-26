import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/storage/secure_token_storage.dart';
import '../models/models.dart';

class ApiService {
  ApiService._();

  static final ApiClient _client = ApiClient();
  static final SecureTokenStorage _tokens = SecureTokenStorage();

  static Future<String?> getToken() => _tokens.readAccessToken();

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: FormData.fromMap({'username': email, 'password': password}),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return _saveAuthResponse(response.data);
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'username': username, 'email': email, 'password': password},
    );
    return _saveAuthResponse(response.data);
  }

  static Future<void> logout() => _tokens.clear();

  static Future<Map<String, dynamic>> _saveAuthResponse(
    Map<String, dynamic>? response,
  ) async {
    final data = response ?? const <String, dynamic>{};
    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Authentication response did not contain a token');
    }
    await _tokens.saveTokens(
      accessToken: accessToken,
      refreshToken: data['refresh_token'] as String?,
    );
    return data;
  }

  static Future<List<Classroom>> getClassrooms() async {
    final response = await _client.dio.get<List<dynamic>>('/classrooms');
    return response.data!
        .map((item) => Classroom.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Classroom> createClassroom(
    String name,
    String? section,
    String? description,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/classrooms',
      data: {'name': name, 'section': section, 'description': description},
    );
    return Classroom.fromJson(response.data!);
  }

  static Future<void> joinClassroom(String inviteCode, String role) async {
    await _client.dio.post<void>(
      '/classrooms/join',
      queryParameters: {'invite_code': inviteCode, 'role': role},
    );
  }

  static Future<List<Routine>> getRoutines(int classroomId) async {
    final response =
        await _client.dio.get<List<dynamic>>('/classrooms/$classroomId/routines');
    return response.data!
        .map((item) => Routine.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addRoutine(int id, Map<String, dynamic> data) =>
      _client.dio.post<void>('/classrooms/$id/routines', data: data);

  static Future<List<TaskItem>> getTasks(int classroomId) async {
    final response =
        await _client.dio.get<List<dynamic>>('/classrooms/$classroomId/tasks');
    return response.data!
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addTask(int id, Map<String, dynamic> data) =>
      _client.dio.post<void>('/classrooms/$id/tasks', data: data);

  static Future<List<BusSchedule>> getBusSchedules(int id) async {
    final response =
        await _client.dio.get<List<dynamic>>('/classrooms/$id/bus-schedules');
    return response.data!
        .map((item) => BusSchedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addBusSchedule(int id, Map<String, dynamic> data) =>
      _client.dio.post<void>('/classrooms/$id/bus-schedules', data: data);

  static Future<List<CustomSchedule>> getCustomSchedules(int id) async {
    final response =
        await _client.dio.get<List<dynamic>>('/classrooms/$id/custom-schedules');
    return response.data!
        .map((item) => CustomSchedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addCustomSchedule(int id, Map<String, dynamic> data) =>
      _client.dio.post<void>('/classrooms/$id/custom-schedules', data: data);

  static Future<String> getPersonalNotes(int id) async {
    final response =
        await _client.dio.get<Map<String, dynamic>>('/classrooms/$id/notes');
    return response.data?['content'] as String? ?? '';
  }

  static Future<void> savePersonalNotes(int id, String content) =>
      _client.dio.post<void>('/classrooms/$id/notes', data: {'content': content});

  static Future<List<AlarmItem>> getAlarms() async {
    final response = await _client.dio.get<List<dynamic>>('/alarms');
    return response.data!
        .map((item) => AlarmItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createAlarm(Map<String, dynamic> data) =>
      _client.dio.post<void>('/alarms', data: data);

  static Future<void> deleteAlarm(int alarmId) =>
      _client.dio.delete<void>('/alarms/$alarmId');
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
