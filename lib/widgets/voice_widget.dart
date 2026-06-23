import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:omiku/services/whisper_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum ScreenState {
  connecting,
  listeningIdle,
  listeningSpeaking,
  thinking,
  thoughtBubble,
  voiceSelection,
}

enum VoiceInteractionMode { pushToTalk, live }

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  late final VoiceSessionController _controller;
  ScreenState _currentScreenState = ScreenState.voiceSelection;
  String _selectedVoice = 'alloy'; // Standard OpenAI voice
  String _selectedModel = VoiceSessionController.defaultRealtimeModel;
  VoiceInteractionMode _interactionMode = VoiceInteractionMode.pushToTalk;

  late AnimationController _visualizerAnimationController;
  late AnimationController _connectingAnimationController;
  late AnimationController _speakingCircleAnimationController;
  late AnimationController _thinkingDotsAnimationController;
  late AnimationController _voiceBarsAnimationController;

  final List<double> _barHeights = List.generate(7, (index) => 0.0);
  bool _isAiSpeaking = false;

  @override
  void initState() {
    super.initState();

    _controller = VoiceSessionController(
      onAiSpeakingStatusChanged: (isSpeaking) {
        if (mounted) {
          setState(() => _isAiSpeaking = isSpeaking);
          if (_interactionMode == VoiceInteractionMode.live) {
            if (isSpeaking &&
                _currentScreenState != ScreenState.thoughtBubble) {
              _navigateTo(ScreenState.thoughtBubble);
            } else if (!isSpeaking &&
                _currentScreenState == ScreenState.thoughtBubble) {
              _navigateTo(ScreenState.listeningIdle);
            }
          }
          if (!isSpeaking && _currentScreenState == ScreenState.thoughtBubble) {
            _navigateTo(ScreenState.listeningIdle);
          }
        }
      },
      onAudioChunk: (pcmChunk) {
        _updateVisualizerWithPcm(pcmChunk);
      },
    );

    _visualizerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _connectingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _speakingCircleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _thinkingDotsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _voiceBarsAnimationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          if (_currentScreenState == ScreenState.listeningSpeaking) {
            _simulateUserSpeakingBars();
          }
        });

    _initSession();
  }

  Future<void> _initSession() async {
    await _controller.initialize();
    _navigateTo(ScreenState.listeningIdle);
  }

  @override
  void dispose() {
    _controller.dispose();
    _visualizerAnimationController.dispose();
    _connectingAnimationController.dispose();
    _speakingCircleAnimationController.dispose();
    _thinkingDotsAnimationController.dispose();
    _voiceBarsAnimationController.dispose();
    super.dispose();
  }

  void _simulateUserSpeakingBars() {
    setState(() {
      final double wave =
          (sin(_voiceBarsAnimationController.value * pi * 2 * 3) + 1) / 2;
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = wave * 0.6 + (Random().nextDouble() * 0.4);
      }
    });
  }

  void _updateVisualizerWithPcm(Uint8List pcm) {
    if (_currentScreenState != ScreenState.thoughtBubble || !mounted) return;
    if (pcm.length < 2) return;

    int samples = pcm.length ~/ 2;
    double sumSq = 0;

    for (int i = 0; i < samples; i += 32) {
      if ((i * 2 + 1) >= pcm.length) break;
      final lo = pcm[i * 2];
      final hi = pcm[i * 2 + 1];
      int s = (hi << 8) | lo;
      if (s > 32767) s -= 65536;
      final v = s / 32768.0;
      sumSq += v * v;
    }
    final rms = sqrt(sumSq / max(1, samples ~/ 32)).clamp(0.0, 1.0);

    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] =
            (0.3 + rms * 0.7) *
            (0.6 + 0.4 * sin(i + DateTime.now().millisecondsSinceEpoch / 200));
      }
    });
  }

  void _navigateTo(ScreenState newState) {
    if (!mounted) return;
    setState(() => _currentScreenState = newState);

    _connectingAnimationController.stop();
    _speakingCircleAnimationController.stop();
    _voiceBarsAnimationController.stop();
    _visualizerAnimationController.stop();

    switch (newState) {
      case ScreenState.connecting:
        _connectingAnimationController.repeat(
          period: const Duration(seconds: 2),
        );
        break;
      case ScreenState.listeningIdle:
        _visualizerAnimationController.forward(from: 0.0);
        break;
      case ScreenState.listeningSpeaking:
        _speakingCircleAnimationController.repeat(reverse: true);
        _voiceBarsAnimationController.repeat(
          period: const Duration(milliseconds: 900),
        );
        break;
      case ScreenState.thinking:
        _speakingCircleAnimationController.value = 1.0;
        _thinkingDotsAnimationController.repeat(reverse: true);
        break;
      case ScreenState.thoughtBubble:
        _visualizerAnimationController.forward(from: 0.0);
        break;
      case ScreenState.voiceSelection:
        _visualizerAnimationController.forward(from: 0.0);
        break;
    }
  }

  Future<void> _connect() async {
    _navigateTo(ScreenState.connecting);
    try {
      await _controller.connect(
        model: _selectedModel,
        voice: _selectedVoice,
        mode: _interactionMode,
      );
      if (!mounted) return;
      _navigateTo(ScreenState.listeningIdle);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connect failed: $e')));
      _navigateTo(ScreenState.voiceSelection);
    }
  }

  void _showDevLogs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryBackground,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Dev Logs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _controller.clearLogs(),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Clear',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: _controller.logs,
                    builder: (context, logs, _) {
                      if (logs.isEmpty) {
                        return const Center(child: Text('No logs yet'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: logs.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            logs[i],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSessionSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryBackground,
      builder: (_) {
        var tmpModel = _selectedModel;
        var tmpVoice = _selectedVoice;
        var tmpMode = _interactionMode;
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Session',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: tmpModel,
                      decoration: const InputDecoration(
                        labelText: 'Realtime model',
                      ),
                      items: VoiceSessionController.availableRealtimeModels
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => tmpModel = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tmpVoice,
                      decoration: const InputDecoration(labelText: 'Voice'),
                      items:
                          const [
                                'alloy',
                                'ash',
                                'ballad',
                                'coral',
                                'echo',
                                'sage',
                                'shimmer',
                                'verse',
                              ]
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => tmpVoice = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VoiceInteractionMode>(
                      initialValue: tmpMode,
                      decoration: const InputDecoration(labelText: 'Mode'),
                      items: const [
                        DropdownMenuItem(
                          value: VoiceInteractionMode.pushToTalk,
                          child: Text('Push-to-talk'),
                        ),
                        DropdownMenuItem(
                          value: VoiceInteractionMode.live,
                          child: Text('Live (auto VAD)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => tmpMode = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          setState(() {
                            _selectedModel = tmpModel;
                            _selectedVoice = tmpVoice;
                            _interactionMode = tmpMode;
                          });
                          await _connect();
                        },
                        child: const Text('Apply & reconnect'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _startTalk() async {
    try {
      if (_interactionMode == VoiceInteractionMode.live) return;
      await _controller.interrupt();
      await _controller.startRecording();
      _navigateTo(ScreenState.listeningSpeaking);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _finishTalk() async {
    if (_interactionMode == VoiceInteractionMode.live) return;
    _navigateTo(ScreenState.thinking);
    try {
      await _controller.stopRecordingAndFetchResponse();

      _navigateTo(ScreenState.thoughtBubble);
    } catch (e) {
      debugPrint("Error in finish talk: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      _navigateTo(ScreenState.listeningIdle);
    }
  }

  Future<void> _cancel() async {
    await _controller.cancelRecording();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildScreenContent(),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showDevLogs,
                    icon: const Icon(Icons.bug_report_outlined),
                    tooltip: 'Dev logs',
                  ),
                  IconButton(
                    onPressed: _showSessionSettings,
                    icon: const Icon(Icons.tune),
                    tooltip: 'Session settings',
                  ),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: _controller.isConnected,
                    builder: (context, connected, _) {
                      return Text(
                        connected ? 'Connected' : 'Disconnected',
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      await _controller.disconnect();
                      if (!mounted) return;
                      _navigateTo(ScreenState.voiceSelection);
                    },
                    icon: const Icon(Icons.power_settings_new),
                    tooltip: 'Disconnect',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenContent() {
    switch (_currentScreenState) {
      case ScreenState.connecting:
        return _buildConnectingUI();
      case ScreenState.listeningIdle:
        return _buildListeningIdleUI();
      case ScreenState.listeningSpeaking:
        return _buildListeningSpeakingUI();
      case ScreenState.thinking:
        return _buildThinkingUI();
      case ScreenState.thoughtBubble:
        return _buildThoughtBubbleUI();
      case ScreenState.voiceSelection:
        return _buildVoiceSelectionUI();
    }
  }

  Widget _buildConnectingUI() {
    return Stack(
      key: const ValueKey('connecting'),
      children: [
        Center(
          child: AnimatedVoiceVisualizer(
            state: VoiceVisualizerState.connectingOval,
            animationController: _connectingAnimationController,
          ),
        ),
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: StatusTextAndIcon(text: 'Connecting'),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: BottomActionButton(
              icon: Icons.close_rounded,
              backgroundColor: AppColors.accentRed,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListeningIdleUI() {
    return Column(
      key: const ValueKey('listeningIdle'),
      children: [
        const Spacer(),
        Center(
          child: AnimatedVoiceVisualizer(
            state: VoiceVisualizerState.idleRoundedRects,
            animationController: _visualizerAnimationController,
          ),
        ),
        const SizedBox(height: 80),
        StatusTextAndIcon(
          text: _interactionMode == VoiceInteractionMode.live
              ? 'Listening (auto)'
              : 'Tap to speak',
          icon: Icons.mic_none,
        ),
        const Spacer(),
        BottomActionButtons(
          onRecordPause: _interactionMode == VoiceInteractionMode.live
              ? () async => _controller.interrupt()
              : _startTalk,
          onCancel: _cancel,
          recordButtonIcon: _interactionMode == VoiceInteractionMode.live
              ? Icons.stop_circle_outlined
              : Icons.mic,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildListeningSpeakingUI() {
    return Column(
      key: const ValueKey('listeningSpeaking'),
      children: [
        const Spacer(),
        Center(
          child: AnimatedVoiceVisualizer(
            state: VoiceVisualizerState.speakingCircle,
            animationController: _speakingCircleAnimationController,
          ),
        ),
        const SizedBox(height: 80),
        StatusTextAndIcon(text: 'Listening...', barHeights: _barHeights),
        const Spacer(),
        BottomActionButtons(
          onRecordPause: _finishTalk,
          onCancel: _cancel,
          recordButtonIcon: Icons.stop_circle_outlined,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildThinkingUI() {
    return Column(
      key: const ValueKey('thinking'),
      children: [
        const Spacer(),
        Center(
          child: AnimatedVoiceVisualizer(
            state: VoiceVisualizerState.speakingCircle,
            animationController: _speakingCircleAnimationController,
          ),
        ),
        const SizedBox(height: 80),
        StatusTextAndIcon(
          text: 'Thinking...',
          animationController: _thinkingDotsAnimationController,
        ),
        const Spacer(),
        BottomActionButtons(
          onRecordPause: () {},
          onCancel: _cancel,
          recordButtonIcon: Icons.hourglass_empty,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildThoughtBubbleUI() {
    return Column(
      key: const ValueKey('thoughtBubble'),
      children: [
        const Spacer(),
        Center(
          child: AnimatedVoiceVisualizer(
            state: VoiceVisualizerState.thoughtBubble,
            animationController: _visualizerAnimationController,
          ),
        ),
        const SizedBox(height: 80),
        StatusTextAndIcon(
          text: _isAiSpeaking ? 'AI is speaking...' : 'Done',
          barHeights: _barHeights,
        ),
        const Spacer(),
        BottomActionButtons(
          onRecordPause: _interactionMode == VoiceInteractionMode.live
              ? () async => _controller.interrupt()
              : _startTalk,
          onCancel: _cancel,
          recordButtonIcon: _interactionMode == VoiceInteractionMode.live
              ? Icons.stop_circle_outlined
              : Icons.mic,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVoiceSelectionUI() {
    return Column(
      key: const ValueKey('voiceSelection'),
      children: [
        AppBar(
          title: const Text('Choose a voice'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: _showDevLogs,
            ),
          ],
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedModel,
                      decoration: const InputDecoration(
                        labelText: 'Realtime model',
                      ),
                      items: VoiceSessionController.availableRealtimeModels
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedModel = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VoiceInteractionMode>(
                      initialValue: _interactionMode,
                      decoration: const InputDecoration(labelText: 'Mode'),
                      items: const [
                        DropdownMenuItem(
                          value: VoiceInteractionMode.pushToTalk,
                          child: Text('Push-to-talk'),
                        ),
                        DropdownMenuItem(
                          value: VoiceInteractionMode.live,
                          child: Text('Live (auto VAD)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _interactionMode = v);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedVoiceVisualizer(
                    state: VoiceVisualizerState.idleCircles,
                    animationController: _visualizerAnimationController,
                  ),
                ),
              ),
              VoiceSelectionList(
                selectedVoice: _selectedVoice,
                onVoiceSelected: (v) => setState(() => _selectedVoice = v),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ConfirmButton(onPressed: _connect),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Add this import at the top of your file
// Remove 'package:record/record.dart' if you no longer use it elsewhere.

class VoiceSessionController {
  static const defaultRealtimeModel = 'gpt-realtime-mini';
  static const availableRealtimeModels = <String>[
    'gpt-realtime',
    'gpt-realtime-mini',
    'gpt-4o-realtime-preview',
    'gpt-4o-mini-realtime-preview',
  ];

  // --- CHANGED: Use FlutterSoundRecorder instead of AudioRecorder ---
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();

  bool _pendingSpeakOff = false;
  static const int _sampleRateHz = 24000;
  static const int _channels = 1;

  // --- CHANGED: StreamController to handle live audio data ---
  StreamController<Uint8List>? _recordingDataController;
  StreamSubscription? _recordingDataSubscription;

  StreamSink<Uint8List>? _playerSink;
  final bool _playerOpened = false;
  bool _recorderOpened = false;
  Timer? _speakOffTimer;

  String _currentModel = defaultRealtimeModel;

  // Handlers
  // EventHandlerCallback? _conversationUpdatedHandler;
  // EventHandlerCallback? _conversationCompletedHandler;
  // EventHandlerCallback? _conversationInterruptedHandler;
  // EventHandlerCallback? _speechStoppedHandler;
  // EventHandlerCallback? _errorHandler;
  // EventHandlerCallback? _allEventsHandler;

  String? _currentAssistantItemId;
  int _playedSamples = 0;
  VoiceInteractionMode _mode = VoiceInteractionMode.pushToTalk;

  final ValueNotifier<List<String>> logs = ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  final void Function(bool isSpeaking)? onAiSpeakingStatusChanged;
  final void Function(Uint8List pcmChunk)? onAudioChunk;

  String? _currentRecordingPath;

  VoiceSessionController({this.onAiSpeakingStatusChanged, this.onAudioChunk});

  Future<void> initialize() async {
    // 1. Setup Audio Session (Crucial for duplex audio - hearing while speaking)
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    // // 2. Initialize Player
    // if (!_playerOpened) {
    //   await _soundPlayer.openPlayer();
    //   _playerOpened = true;
    // }

    // 3. Initialize Recorder
    if (!_recorderOpened) {
      await _recorder.openRecorder();
      _recorderOpened = true;
    }

    // Start player stream immediately (waiting for data)
    // await _soundPlayer.startPlayerFromStream(
    //   codec: Codec.pcm16,
    //   interleaved: true,
    //   numChannels: _channels,
    //   sampleRate: _sampleRateHz,
    //   bufferSize: 8192,
    // );
    _playerSink = _soundPlayer.uint8ListSink;

    // _realtimeClient = RealtimeClient(apiKey: Cfg.current.key);
    // _setupRealtimeHandlers();
  }

  void _log(String msg) {
    final ts = DateTime.now().toIso8601String();
    final next = [...logs.value, '[$ts] $msg'];
    logs.value = next.length > 400 ? next.sublist(next.length - 400) : next;
  }

  void clearLogs() => logs.value = const [];

  Future<void> connect({
    required String model,
    required String voice,
    required VoiceInteractionMode mode,
  }) async {
    _mode = mode;
    // final targetVoice = _voiceFromName(voice);

    final modelChanged = model != _currentModel;
    // if (_realtimeClient.isConnected() && modelChanged) {
    //   _log('Model changed -> reconnect ($model)');
    //   await disconnect();
    // }

    _currentModel = model;
    // _currentVoice = targetVoice;

    try {
      _log(
        'Connecting realtime: model=$_currentModel /*voice=\${_currentVoice.name}*/ mode=$_mode',
      );
      // if (!_realtimeClient.isConnected()) {
      //   await _realtimeClient.connect(model: _currentModel);
      // }
      // await _realtimeClient.updateSession(
      //   voice: _currentVoice,
      //   turnDetection: _mode == VoiceInteractionMode.live
      //       ? const TurnDetection(type: TurnDetectionType.serverVad)
      //       : null,
      // );
      // await _realtimeClient.waitForSessionCreated();
      isConnected.value = true;
      _log('Realtime connected');

      if (_mode == VoiceInteractionMode.live) {
        await startLive();
      } else {
        await stopLive();
      }
    } catch (e) {
      isConnected.value = false;
      _log('Connect error: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      _log('Disconnecting realtime');
      await stopLive();
      // if (_realtimeClient.isConnected()) {
      //   await _realtimeClient.disconnect();
      // }
    } finally {
      isConnected.value = false;
      _currentAssistantItemId = null;
      _playedSamples = 0;
    }
  }

  // --- Push-to-Talk Logic ---
  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission denied');
    }

    final dir = await getTemporaryDirectory();
    _currentRecordingPath = p.join(
      dir.path,
      'user_audio_${DateTime.now().millisecondsSinceEpoch}.pcm',
    );

    // CHANGED: Use FlutterSoundRecorder to file
    await _recorder.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );
  }

  String finalTranscribe = '';
  WhisperService whisperService = WhisperService();
  Future<void> stopRecordingAndFetchResponse() async {
    try {
      // CHANGED: Stop FlutterSoundRecorder
      await _recorder.stopRecorder();

      if (_currentRecordingPath == null) {
        throw Exception("No recording path found");
      }

      // final audioBytes = await file.readAsBytes();
      // final audioBase64 = base64Encode(audioBytes);

      // await _connectRealtime(voice: voice);
      final t = await whisperService.transcribe(_currentRecordingPath!);
      finalTranscribe = t ?? "";
      onAiSpeakingStatusChanged?.call(true);
      // await _realtimeClient.sendUserMessageContent(
      //   [ContentPart.inputAudio(audio: audioBase64)],
      // );
    } finally {
      _currentRecordingPath = null;
    }
  }

  Future<void> cancelRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
    _currentRecordingPath = null;
  }

  // --- Live Mode Logic ---
  Future<void> startLive() async {
    if (_recorder.isRecording) return; // Already recording

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission denied');
    }

    _log('Starting live mic stream (pcm16 24k)');

    // 1. Create a StreamController to receive data from recorder
    _recordingDataController = StreamController<Uint8List>();

    // 2. Listen to the controller and send data to OpenAI
    _recordingDataSubscription = _recordingDataController!.stream.listen((
      chunk,
    ) {
      // if (_realtimeClient.isConnected()) {
      //   // Send to OpenAI (fire and forget)
      //   _realtimeClient.appendInputAudio(chunk);
      // }
    }, onError: (e) => _log('Mic stream error: $e'));

    // 3. Start Recorder writing to the controller's sink
    await _recorder.startRecorder(
      toStream: _recordingDataController!.sink,
      codec: Codec.pcm16,
      sampleRate: 24000,
      numChannels: 1,
      audioSource: AudioSource.voice_communication,
    );
  }

  Future<void> stopLive() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
    await _recordingDataSubscription?.cancel();
    await _recordingDataController?.close();
    _recordingDataSubscription = null;
    _recordingDataController = null;
  }

  // --- Helpers & Clean up ---

  // Voice _voiceFromName(String voice) {
  //   return Voice.values.firstWhere(
  //     (v) => v.name.toLowerCase() == voice.toLowerCase(),
  //     orElse: () => Voice.alloy,
  //   );
  // }

  // Future<void> _connectRealtime({String? voice}) async {
  //   final targetVoice = voice != null ? _voiceFromName(voice) : _currentVoice;
  //   _currentVoice = targetVoice;

  //   if (!_realtimeClient.isConnected()) {
  //     await _realtimeClient.connect(model: _currentModel);
  //   }
  //   await _realtimeClient.updateSession(voice: _currentVoice);
  //   await _realtimeClient.waitForSessionCreated();
  // }

  // void _setupRealtimeHandlers() {
  //   _allEventsHandler = (event) async {
  //     switch (event) {
  //       case RealtimeEventResponseAudioDelta e:
  //         final approxBytes = (e.delta.length * 3) ~/ 4;
  //         _log('${e.type.name}: item=${e.itemId} ~${approxBytes}B');
  //         return;
  //       case RealtimeEventResponseTextDelta e:
  //         _log('${e.type.name}: "${e.delta}"');
  //         return;
  //       default:
  //         _log(event.type.name);
  //         return;
  //     }
  //   };
  //   // _realtimeClient.on(RealtimeEventType.all, _allEventsHandler!);

  //   _errorHandler = (event) async {
  //     _log('Realtime error: ${jsonEncode(event.toJson())}');
  //     isConnected.value = false;
  //   };
  //   _realtimeClient.on(RealtimeEventType.error, _errorHandler!);

  //   _conversationUpdatedHandler = (event) async {
  //     final ev = event as RealtimeEventConversationUpdated;
  //     final delta = ev.result.delta;
  //     final audio = delta?.audio;
  //     final itemId = ev.result.item?.item.id;
  //     if (audio != null && audio.isNotEmpty) {
  //       onAiSpeakingStatusChanged?.call(true);
  //       if (itemId != null) {
  //         if (_currentAssistantItemId != itemId) {
  //           _currentAssistantItemId = itemId;
  //           _playedSamples = 0;
  //           await _resetPlayback();
  //         }
  //       }
  //       _appendPcm(audio);
  //       _playedSamples += audio.lengthInBytes ~/ 2;
  //       onAudioChunk?.call(audio);
  //     }
  //   };

  //   _conversationCompletedHandler = (event) async {
  //     _pendingSpeakOff = true;
  //     _speakOffTimer?.cancel();
  //     _speakOffTimer = Timer(const Duration(milliseconds: 250), () {
  //       if (!_pendingSpeakOff) return;
  //       _pendingSpeakOff = false;
  //       onAiSpeakingStatusChanged?.call(false);
  //     });
  //   };

  //   _conversationInterruptedHandler = (event) async {
  //     _log('Conversation interrupted -> cancelResponse');
  //     await interrupt();
  //   };

  //   _speechStoppedHandler = (event) async {
  //     if (_mode != VoiceInteractionMode.live) return;
  //     _log('Speech stopped -> createResponse');
  //     await _realtimeClient.createResponse();
  //   };

  //   _realtimeClient.on(
  //     RealtimeEventType.conversationUpdated,
  //     _conversationUpdatedHandler!,
  //   );
  //   _realtimeClient.on(
  //     RealtimeEventType.conversationItemCompleted,
  //     _conversationCompletedHandler!,
  //   );
  //   _realtimeClient.on(
  //     RealtimeEventType.conversationInterrupted,
  //     _conversationInterruptedHandler!,
  //   );
  //   _realtimeClient.on(
  //     RealtimeEventType.inputAudioBufferSpeechStopped,
  //     _speechStoppedHandler!,
  //   );
  // }

  Future<void> interrupt() async {
    // if (!_realtimeClient.isConnected()) return;
    try {
      await _resetPlayback();
      // Sending samples played helps the AI know where it was interrupted
      // await _realtimeClient.cancelResponse(
      //   _currentAssistantItemId,
      //   _playedSamples,
      // );
    } catch (e) {
      _log('cancelResponse failed: $e');
      // await _realtimeClient.cancelResponse(null);
    } finally {
      onAiSpeakingStatusChanged?.call(false);
    }
  }

  void _appendPcm(Uint8List pcm) {
    _pendingSpeakOff = false;
    _speakOffTimer?.cancel();
    final sink = _playerSink;
    if (sink == null) return;
    sink.add(pcm);
  }

  Future<void> _resetPlayback() async {
    _pendingSpeakOff = false;
    _speakOffTimer?.cancel();
    _speakOffTimer = null;
    _playerSink = null;
    try {
      await _soundPlayer.stopPlayer();
    } catch (_) {}

    try {
      await _soundPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        interleaved: true,
        numChannels: _channels,
        sampleRate: _sampleRateHz,
        bufferSize: 8192,
      );
      _playerSink = _soundPlayer.uint8ListSink;
    } catch (e) {
      _log('Sound player restart error: $e');
    }
  }

  void dispose() {
    _recorder.closeRecorder(); // Dispose recorder
    _soundPlayer.closePlayer(); // Dispose player

    _recordingDataSubscription?.cancel();
    _recordingDataController?.close();

    _speakOffTimer?.cancel();

    // // Remove handlers
    // if (_conversationUpdatedHandler != null) {
    //   // _realtimeClient.off(
    //   //   RealtimeEventType.conversationUpdated,
    //   //   _conversationUpdatedHandler!,
    //   // );
    // }
    // if (_conversationCompletedHandler != null) {
    //   // _realtimeClient.off(
    //   //   RealtimeEventType.conversationItemCompleted,
    //   //   _conversationCompletedHandler!,
    //   // );
    // }
    // if (_conversationInterruptedHandler != null) {
    //   // _realtimeClient.off(
    //   //   RealtimeEventType.conversationInterrupted,
    //   //   _conversationInterruptedHandler!,
    //   // );
    // }
    // if (_speechStoppedHandler != null) {
    //   // _realtimeClient.off(
    //   //   RealtimeEventType.inputAudioBufferSpeechStopped,
    //   //   _speechStoppedHandler!,
    //   // );
    // }
    // if (_errorHandler != null) {
    //   // _realtimeClient.off(RealtimeEventType.error, _errorHandler!);
    // }
    // if (_allEventsHandler != null) {
    //   // _realtimeClient.off(RealtimeEventType.all, _allEventsHandler!);
    // }

    unawaited(disconnect());
  }
}

enum VoiceVisualizerState {
  idleCircles,
  idleRoundedRects,
  connectingOval,
  speakingCircle,
  thoughtBubble,
}

class BottomActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double size;
  final double iconSize;

  const BottomActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    this.size = 64.0,
    this.iconSize = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class BottomActionButtons extends StatelessWidget {
  final VoidCallback onRecordPause;
  final VoidCallback onCancel;
  final IconData recordButtonIcon;

  const BottomActionButtons({
    super.key,
    required this.onRecordPause,
    required this.onCancel,
    required this.recordButtonIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 56),
          BottomActionButton(
            icon: recordButtonIcon,
            onPressed: onRecordPause,
            backgroundColor: AppColors.cardBackground,
          ),
          BottomActionButton(
            icon: Icons.close_rounded,
            backgroundColor: AppColors.accentRed,
            onPressed: onCancel,
            size: 56.0,
            iconSize: 28.0,
          ),
        ],
      ),
    );
  }
}

class ConfirmButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ConfirmButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: const Text(
          'Confirm',
          style: TextStyle(
            color: AppColors.buttonText,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class AppColors {
  static const Color primaryBackground = Color(0xFF140D17);
  static const Color cardBackground = Color(0xFF201625);
  static const Color selectedCardBackground = Color(0xFF2E2333);
  static const Color accentRed = Color(0xFFDA2A39);
  static const Color buttonPrimary = Color(0xFFB1A2BB);
  static const Color buttonText = Color(0xFF201625);
  static const Color textLight = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFFA0A0A0);
}

class StatusTextAndIcon extends StatelessWidget {
  final String text;
  final IconData? icon;
  final List<double> barHeights;
  final AnimationController? animationController;

  const StatusTextAndIcon({
    super.key,
    required this.text,
    this.icon,
    this.barHeights = const [],
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (icon != null) {
      iconWidget = Icon(icon, color: AppColors.textLight, size: 24);
    } else if (barHeights.isNotEmpty) {
      iconWidget = _VoiceBars(barHeights: barHeights);
    } else if (animationController != null) {
      iconWidget = AnimatedBuilder(
        animation: animationController!,
        builder: (context, child) =>
            _ThinkingDots(animationValue: animationController!.value),
      );
    } else {
      iconWidget = const SizedBox(height: 24);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 24, child: iconWidget),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VoiceBars extends StatelessWidget {
  final List<double> barHeights;
  const _VoiceBars({required this.barHeights});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 24),
      painter: _VoiceBarsPainter(barHeights),
    );
  }
}

class _VoiceBarsPainter extends CustomPainter {
  final List<double> barHeights;
  _VoiceBarsPainter(this.barHeights);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.textLight;
    const double barWidth = 6.0;
    const double spacing = 4.0;
    const int numBars = 7;
    final double totalWidth = (barWidth * numBars) + (spacing * (numBars - 1));
    final double startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < numBars; i++) {
      double height =
          (barHeights.length > i ? barHeights[i] * size.height : 2.0).clamp(
            2.0,
            size.height,
          );
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + i * (barWidth + spacing),
          size.height - height,
          barWidth,
          height,
        ),
        const Radius.circular(3.0),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceBarsPainter oldDelegate) => true;
}

class _ThinkingDots extends StatelessWidget {
  final double animationValue;
  const _ThinkingDots({required this.animationValue});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 24),
      painter: _ThinkingDotsPainter(animationValue),
    );
  }
}

class _ThinkingDotsPainter extends CustomPainter {
  final double animationValue;
  _ThinkingDotsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.textLight;
    const double dotRadius = 4.0;
    const double spacing = 8.0;
    const int numDots = 5;
    final double totalWidth =
        (dotRadius * 2 * numDots) + (spacing * (numDots - 1));
    final double startX = (size.width - totalWidth) / 2 + dotRadius;
    final double centerY = size.height / 2;

    for (int i = 0; i < numDots; i++) {
      final double sineOffset = sin(
        animationValue * 2 * pi + (i * pi / (numDots - 1)),
      );
      final double yOffset = -4 * (sineOffset + 1) / 2;
      canvas.drawCircle(
        Offset(startX + i * (dotRadius * 2 + spacing), centerY + yOffset),
        dotRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingDotsPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class AnimatedVoiceVisualizer extends AnimatedWidget {
  final VoiceVisualizerState state;
  final AnimationController animationController;

  const AnimatedVoiceVisualizer({
    super.key,
    required this.state,
    required this.animationController,
  }) : super(listenable: animationController);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: CustomPaint(
        painter: _VoiceVisualizerPainter(
          state: state,
          animationValue: animationController.value,
        ),
      ),
    );
  }
}

class _VoiceVisualizerPainter extends CustomPainter {
  final VoiceVisualizerState state;
  final double animationValue;

  _VoiceVisualizerPainter({required this.state, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    switch (state) {
      case VoiceVisualizerState.idleCircles:
        _drawFourShapes(canvas, size, paint, isRoundedRects: false);
        break;
      case VoiceVisualizerState.idleRoundedRects:
        _drawFourShapes(canvas, size, paint, isRoundedRects: true);
        break;
      case VoiceVisualizerState.connectingOval:
        _drawConnectingOval(canvas, size, paint, animationValue);
        break;
      case VoiceVisualizerState.speakingCircle:
        _drawSpeakingCircle(canvas, size, paint, animationValue);
        break;
      case VoiceVisualizerState.thoughtBubble:
        _drawThoughtBubble(canvas, size, paint);
        break;
    }
  }

  void _drawFourShapes(
    Canvas canvas,
    Size size,
    Paint paint, {
    required bool isRoundedRects,
  }) {
    const int count = 4;
    final double totalWidth = size.width * 0.8;
    final double shapeSize = totalWidth / 4.5;
    final double spacing = (totalWidth - (shapeSize * count)) / (count - 1);
    final double startX = (size.width - totalWidth) / 2;
    final double centerY = size.height / 2;

    for (int i = 0; i < count; i++) {
      double x = startX + i * (shapeSize + spacing);
      if (isRoundedRects) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - shapeSize / 2, shapeSize, shapeSize),
          Radius.circular(shapeSize / 4),
        );
        canvas.drawRRect(rrect, paint);
      } else {
        canvas.drawCircle(
          Offset(x + shapeSize / 2, centerY),
          shapeSize / 2,
          paint,
        );
      }
    }
  }

  void _drawConnectingOval(
    Canvas canvas,
    Size size,
    Paint paint,
    double animValue,
  ) {
    final curvedValue = Curves.easeOutCubic.transform(animValue);
    final width = size.width * 0.4 + (size.width * 0.3 * curvedValue);
    final height = size.height * 0.6 + (size.height * 0.3 * curvedValue);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: width,
        height: height,
      ),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(rrect, paint);
  }

  void _drawSpeakingCircle(
    Canvas canvas,
    Size size,
    Paint paint,
    double animValue,
  ) {
    final radius = size.width * 0.45 * (0.98 + 0.02 * animValue);
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  void _drawThoughtBubble(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.8,
      height: size.height * 0.6,
    );
    path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(30.0)));
    path.addOval(
      Rect.fromCircle(
        center: Offset(rect.left + 30, rect.bottom - 10),
        radius: 15,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(rect.left + 15, rect.bottom + 5),
        radius: 8,
      ),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VoiceVisualizerPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.animationValue != animationValue;
}

class VoiceSelectionList extends StatelessWidget {
  final String selectedVoice;
  final ValueChanged<String> onVoiceSelected;
  final List<String> voices = const [
    'alloy',
    'echo',
    'shimmer',
    'ash',
    'coral',
    'sage',
  ];

  const VoiceSelectionList({
    super.key,
    required this.selectedVoice,
    required this.onVoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        children: voices.map((voice) {
          final isSelected = voice == selectedVoice;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Material(
              color: isSelected
                  ? AppColors.selectedCardBackground
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12.0),
              child: InkWell(
                onTap: () => onVoiceSelected(voice),
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        voice.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
