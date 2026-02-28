import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const SafeWalkApp());
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WalkWithMeScreen(),
    );
  }
}

class WalkWithMeScreen extends StatefulWidget {
  const WalkWithMeScreen({super.key});

  @override
  State<WalkWithMeScreen> createState() => _WalkWithMeScreenState();
}

class _WalkWithMeScreenState extends State<WalkWithMeScreen> {
  Timer? _checkInTimer;
  int _remainingCheckIn = 60;
  int _selectedTimerSeconds = 60;
  bool _isWalking = false;
  bool _isFakeCallScheduled = false;

  Position? _currentPosition;

  final Map<String, int> timerOptions = {
    "30 Seconds": 30,
    "1 Minute": 60,
    "5 Minutes": 300,
    "10 Minutes": 600,
    "15 Minutes": 900,
    "30 Minutes": 1800,
    "45 Minutes": 2700,
    "1 Hour": 3600,
  };

  String? selectedTimerLabel;
  String? selectedDistrict;
  String? selectedPlace;

  final Map<String, Map<String, Map<String, double>>> locations = {
    "Thiruvananthapuram": {
      "Kowdiar": {"lat": 8.5230, "lng": 76.9492},
      "Technopark": {"lat": 8.5584, "lng": 76.8800},
      "Kovalam": {"lat": 8.3988, "lng": 76.9782},
      "Lulu Mall": {"lat": 8.4875, "lng": 76.9512},
    },
    "Kollam": {
      "Kollam Town": {"lat": 8.8932, "lng": 76.6141},
      "Paravur": {"lat": 8.8150, "lng": 76.6670},
      "Chinnakada": {"lat": 8.8939, "lng": 76.6148},
    },
    "Pathanamthitta": {
      "Adoor": {"lat": 9.1559, "lng": 76.7317},
      "Thiruvalla": {"lat": 9.3840, "lng": 76.5740},
      "Pandalam": {"lat": 9.2400, "lng": 76.6900},
    },
    "Alappuzha": {
      "Alappuzha Town": {"lat": 9.4981, "lng": 76.3388},
      "Cherthala": {"lat": 9.6866, "lng": 76.3394},
      "Kayamkulam": {"lat": 9.1817, "lng": 76.5040},
    },
    "Kottayam": {
      "Kottayam Town": {"lat": 9.5916, "lng": 76.5222},
      "Ettumanoor": {"lat": 9.6700, "lng": 76.5700},
      "Pala": {"lat": 9.7110, "lng": 76.6890},
    },
    "Idukki": {
      "Thodupuzha": {"lat": 9.8970, "lng": 76.7130},
      "Munnar": {"lat": 10.0889, "lng": 77.0595},
      "Kattappana": {"lat": 9.7510, "lng": 77.1160},
    },
    "Ernakulam": {
      "Kochi": {"lat": 9.9312, "lng": 76.2673},
      "Edappally": {"lat": 10.0261, "lng": 76.3089},
      "Kakkanad": {"lat": 10.0159, "lng": 76.3419},
    },
    "Thrissur": {
      "Thrissur Town": {"lat": 10.5276, "lng": 76.2144},
      "Guruvayur": {"lat": 10.5943, "lng": 76.0411},
      "Kodungallur": {"lat": 10.2333, "lng": 76.2000},
    },
    "Palakkad": {
      "Palakkad Town": {"lat": 10.7867, "lng": 76.6548},
      "Ottapalam": {"lat": 10.7730, "lng": 76.3770},
      "Mannarkkad": {"lat": 10.9900, "lng": 76.4700},
    },
    "Malappuram": {
      "Malappuram Town": {"lat": 11.0510, "lng": 76.0710},
      "Manjeri": {"lat": 11.1200, "lng": 76.1200},
      "Tirur": {"lat": 10.9140, "lng": 75.9210},
    },
    "Kozhikode": {
      "Kozhikode City": {"lat": 11.2588, "lng": 75.7804},
      "Koyilandy": {"lat": 11.4400, "lng": 75.6900},
      "Vadakara": {"lat": 11.6000, "lng": 75.5800},
    },
    "Wayanad": {
      "Kalpetta": {"lat": 11.6085, "lng": 76.0830},
      "Sulthan Bathery": {"lat": 11.6670, "lng": 76.2700},
      "Mananthavady": {"lat": 11.8020, "lng": 76.0000},
    },
    "Kannur": {
      "Kannur Town": {"lat": 11.8745, "lng": 75.3704},
      "Thalassery": {"lat": 11.7500, "lng": 75.4900},
      "Payyannur": {"lat": 12.1050, "lng": 75.2100},
    },
    "Kasaragod": {
      "Kasaragod Town": {"lat": 12.4996, "lng": 74.9869},
      "Kanhangad": {"lat": 12.3150, "lng": 75.1100},
      "Bekal": {"lat": 12.3940, "lng": 75.0330},
    },
  };

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Future<void> _requestPermission() async {
    await Permission.location.request();
  }

