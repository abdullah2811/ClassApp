import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const ClassApp());
}

class ClassApp extends StatelessWidget {
  const ClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Class & Tasks System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          background: const Color(0xFF0F172A),
          surface: const Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await ApiService.getToken();
    setState(() {
      _isLoggedIn = token != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }
    return _isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}

// --- Login & Register Screens ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  void _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ApiService.login(
          _emailController.text.trim(), _passwordController.text.trim());
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 64, color: Color(0xFF6366F1)),
                const SizedBox(height: 16),
                Text('SmartClass & Tasks',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text('Sign in to manage your classes, routines, and alarms',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign In',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('Don\'t have an account? Sign Up',
                      style: TextStyle(color: Color(0xFF818CF8))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  void _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ApiService.register(_usernameController.text.trim(),
          _emailController.text.trim(), _passwordController.text.trim());
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Join SmartClass',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                      labelText: 'Username', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Dashboard Screen ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Classroom>> _classroomsFuture;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  void _loadClassrooms() {
    setState(() {
      _classroomsFuture = ApiService.getClassrooms();
    });
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final sectionController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Classroom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Classroom Name')),
            TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                    labelText: 'Section (e.g. A, Semester 4)')),
            TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.createClassroom(nameController.text,
                    sectionController.text, descController.text);
                Navigator.pop(context);
                _loadClassrooms();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog() {
    final codeController = TextEditingController();
    String role = 'viewer';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: const Text('Join Classroom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Invite Code')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: const [
                  DropdownMenuItem(
                      value: 'viewer', child: Text('Viewer (Read Only)')),
                  DropdownMenuItem(
                      value: 'editor', child: Text('Collaborator (Can Edit)')),
                ],
                onChanged: (val) => setStateSB(() => role = val!),
                decoration: const InputDecoration(labelText: 'Join As'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.joinClassroom(codeController.text, role);
                  Navigator.pop(context);
                  _loadClassrooms();
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classrooms & Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Classroom>>(
        future: _classroomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          final classrooms = snapshot.data ?? [];
          if (classrooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No classrooms found.',
                      style: TextStyle(color: Colors.white60, fontSize: 18)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Classroom'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _showJoinDialog,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Class'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisExtent: 200,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: classrooms.length,
            itemBuilder: (context, index) {
              final c = classrooms[index];
              return InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ClassroomDetailScreen(classroom: c))),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.role == 'owner'
                                  ? Colors.indigo
                                  : (c.role == 'editor'
                                      ? Colors.teal
                                      : Colors.blueGrey),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(c.role.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          Text('Code: ${c.inviteCode}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                      const Spacer(),
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      if (c.section != null) ...[
                        const SizedBox(height: 4),
                        Text(c.section!,
                            style: const TextStyle(
                                color: Color(0xFF818CF8), fontSize: 13)),
                      ],
                      const SizedBox(height: 8),
                      Text(c.description ?? 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Class', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- Classroom Detail Screen with Tabs ---
class ClassroomDetailScreen extends StatefulWidget {
  final Classroom classroom;
  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    bool canEdit =
        widget.classroom.role == 'owner' || widget.classroom.role == 'editor';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.classroom.name),
            Text(
                'Invite Code: ${widget.classroom.inviteCode} • Role: ${widget.classroom.role}',
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF818CF8),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Routine'),
            Tab(icon: Icon(Icons.task), text: 'Tasks'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Bus Schedule'),
            Tab(icon: Icon(Icons.event), text: 'Events'),
            Tab(icon: Icon(Icons.note), text: 'My Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RoutineTab(classroom: widget.classroom, canEdit: canEdit),
          TasksTab(classroom: widget.classroom, canEdit: canEdit),
          BusTab(classroom: widget.classroom, canEdit: canEdit),
          CustomScheduleTab(classroom: widget.classroom, canEdit: canEdit),
          PersonalNotesTab(classroom: widget.classroom),
        ],
      ),
    );
  }
}

// --- Routine Tab ---
class RoutineTab extends StatefulWidget {
  final Classroom classroom;
  final bool canEdit;
  const RoutineTab({super.key, required this.classroom, required this.canEdit});

  @override
  State<RoutineTab> createState() => _RoutineTabState();
}

class _RoutineTabState extends State<RoutineTab> {
  late Future<List<Routine>> _routinesFuture;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  void _loadRoutines() {
    setState(() {
      _routinesFuture = ApiService.getRoutines(widget.classroom.id);
    });
  }

  void _showAddDialog() {
    final dayController = TextEditingController(text: 'Monday');
    final subjectController = TextEditingController();
    final startController = TextEditingController(text: '09:00');
    final endController = TextEditingController(text: '10:30');
    final roomController = TextEditingController();
    final instructorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Class Routine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: dayController,
                decoration: const InputDecoration(labelText: 'Day of Week')),
            TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject Name')),
            TextField(
                controller: startController,
                decoration: const InputDecoration(
                    labelText: 'Start Time (e.g. 09:00)')),
            TextField(
                controller: endController,
                decoration:
                    const InputDecoration(labelText: 'End Time (e.g. 10:30)')),
            TextField(
                controller: roomController,
                decoration: const InputDecoration(labelText: 'Room')),
            TextField(
                controller: instructorController,
                decoration: const InputDecoration(labelText: 'Instructor')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.addRoutine(widget.classroom.id, {
                  'day_of_week': dayController.text,
                  'subject': subjectController.text,
                  'start_time': startController.text,
                  'end_time': endController.text,
                  'room': roomController.text,
                  'instructor': instructorController.text,
                });
                Navigator.pop(context);
                _loadRoutines();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Routine>>(
        future: _routinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final routines = snapshot.data ?? [];
          if (routines.isEmpty) {
            return const Center(
                child: Text('No routines added yet.',
                    style: TextStyle(color: Colors.white60)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final r = routines[index];
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(r.dayOfWeek[0],
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(r.subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                      '${r.startTime} - ${r.endTime} | Room: ${r.room ?? "N/A"} | Inst: ${r.instructor ?? "N/A"}',
                      style: const TextStyle(color: Colors.white60)),
                  trailing: Text(r.dayOfWeek,
                      style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- Tasks Tab ---
class TasksTab extends StatefulWidget {
  final Classroom classroom;
  final bool canEdit;
  const TasksTab({super.key, required this.classroom, required this.canEdit});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  late Future<List<TaskItem>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasksFuture = ApiService.getTasks(widget.classroom.id);
    });
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: const Text('Add Task / Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Task Title')),
              TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: priority,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (val) => setStateSB(() => priority = val!),
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.addTask(widget.classroom.id, {
                    'title': titleController.text,
                    'description': descController.text,
                    'priority': priority,
                    'status': 'pending',
                  });
                  Navigator.pop(context);
                  _loadTasks();
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<TaskItem>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(
                child: Text('No tasks created yet.',
                    style: TextStyle(color: Colors.white60)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final t = tasks[index];
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    t.status == 'completed'
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        t.status == 'completed' ? Colors.green : Colors.orange,
                  ),
                  title: Text(t.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(t.description ?? 'No description',
                      style: const TextStyle(color: Colors.white60)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.priority == 'urgent'
                          ? Colors.red
                          : (t.priority == 'high'
                              ? Colors.orange
                              : Colors.blue),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t.priority.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- Bus Schedule Tab ---
class BusTab extends StatefulWidget {
  final Classroom classroom;
  final bool canEdit;
  const BusTab({super.key, required this.classroom, required this.canEdit});

  @override
  State<BusTab> createState() => _BusTabState();
}

class _BusTabState extends State<BusTab> {
  late Future<List<BusSchedule>> _busFuture;

  @override
  void initState() {
    super.initState();
    _loadBus();
  }

  void _loadBus() {
    setState(() {
      _busFuture = ApiService.getBusSchedules(widget.classroom.id);
    });
  }

  void _showAddDialog() {
    final routeController = TextEditingController();
    final depController = TextEditingController(text: '08:00');
    final arrController = TextEditingController(text: '09:00');
    final busNoController = TextEditingController();
    final pickupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bus Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: routeController,
                decoration: const InputDecoration(labelText: 'Route Name')),
            TextField(
                controller: depController,
                decoration: const InputDecoration(labelText: 'Departure Time')),
            TextField(
                controller: arrController,
                decoration: const InputDecoration(labelText: 'Arrival Time')),
            TextField(
                controller: busNoController,
                decoration: const InputDecoration(labelText: 'Bus Number')),
            TextField(
                controller: pickupController,
                decoration: const InputDecoration(labelText: 'Pickup Point')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.addBusSchedule(widget.classroom.id, {
                  'route_name': routeController.text,
                  'departure_time': depController.text,
                  'arrival_time': arrController.text,
                  'bus_number': busNoController.text,
                  'pickup_point': pickupController.text,
                });
                Navigator.pop(context);
                _loadBus();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<BusSchedule>>(
        future: _busFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
                child: Text('No bus schedules added yet.',
                    style: TextStyle(color: Colors.white60)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final b = list[index];
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.directions_bus,
                      color: Color(0xFF6366F1), size: 36),
                  title: Text(b.routeName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                      'Dep: ${b.departureTime} | Arr: ${b.arrivalTime} | Bus: ${b.busNumber ?? "N/A"}\nPickup: ${b.pickupPoint ?? "N/A"}',
                      style: const TextStyle(color: Colors.white60)),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- Custom Schedule / Events Tab ---
class CustomScheduleTab extends StatefulWidget {
  final Classroom classroom;
  final bool canEdit;
  const CustomScheduleTab(
      {super.key, required this.classroom, required this.canEdit});

  @override
  State<CustomScheduleTab> createState() => _CustomScheduleTabState();
}

class _CustomScheduleTabState extends State<CustomScheduleTab> {
  late Future<List<CustomSchedule>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = ApiService.getCustomSchedules(widget.classroom.id);
    });
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Title')),
            TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.addCustomSchedule(widget.classroom.id, {
                  'title': titleController.text,
                  'event_time': DateTime.now()
                      .add(const Duration(days: 1))
                      .toIso8601String(),
                  'description': descController.text,
                });
                Navigator.pop(context);
                _loadEvents();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CustomSchedule>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
                child: Text('No custom events added yet.',
                    style: TextStyle(color: Colors.white60)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final e = list[index];
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Color(0xFF818CF8)),
                  title: Text(e.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                      '${e.description ?? ""}\nTime: ${e.eventTime.toLocal()}'
                          .trim(),
                      style: const TextStyle(color: Colors.white60)),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- Personal Notes Tab ---
class PersonalNotesTab extends StatefulWidget {
  final Classroom classroom;
  const PersonalNotesTab({super.key, required this.classroom});

  @override
  State<PersonalNotesTab> createState() => _PersonalNotesTabState();
}

class _PersonalNotesTabState extends State<PersonalNotesTab> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    try {
      final notes = await ApiService.getPersonalNotes(widget.classroom.id);
      _controller.text = notes;
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _saveNotes() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.savePersonalNotes(widget.classroom.id, _controller.text);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal notes saved successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Your Private Notes (Only visible & modifiable by you)',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText:
                    'Type your personal notes, reminders, or modifications here...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveNotes,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            icon: const Icon(Icons.save, color: Colors.white),
            label: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Notes',
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
