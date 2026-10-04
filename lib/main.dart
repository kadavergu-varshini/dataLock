import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 🔥 STEP 1: UPDATE THIS URL EVERY TIME YOU RESTART NGROK!
const String GLOBAL_URL = "https://flagship-overprice-shortcut.ngrok-free.dev";

void main() { runApp(DataLockApp()); }

class DataLockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: AuthCheck(),
    );
  }
}

// --- PART 1: AUTH CHECK ---
class AuthCheck extends StatefulWidget {
  @override _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() { super.initState(); checkUser(); }
  void checkUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('user_name') != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DataLockScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegistrationScreen()));
    }
  }
  @override Widget build(BuildContext context) { return Scaffold(body: Center(child: CircularProgressIndicator())); }
}

// --- PART 2: REGISTRATION SCREEN ---
class RegistrationScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  void saveUser(BuildContext context) async {
    if (nameController.text.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$GLOBAL_URL/register'),
          headers: {"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"},
          body: jsonEncode({
            "name": nameController.text.trim(), 
            "phone": phoneController.text.trim(),
            "email": emailController.text.trim()
          }),
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', nameController.text.trim());
          await prefs.setString('user_phone', phoneController.text.trim());
          await prefs.setString('user_email', emailController.text.trim());
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DataLockScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registration Failed: Check Table/Backend")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection Failed: Ensure ngrok is ONLINE")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("DataLock Registration"), backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Column(
          children: [
            SizedBox(height: 20),
            Icon(Icons.lock_person, size: 80, color: Colors.indigo[900]),
            SizedBox(height: 30),
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            SizedBox(height: 15),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone", border: OutlineInputBorder())),
            SizedBox(height: 15),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => saveUser(context),
              child: Text("Register & Secure Data"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white, minimumSize: Size(double.infinity, 55)),
            )
          ],
        ),
      ),
    );
  }
}

// --- PART 3: SECURE PROFILE SCREEN ---
class DataLockScreen extends StatefulWidget {
  @override _DataLockScreenState createState() => _DataLockScreenState();
}

class _DataLockScreenState extends State<DataLockScreen> {
  String myName = "";
  String dispName = "";
  String dispPhone = "---";
  String dispEmail = "---";

