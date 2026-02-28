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
      home: CalculatorScreen(),
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
  // ==============================
  // FORMAT TIMER
  // ==============================
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  // ==============================
  // LOCATION
  // ==============================
  Future<void> _getLocation() async {
    await Permission.location.request();
    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ==============================
  // START WALK
  // ==============================
  void _startWalk() async {
    if (selectedDistrict == null ||
        selectedPlace == null ||
        selectedTimerLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select district, place & timer")),
      );
      return;
    }

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
  bool _isFakeCallScheduled = false;

void _triggerFakeCall() {
  if (_isFakeCallScheduled) return;

  setState(() {
    _isFakeCallScheduled = true;
  });

  Future.delayed(const Duration(seconds: 2), () {
    setState(() {
      _isFakeCallScheduled = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FakeCallScreen(),
      ),
    );
  });
}
  @override
  void dispose() {
    _checkInTimer?.cancel();
    super.dispose();
  }

  // ==============================
  // UI
  // ==============================
  @override
  Widget build(BuildContext context) {
    List<String> places = selectedDistrict == null
    ? []
    : locations[selectedDistrict]!.keys.toList();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ===========================
              // FIRST PAGE
              // ===========================
              if (!_isWalking) ...[
                const SizedBox(height: 40),

                // SHIELD ICON
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "SafeWalk",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Your trusted safety companion",
                  style: TextStyle(color: Colors.white54),
                ),

                const SizedBox(height: 40),

                _buildDropdown(
                  label: "DISTRICT",
                  value: selectedDistrict,
                  items: locations.keys.toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedDistrict = val;
                      selectedPlace = null;
                    });
                  },
                ),

                const SizedBox(height: 16),

                _buildDropdown(
                  label: "PLACE",
                  value: selectedPlace,
                  items: places,
                  onChanged: (val) {
                    setState(() {
                      selectedPlace = val;
                    });
                  },
                ),

                const SizedBox(height: 16),

                _buildDropdown(
                  label: "ALERT TIMER",
                  value: selectedTimerLabel,
                  items: timerOptions.keys.toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedTimerLabel = val;
                      _selectedTimerSeconds = timerOptions[val]!;
                    });
                  },
                ),

                const SizedBox(height: 30),

                _buildMainButton(
                  text: "🚶 Start Walk",
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  ),
                  onPressed: _startWalk,
                ),

                const SizedBox(height: 16),

                _buildMainButton(
                  text: "🚨 SOS Emergency",
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  ),
                  onPressed: _sendSOS,
                ),
                const SizedBox(height: 16),

                _buildMainButton(
                  text: "📞 Fake Call",
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFB45309)],
                  ),
                  onPressed: _triggerFakeCall,
                ),
              ],

              // ===========================
              // WALKING PAGE (NO SOS)
              // ===========================
              if (_isWalking) ...[
                const SizedBox(height: 30),

                // WALK ACTIVE LABEL
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.circle, color: Colors.green, size: 10),
                    SizedBox(width: 8),
                    Text(
                      "WALK ACTIVE",
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  "${selectedPlace ?? ""}, ${selectedDistrict ?? ""}",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // TIMER CIRCLE
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // Circular Progress
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: _remainingCheckIn / _selectedTimerSeconds,
                          strokeWidth: 12,
                          backgroundColor: Colors.white12,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.pink),
                        ),
                      ),

                      // Center Text Column
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "CHECK-IN IN",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formatTime(_remainingCheckIn),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // I'M SAFE BUTTON
                _simpleButton(
                  text: "✓ I'm Safe — Check In",
                  color: Colors.green,
                  onPressed: _checkIn,
                ),

                const SizedBox(height: 16),

                // I HAVE REACHED BUTTON
                _simpleButton(
                  text: "🏠 I Have Reached",
                  color: Colors.blue,
                  onPressed: _iHaveReached,
                ),

                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==============================
  // HELPERS
  // ==============================

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF111827),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      items: items
          .map((e) =>
              DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMainButton({
    required String text,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding:
              const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _simpleButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding:
              const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        child: Text(text,
            style: const TextStyle(fontSize: 16)),
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
                Text("Police",
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
  State<CallConnectedScreen> createState() =>
      _CallConnectedScreenState();
}

class _CallConnectedScreenState extends State<CallConnectedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

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
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: Colors.black87, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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

                      // Animated Profile
                      ScaleTransition(
                        scale: _animation,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor:
                              Colors.grey.shade300,
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Police",
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

                      // Row 1
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          _callOption(
                              Icons.mic_off, "Mute"),
                          _callOption(Icons.bluetooth,
                              "Bluetooth"),
                          _callOption(
                              Icons.pause_circle_outline,
                              "Hold"),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Row 2
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          _callOption(
                              Icons.dialpad, "Keypad"),
                          _callOption(Icons.volume_up,
                              "Speaker"),
                        ],
                      ),

                      const Spacer(),

                      // End Call Button
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 40),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.teal,
                          child: IconButton(
                            icon: const Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 28),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = "";
  String result = "0";

  void buttonPressed(String value) async {
    if (value == "C") {
      setState(() {
        input = "";
        result = "0";
      });
      return;
    }

    if (value == "=") {

  // 🚨 EMERGENCY NUMBERS
  if (input == "100" ||
      input == "101" ||
      input == "102" ||
      input == "112") {

    final Uri callUri = Uri(
      scheme: 'tel',
      path: input,
    );

    await launchUrl(callUri);
    return;
  }

  // 🔐 SECRET CODE → OPEN SAFETY APP
  if (input == "1234") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WalkWithMeScreen(),
      ),
    );

    setState(() {
      input = "";
    });

    return;
  }

  // NORMAL CALCULATOR
  try {
    final res = double.parse(input);
    setState(() {
      result = res.toString();
    });
  } catch (_) {
    setState(() {
      result = "Error";
    });
  }

  return;
}
    setState(() {
      input += value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // DISPLAY
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(24),
                child: Text(
                  input.isEmpty ? result : input,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),

            // BUTTON GRID
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  buildRow(["C", "(", ")", "/"]),
                  buildRow(["7", "8", "9", "*"]),
                  buildRow(["4", "5", "6", "-"]),
                  buildRow(["1", "2", "3", "+"]),
                  buildRow(["+/-", "0", ".", "="]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((text) => buildButton(text)).toList(),
      ),
    );
  }

  Widget buildButton(String text) {
    bool isOperator = ["/", "*", "-", "+", "="].contains(text);
    bool isClear = text == "C";

    Color bgColor;
    Color textColor;

    if (text == "=") {
      bgColor = const Color(0xFF8D5A46);
      textColor = Colors.white;
    } else {
      bgColor = const Color(0xFF1E1E2C);
      textColor = isOperator
          ? const Color(0xFFD2B8A3)
          : isClear
              ? Colors.redAccent
              : Colors.white;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AspectRatio(
          aspectRatio: 1,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              shape: const CircleBorder(),
            ),
            onPressed: () => buttonPressed(text),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}