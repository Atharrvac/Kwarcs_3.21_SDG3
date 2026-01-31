import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isFetchingInitialData = true;
  Map<String, dynamic>? _sensorData;
  Position? _userPosition;

  static const String _sensorEndpoint = 'http://10.227.198.126:5000/api/sensor/nearby';
  static const String _aiEndpoint = 'http://10.227.198.126:5000/api/ai/generate';

  @override
  void initState() {
    super.initState();
    _initializeBot();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeBot() async {
    setState(() {
      _isFetchingInitialData = true;
      _messages.add({
        'sender': 'bot',
        'text': '👋 Hello! I\'m AirBot, your air quality assistant.\n\n🔍 Fetching your location and nearby sensor data...',
        'timestamp': DateTime.now(),
      });
    });

    await _fetchLocationAndSensorData();
  }

  Future<void> _fetchLocationAndSensorData() async {
    try {
      // Step 1: Get user location
      debugPrint('🔍 Fetching user location...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _addBotMessage(
          '⚠️ Location services are disabled.\n\nPlease enable location services in your device settings to get accurate air quality information for your area.',
        );
        setState(() => _isFetchingInitialData = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _addBotMessage(
            '⚠️ Location permission denied.\n\nI need location access to provide air quality data for your area. Please grant permission and restart the app.',
          );
          setState(() => _isFetchingInitialData = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _addBotMessage(
          '⚠️ Location permission permanently denied.\n\nPlease enable location permission in your device settings to use this feature.',
        );
        setState(() => _isFetchingInitialData = false);
        return;
      }

      // Get last known position first (faster)
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        debugPrint('📍 Got last known position: ${position?.latitude}, ${position?.longitude}');
      } catch (e) {
        debugPrint('⚠️ No last known position: $e');
      }

      // If no last known position, get current position
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 30),
          ),
        );
      }

      _userPosition = position;
      debugPrint('✅ User location: ${position.latitude}, ${position.longitude}');

      // Step 2: Fetch nearby sensor data
      await _fetchNearbySensorData(position);

      // Step 3: Generate AI greeting with sensor data
      if (_sensorData != null) {
        await _sendInitialAiGreeting();
      }

    } catch (e) {
      debugPrint('❌ Location/Sensor error: $e');
      _addBotMessage(
        '❌ Error getting your location:\n$e\n\nYou can still ask me questions about air quality and respiratory health in general!',
      );
    } finally {
      setState(() => _isFetchingInitialData = false);
    }
  }

  Future<void> _fetchNearbySensorData(Position position) async {
    try {
      debugPrint('📡 Fetching nearby sensor data...');

      final response = await http.post(
        Uri.parse(_sensorEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lat': position.latitude.toStringAsFixed(6),
          'lang': position.longitude.toStringAsFixed(6),
          'distance': '5000m', // 5km radius
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 Sensor API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Sensor data received: $data');

        // Extract sensor data from response
        if (data.containsKey('data') && data['data'] is List) {
          final sensorList = data['data'] as List;
          if (sensorList.isNotEmpty) {
            // Get the nearest sensor (first one)
            _sensorData = sensorList[0] as Map<String, dynamic>;
            debugPrint('✅ Using nearest sensor: $_sensorData');
          } else {
            debugPrint('⚠️ No sensors found in the area');
            _addBotMessage(
              '⚠️ No air quality sensors found within 5km of your location.\n\nYou can still ask me general questions about air quality and respiratory health!',
            );
          }
        } else {
          debugPrint('⚠️ Unexpected API response format');
        }
      } else {
        debugPrint('❌ Sensor API failed: ${response.statusCode}');
        _addBotMessage(
          '⚠️ Unable to fetch nearby sensor data (HTTP ${response.statusCode}).\n\nYou can still ask me general questions!',
        );
      }
    } catch (e) {
      debugPrint('❌ Sensor fetch error: $e');
      _addBotMessage(
        '⚠️ Error connecting to sensor network:\n$e\n\nYou can still ask me general questions!',
      );
    }
  }

  Future<void> _sendInitialAiGreeting() async {
    if (_sensorData == null) return;

    try {
      final temp = _parseValue(_sensorData!['temp']);
      final humidity = _parseValue(_sensorData!['humidity']);
      final aqi = _parseValue(_sensorData!['air_quality']);
      final distance = _parseValue(_sensorData!['distance_km']);

      final prompt = '''
You are AirBot, a helpful and friendly air quality and respiratory health assistant.

CONTEXT - Current Real-Time Sensor Data (${distance}km from user):
- Temperature: ${temp}°C
- Humidity: ${humidity}%
- Air Quality Index (AQI): $aqi

TASK:
1. Greet the user warmly
2. Briefly summarize the current air quality situation based on the AQI value
3. Provide 2-3 specific, actionable prevention measures if needed (based on AQI level)
4. Invite them to ask questions about air quality, respiratory health, prevention measures, or related topics

GUIDELINES:
- Keep response concise, friendly and under 150 words
- Use emojis sparingly for visual appeal
- Be encouraging and supportive
- Focus on practical, helpful information

Generate your greeting now:
''';

      final aiResponse = await _callAiApi(prompt);
      _addBotMessage(aiResponse);

    } catch (e) {
      debugPrint('❌ AI greeting error: $e');
      _addBotMessage(
        '✅ Sensor data loaded successfully!\n\nAsk me anything about air quality, respiratory health, or prevention measures. How can I help you today?',
      );
    }
  }

  String _parseValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) return value.toString();
    if (value is String) return value;
    return 'N/A';
  }

  Future<String> _callAiApi(String prompt) async {
    try {
      debugPrint('🤖 Calling AI API...');

      final response = await http.post(
        Uri.parse(_aiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': prompt}),
      ).timeout(const Duration(seconds: 30));

      debugPrint('🤖 AI API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          // Try different possible response keys
          final responseText = data['response']?.toString() ??
              data['text']?.toString() ??
              data['result']?.toString() ??
              data['answer']?.toString();

          if (responseText != null && responseText.isNotEmpty) {
            debugPrint('✅ AI response received');
            return responseText;
          }
        }

        return 'Sorry, I received an empty response. Please try asking again.';
      } else {
        debugPrint('❌ AI API error: ${response.statusCode}');
        return 'Sorry, I\'m having trouble connecting to my AI service (HTTP ${response.statusCode}). Please try again in a moment.';
      }
    } catch (e) {
      debugPrint('❌ AI API exception: $e');
      return 'Sorry, I\'m temporarily unable to connect to my AI service. Please check your internet connection and try again.';
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({
        'sender': 'bot',
        'text': text.trim(),
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text.trim(),
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _addUserMessage(trimmed);
    setState(() => _isLoading = true);

    final reply = await _generateAiResponse(trimmed);
    _addBotMessage(reply);

    setState(() => _isLoading = false);
  }

  Future<String> _generateAiResponse(String userQuestion) async {
    final temp = _sensorData != null ? _parseValue(_sensorData!['temp']) : 'N/A';
    final humidity = _sensorData != null ? _parseValue(_sensorData!['humidity']) : 'N/A';
    final aqi = _sensorData != null ? _parseValue(_sensorData!['air_quality']) : 'N/A';
    final distance = _sensorData != null ? _parseValue(_sensorData!['distance_km']) : 'N/A';

    final prompt = '''
You are AirBot, a helpful and knowledgeable air quality and respiratory health assistant.

CURRENT REAL-TIME SENSOR DATA (${distance}km from user):
- Temperature: ${temp}°C
- Humidity: ${humidity}%
- Air Quality Index (AQI): $aqi

USER QUESTION: "$userQuestion"

YOUR ROLE & SCOPE:
You are ONLY here to help with:
- Air quality and pollution (AQI, PM2.5, PM10, ozone, etc.)
- Respiratory health (asthma, COPD, breathing issues, cough, lung health)
- Prevention measures (masks, air purifiers, ventilation, indoor air quality)
- Environmental factors (humidity, temperature, weather impact on air quality)
- Health advice related to air quality and breathing
- Interpretation of the current sensor readings

IMPORTANT RULES:
1. **Context Detection**: Automatically determine if the user's question is related to your scope
   - If RELATED: Answer helpfully using current sensor data when relevant
   - If UNRELATED: Politely redirect them back to air quality/respiratory topics
   
2. **Use Real Data**: When answering, reference the current sensor readings if relevant to the question

3. **Health Advice**: Provide general prevention tips and health information, but NEVER give personalized medical diagnoses or prescriptions. Always recommend consulting a doctor for medical concerns.

4. **Be Helpful**: Give clear, practical, actionable advice

5. **Stay Concise**: Keep answers under 200 words, well-structured with bullet points when appropriate

6. **Be Encouraging**: Use a friendly, supportive tone

7. **No Off-Topic**: If the question is clearly unrelated (e.g., cooking, sports, entertainment), politely say:
   "I'm specifically designed to help with air quality and respiratory health topics. Please ask me something related to air pollution, breathing, AQI, prevention measures, or lung health! 😊"

Generate your response now:
''';

    return await _callAiApi(prompt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            if (_isLoading) _buildLoadingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'AirBot Assistant',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    if (_sensorData == null && !_isFetchingInitialData) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: _isFetchingInitialData
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Loading sensor data...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderMetric(
                icon: Icons.thermostat_rounded,
                label: 'Temp',
                value: '${_parseValue(_sensorData!['temp'])}°C',
                color: const Color(0xFFFF6B6B),
              ),
              _buildHeaderMetric(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: '${_parseValue(_sensorData!['humidity'])}%',
                color: const Color(0xFF4FC3F7),
              ),
              _buildHeaderMetric(
                icon: Icons.air_rounded,
                label: 'AQI',
                value: _parseValue(_sensorData!['air_quality']),
                color: const Color(0xFF00E676),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isBot = msg['sender'] == 'bot';

        return Align(
          alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isBot
                          ? [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.08),
                      ]
                          : [
                        const Color(0xFF00E676).withValues(alpha: 0.3),
                        const Color(0xFF00E676).withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isBot
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF00E676).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
                            size: 14,
                            color: isBot ? const Color(0xFF00E676) : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isBot ? 'AirBot' : 'You',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isBot ? const Color(0xFF00E676) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        msg['text'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: const Color(0xFF00E676),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'AirBot is thinking...',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E293B).withValues(alpha: 0.95),
                const Color(0xFF0F172A).withValues(alpha: 0.98),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Ask about air quality, health, prevention...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? LinearGradient(
                        colors: [
                          Colors.grey.shade600,
                          Colors.grey.shade700,
                        ],
                      )
                          : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF00E676),
                          Color(0xFF00C853),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isLoading
                          ? null
                          : [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isLoading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !_isLoading) {
      _controller.clear();
      _handleUserMessage(text);
    }
  }
}