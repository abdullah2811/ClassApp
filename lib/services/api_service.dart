import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['access_token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['access_token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Registration failed');
    }
  }

  static Future<List<Classroom>> getClassrooms() async {
    final response = await http.get(Uri.parse('$baseUrl/classrooms'), headers: await _headers());
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body);
      return list.map((e) => Classroom.fromJson(e)).toList();
    }
    throw Exception('Failed to load classrooms');
  }

  static Future<Classroom> createClassroom(String name, String? section, String? description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classrooms'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'section': section, 'description': description}),
    );
    if (response.statusCode == 200) {
      return Classroom.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create classroom');
  }

  static Future<void> joinClassroom(String inviteCode, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classrooms/join?invite_code=$inviteCode&role=$role'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to join classroom');
    }
  }

  static Future<List<Routine>> getRoutines(int classroomId) async {
    final response = await http.get(Uri.parse('$baseUrl/classrooms/$classroomId/routines'), headers: await _headers());
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body);
      return list.map((e) => Routine.fromJson(e)).toList();
    }
    throw Exception('Failed to load routines');
  }

  static Future<void> addRoutine(int classroomId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classrooms/$classroomId/routines'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Failed to add routine');
  }

  static Future<List<TaskItem>> getTasks(int classroomId) async {
    final response = await http.get(Uri.parse('$baseUrl/classrooms/$classroomId/tasks'), headers: await _headers());
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body);
      return list.map((e) => TaskItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load tasks');
  }

  static Future<void> addTask(int classroomId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classrooms/$classroomId/tasks'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Failed to add task');
  }

  static Future<List<BusSchedule>> getBusSchedules(int classroomId) async {
    final response = await http.get(Uri.parse('$baseUrl/classrooms/$classroomId/bus-schedules'), headers: await _headers());
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body);
      return list.map((e) => BusSchedule.fromJson(e)).toList();
    }
    throw Exception('Failed to load bus schedules');
  }

  static Future<void> addBusSchedule(int classroomId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classrooms/$classroomId/bus-schedules'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Failed to add bus schedule');
  }

  static Future<List<CustomSchedule>> getCustomSchedules(int classroomId) async {
    final response = await http.get(Uri.parse('$baseUrl/classrooms/$classroomId/custom-schedules'), headers: await _headers());
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body);
      return list.map((e) => CustomSchedule.fromJson(e)).toList();
    }
    throw Exception('Failed to load custom schedules');
  }

  static Future<void> addCustomSchedule(int classroomId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classrooms/$classroomId/custom-schedules'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Failed to add custom schedule');
  }

  static Future<String> getPersonalNotes(int classroomId) async {
    final response = await http.get(Uri.parse('$baseUrl/classrooms/$classroomId/notes'), headers: await _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['content'] ?? '';
    }
    return '';
  }

  static Future<void> savePersonalNotes(int classroomId, String content) async {
    await http.post(
      Uri.parse('$baseUrl/classrooms/$classroomId/notes'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
  }

  static Future<List<AlarmItem>> getAlarms() async {
    final response = await http.get(Uri.parse('$baseUrl/alarms'), headers: await _headers());
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body);
      return list.map((e) => AlarmItem.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> createAlarm(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('$baseUrl/alarms'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
  }

  static Future<void> deleteAlarm(int alarmId) async {
    await http.delete(Uri.parse('$baseUrl/alarms/$alarmId'), headers: await _headers());
  }
}