  Future<void> _getLocation() async {
    _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _startWalk() async {
    if (selectedDistrict == null ||
        selectedPlace == null ||
        selectedTimerLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select district, place & timer")),
      );
      return;
    }

    await _requestPermission();
    await _getLocation();

    setState(() {
      _isWalking = true;
      _remainingCheckIn = _selectedTimerSeconds;
    });

    _checkInTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingCheckIn == 0) {
        timer.cancel();
        _triggerAutoAlert();
      } else {
        setState(() {
          _remainingCheckIn--;
        });
      }
    });
  }

  void _checkIn() {
    setState(() {
      _remainingCheckIn = _selectedTimerSeconds;
    });
  }

  void _iHaveReached() {
    _checkInTimer?.cancel();
    setState(() {
      _isWalking = false;
    });
  }

  Future<void> _sendSOS() async {
    if (_currentPosition == null) await _getLocation();

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: '9846825169',
      queryParameters: {
        'body':
            "🚨 Emergency!\nLocation:\nhttps://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}"
      },
    );

    await launchUrl(smsUri);
  }

  void _triggerAutoAlert() async {
    await _sendSOS();
    setState(() {
      _isWalking = false;
    });
  }

  void _triggerFakeCall() {
    if (_isFakeCallScheduled) return;

    setState(() {
      _isFakeCallScheduled = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _isFakeCallScheduled = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FakeCallScreen()),
      );
    });
  }

  @override
  void dispose() {
    _checkInTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> places = selectedDistrict == null
        ? []
        : locations[selectedDistrict]!.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Women Safety App")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [

              if (!_isWalking) ...[
                DropdownButtonFormField<String>(
                  value: selectedDistrict,
                  items: locations.keys
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDistrict = value;
                      selectedPlace = null;
                    });
                  },
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select District"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedPlace,
                  items: places
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPlace = value;
                    });
                  },
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select Place"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedTimerLabel,
                  items: timerOptions.keys
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTimerLabel = value;
                      _selectedTimerSeconds = timerOptions[value]!;
                    });
                  },
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select Alert Timer"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: _startWalk,
                    child: const Text("Start Walk")),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: _sendSOS,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("🚨 SEND SOS")),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: _triggerFakeCall,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text("📞 Fake Call")),
              ],

              if (_isWalking) ...[
                const SizedBox(height: 30),
                Text("Check-in in:",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                Text(formatTime(_remainingCheckIn),
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink)),
                const SizedBox(height: 30),
                ElevatedButton(
                    onPressed: _checkIn,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text("Check In")),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: _iHaveReached,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue),
                    child: const Text("I Have Reached")),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
    _player.play(AssetSource('sample-audio-67973.mp3'));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 100),
            const Column(
              children: [
                Text("Incoming Call",
                    style: TextStyle(color: Colors.white70, fontSize: 18)),
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person,
                      size: 70, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text("Khun Thee",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.call_end),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CallConnectedScreen()),
                      );
                    },
                    child: const Icon(Icons.call),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================
// 🔥 CALL CONNECTED SCREEN
// ==========================

class CallConnectedScreen extends StatefulWidget {
  const CallConnectedScreen({super.key});

  @override
  State<CallConnectedScreen> createState() => _CallConnectedScreenState();
}

class _CallConnectedScreenState extends State<CallConnectedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animated pulse effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation =
        Tween<double>(begin: 0.9, end: 1.1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _callOption(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 40),

            const Text(
              "Dialing",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 40),

            // Animated Profile Circle
            ScaleTransition(
              scale: _animation,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey.shade300,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "khun Thee",
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "476-229-9449",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54),
            ),

            const SizedBox(height: 40),

            const Divider(),

            const SizedBox(height: 20),

            // Call Options Row 1
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _callOption(Icons.mic_off, "Mute"),
                _callOption(Icons.bluetooth, "Bluetooth"),
                _callOption(Icons.pause_circle_outline, "Hold"),
              ],
            ),

            const SizedBox(height: 30),

            // Call Options Row 2
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _callOption(Icons.dialpad, "Keypad"),
                const SizedBox(width: 60),
                _callOption(Icons.volume_up, "Speaker"),
              ],
            ),

            const Spacer(),

            // End Call Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.teal,
                child: IconButton(
                  icon: const Icon(Icons.call_end,
                      color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}