import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// my Agora App ID 
const String appId = "6a13a5e2830e40518478c5f48149bda5"; 

//  my Agora Temporary Token 
const String token = "007eJxTYGjavU/217Pc16X72RUvc2ax17k9/cqV9O6bq8v3HrlXCiIKDGaJhsaJpqlGFsYGqSYGpoYWJuYWyaZpJhaGJpZJKYmmNwMXZTUEMjLcCI1kZmSAQBCfh8E5IzMvtThVISQxJ5uBAQCFDCJ/"; 

void main() => runApp(const MaterialApp(
      home: HSKClassHomePage(),
      debugShowCheckedModeBanner: false,
    ));

class HSKClassHomePage extends StatefulWidget {
  const HSKClassHomePage({super.key});

  @override
  State<HSKClassHomePage> createState() => _HSKClassHomePageState();
}

class _HSKClassHomePageState extends State<HSKClassHomePage> {
  final _channelController = TextEditingController(text: "hsk1_room");

  Future<void> _join() async {
    // Request camera and microphone permissions
    await [Permission.camera, Permission.microphone].request();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          channelName: _channelController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HSK 1 Video Class (တရုတ်စာ အတန်း)')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Laoshi နှင့် အတန်းဖော်များအတွက် အခန်းနာမည်ထည့်ပါ",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _channelController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Channel Name (ဥပမာ - hsk1_room)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _join,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Join Class (အတန်းသို့ဝင်မည်)',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  const VideoCallScreen({super.key, required this.channelName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  bool _isJoined = false;
  int? _remoteUid;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Initialize the RtcEngine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    // Join the channel using App ID, Channel Name, and Token
    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Classroom: ${widget.channelName}')),
      body: Stack(
        children: [
          Center(child: _renderRemoteVideo()),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 120,
              height: 160,
              padding: const EdgeInsets.all(4),
              child: _isJoined
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          _toolbar(),
        ],
      ),
    );
  }

  Widget _renderRemoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Text(
        'Laoshi (သို့မဟုတ်) အတန်းဖော်များကို စောင့်နေပါသည်...',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      );
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isMuted = !_isMuted;
              });
              _engine.muteLocalAudioStream(_isMuted);
            },
            child: Icon(_isMuted ? Icons.mic_off : Icons.mic),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Icon(Icons.call_end, color: Colors.white),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              _engine.switchCamera();
            },
            child: const Icon(Icons.switch_camera),
          ),
        ],
      ),
    );
  }
}