class User {
  final int id;
  final String username;
  final String email;

  User({required this.id, required this.username, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'username': username, 'email': email};
}

class Classroom {
  final int id;
  final String name;
  final String? section;
  final String? description;
  final int ownerId;
  final String inviteCode;
  final String role; // 'owner', 'editor', 'viewer'

  Classroom({
    required this.id,
    required this.name,
    this.section,
    this.description,
    required this.ownerId,
    required this.inviteCode,
    required this.role,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'],
      name: json['name'],
      section: json['section'],
      description: json['description'],
      ownerId: json['owner_id'],
      inviteCode: json['invite_code'],
      role: json['role'] ?? 'viewer',
    );
  }
}

class Routine {
  final int id;
  final int classroomId;
  final String dayOfWeek;
  final String subject;
  final String startTime;
  final String endTime;
  final String? room;
  final String? instructor;

  Routine({
    required this.id,
    required this.classroomId,
    required this.dayOfWeek,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.room,
    this.instructor,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      classroomId: json['classroom_id'],
      dayOfWeek: json['day_of_week'],
      subject: json['subject'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      room: json['room'],
      instructor: json['instructor'],
    );
  }
}

class TaskItem {
  final int id;
  final int classroomId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'pending', 'in_progress', 'completed'

  TaskItem({
    required this.id,
    required this.classroomId,
    required this.title,
    this.description,
    this.dueDate,
    required this.priority,
    required this.status,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      classroomId: json['classroom_id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
    );
  }
}

class BusSchedule {
  final int id;
  final int classroomId;
  final String routeName;
  final String departureTime;
  final String arrivalTime;
  final String? busNumber;
  final String? pickupPoint;

  BusSchedule({
    required this.id,
    required this.classroomId,
    required this.routeName,
    required this.departureTime,
    required this.arrivalTime,
    this.busNumber,
    this.pickupPoint,
  });

  factory BusSchedule.fromJson(Map<String, dynamic> json) {
    return BusSchedule(
      id: json['id'],
      classroomId: json['classroom_id'],
      routeName: json['route_name'],
      departureTime: json['departure_time'],
      arrivalTime: json['arrival_time'],
      busNumber: json['bus_number'],
      pickupPoint: json['pickup_point'],
    );
  }
}

class CustomSchedule {
  final int id;
  final int classroomId;
  final String title;
  final DateTime eventTime;
  final String? description;

  CustomSchedule({
    required this.id,
    required this.classroomId,
    required this.title,
    required this.eventTime,
    this.description,
  });

  factory CustomSchedule.fromJson(Map<String, dynamic> json) {
    return CustomSchedule(
      id: json['id'],
      classroomId: json['classroom_id'],
      title: json['title'],
      eventTime: DateTime.parse(json['event_time']),
      description: json['description'],
    );
  }
}

class AlarmItem {
  final int id;
  final int userId;
  final String eventType;
  final int eventId;
  final DateTime alarmTime;
  final bool isEnabled;
  final String sound;

  AlarmItem({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.eventId,
    required this.alarmTime,
    required this.isEnabled,
    required this.sound,
  });

  factory AlarmItem.fromJson(Map<String, dynamic> json) {
    return AlarmItem(
      id: json['id'],
      userId: json['user_id'],
      eventType: json['event_type'],
      eventId: json['event_id'],
      alarmTime: DateTime.parse(json['alarm_time']),
      isEnabled: json['is_enabled'] ?? true,
      sound: json['sound'] ?? 'default_alarm',
    );
  }
}