  final TextEditingController searchController = TextEditingController();
  int _tapCount = 0;
  DateTime? _lastTapTime;
  Timer? _securityGuard;
  bool _isShowingAlert = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
    secureScreen();
    syncOfflineLogs();
    startSecurityGuard();
  }

  @override
  void dispose() { _securityGuard?.cancel(); super.dispose(); }

  void loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      myName = prefs.getString('user_name') ?? "User";
      dispName = myName;
      dispPhone = prefs.getString('user_phone') ?? "";
      dispEmail = prefs.getString('user_email') ?? "";
    });
  }

  void startSecurityGuard() {
    _securityGuard = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_isShowingAlert || myName == "User") return;
      try {
        final response = await http.get(
          Uri.parse('$GLOBAL_URL/check_alerts/$myName'), 
          headers: {"ngrok-skip-browser-warning": "true"}
        );
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data['status'] == 'breach') { 
            // Trigger the big red popup (The main alert for the demo)
            _showCriticalAlert(data['attacker'], data['activity']); 
          }
        }
      } catch (e) { print("Guard: $e"); }
    });
  }

  void _showCriticalAlert(String attacker, String activity) {
    setState(() => _isShowingAlert = true);
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      backgroundColor: Colors.red[900],
      title: Icon(Icons.gpp_bad, color: Colors.white, size: 60),
      content: Text("SECURITY BREACH!\n\nUser '$attacker' is attempting an unauthorized action on your profile.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
      actions: [TextButton(child: Text("DISMISS", style: TextStyle(color: Colors.white)), onPressed: () { Navigator.of(context).pop(); setState(() => _isShowingAlert = false); })],
    ));
  }

  void _performSearch() async {
    String query = searchController.text.trim();
    if (query.isEmpty) return;

    print("--- Searching Cloud for: $query ---");

    try {
      final response = await http.get(
        Uri.parse('$GLOBAL_URL/search/$query'),
        headers: {"ngrok-skip-browser-warning": "true"},
      ).timeout(Duration(seconds: 7));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          dispName = data['name'];
          dispPhone = data['phone'];
          dispEmail = data['email'];
        });
      } else {
        setState(() { dispName = "USER NOT FOUND"; dispPhone = "---"; dispEmail = "---"; });
        showDialog(context: context, builder: (context) => AlertDialog(title: Text("Search Result"), content: Text("The account '$query' does not exist."), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))]));
      }
    } catch (e) {
      print("Search Error: $e");
    }
  }

  Future<void> secureScreen() async { await ScreenProtector.preventScreenshotOn(); }

  void _saveLogLocally(Map<String, String> logData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> offlineLogs = prefs.getStringList('pending_logs') ?? [];
    offlineLogs.add(jsonEncode(logData));
    await prefs.setStringList('pending_logs', offlineLogs);
  }

  void syncOfflineLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> offlineLogs = prefs.getStringList('pending_logs') ?? [];
    if (offlineLogs.isEmpty) return;
    List<String> remainingLogs = List.from(offlineLogs);
    for (String logStr in offlineLogs) {
      try {
        final response = await http.post(Uri.parse('$GLOBAL_URL/log_alert'), headers: {"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"}, body: logStr).timeout(Duration(seconds: 5));
        if (response.statusCode == 200) { remainingLogs.remove(logStr); }
      } catch (e) { break; }
    }
    await prefs.setStringList('pending_logs', remainingLogs);
  }

  void _analyzeInteraction() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 5000) { _tapCount++; } else { _tapCount = 1; }
    _lastTapTime = now;
    if (_tapCount >= 3) { _triggerSecurityAlert(); _tapCount = 0; }
  }

  void _triggerSecurityAlert() async {
    Map<String, String> logData = {"user": myName, "target_profile": dispName, "activity": "Interaction Pattern Detected"};
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("THREAT LOGGED!"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    try {
      await http.post(Uri.parse('$GLOBAL_URL/log_alert'), headers: {"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"}, body: jsonEncode(logData));
      syncOfflineLogs();
    } catch (e) {
      _saveLogLocally(logData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("DataLock v2.0", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo[900], centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.sync, color: Colors.white), onPressed: syncOfflineLogs),
          IconButton(icon: Icon(Icons.logout, color: Colors.white), onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.clear();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegistrationScreen()));
          })
        ],
      ),
      body: GestureDetector(
        onTap: _analyzeInteraction,
        child: Column(children: [
          Container(padding: EdgeInsets.all(15), color: Colors.indigo[900], child: TextField(controller: searchController, onSubmitted: (_) => _performSearch(), style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: "Search users...", hintStyle: TextStyle(color: Colors.white60), prefixIcon: Icon(Icons.search, color: Colors.white70), suffixIcon: IconButton(icon: Icon(Icons.send, color: Colors.white), onPressed: _performSearch), filled: true, fillColor: Colors.white.withOpacity(0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: EdgeInsets.zero))),
          Expanded(child: SingleChildScrollView(child: Column(children: [
            SizedBox(height: 40), 
            Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigo[50]), child: Icon(Icons.security, size: 80, color: Colors.indigo[900])),
            SizedBox(height: 20), 
            Text("PROTECTED USER PROFILE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo[900])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 40.0), child: Divider(thickness: 1, color: Colors.indigo[100])),
            SizedBox(height: 20),
            Text("User: $dispName", style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold)),
            Text("Phone: $dispPhone", style: TextStyle(fontSize: 14, color: Colors.black54)),
            Text("Email: $dispEmail", style: TextStyle(fontSize: 14, color: Colors.black54)),
            SizedBox(height: 40),
            Text(_isShowingAlert ? "🚨 BREACH IN PROGRESS" : "🛡️ GUARD ACTIVE (Polling Every 5s)", style: TextStyle(color: _isShowingAlert ? Colors.red : Colors.indigo[300], fontSize: 10, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.green)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_user, color: Colors.green[700], size: 20), SizedBox(width: 10), Text("SECURITY STATUS: ACTIVE", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold))])),
            SizedBox(height: 10),
            Text("Global Cloud Link Active", style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic)),
          ])))
        ]),
      ),
    );
  }
}