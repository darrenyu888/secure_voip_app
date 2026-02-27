import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const SecureVoipApp());
}

class SecureVoipApp extends StatelessWidget {
  const SecureVoipApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asterisk 加密通訊',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SipPhoneScreen(),
    );
  }
}

class SipPhoneScreen extends StatefulWidget {
  const SipPhoneScreen({Key? key}) : super(key: key);

  @override
  State<SipPhoneScreen> createState() => _SipPhoneScreenState();
}

class _SipPhoneScreenState extends State<SipPhoneScreen> implements SipUaHelperListener {
  final SIPUAHelper _sipHelper = SIPUAHelper();
  Call? _currentCall;
  String _registrationStatus = "尚未註冊";
  
  // 視訊渲染器
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // ================= 你的伺服器設定 =================
  final String wssUrl = 'wss://uk01.888168.de:8089/ws'; // WSS 加密通道
  final String sipDomain = 'uk01.888168.de';
  final String myExtension = '9001'; // 測試分機
  final String myPassword = 'WebRTC_test_9001'; // 測試分機密碼
  // ==================================================

  final TextEditingController _targetExtController = TextEditingController(text: '9002');
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) {
      _initRenderers();
      _initSip();
    });
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  // 1. 要求相機與麥克風權限
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    
    if (statuses[Permission.camera]!.isGranted && statuses[Permission.microphone]!.isGranted) {
      setState(() { _hasPermissions = true; });
    } else {
      print("權限被拒絕！無法通話");
    }
  }

  // 2. 初始化畫面
  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // 3. 初始化 SIP 與 TLS 連線
  void _initSip() {
    _sipHelper.addSipUaHelperListener(this);
    UaSettings settings = UaSettings();
    
    settings.webSocketUrl = wssUrl;
    settings.webSocketSettings.allowBadCertificate = true; // 測試用，若憑證正常可設為 false
    settings.uri = 'sip:$myExtension@$sipDomain';
    settings.authorizationUser = myExtension;
    settings.password = myPassword;
    settings.displayName = 'DarrenPhone';
    settings.userAgent = 'Flutter_Secure_VoIP/1.0';

    _sipHelper.start(settings);
  }

  // 4. 撥打視訊電話
  void _makeCall(String targetExt) {
    if (!_hasPermissions) return;
    
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };
    
    _sipHelper.call(
      'sip:$targetExt@$sipDomain', 
      voiceOnly: false, 
      mediaStreamConstraints: mediaConstraints
    );
  }

  // 5. 接聽電話
  void _answerCall() {
    if (_currentCall != null) {
      final mediaConstraints = <String, dynamic>{'audio': true, 'video': true};
      _currentCall!.answer(_sipHelper.buildCallOptions(true), mediaStreamConstraints: mediaConstraints);
    }
  }

  // 6. 掛斷或拒接
  void _hangup() {
    if (_currentCall != null) {
      _currentCall!.hangup();
    }
  }

  // ================= SIP 事件回調 =================
  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _registrationStatus = state.state.toString();
    });
  }

  @override
  void callStateChanged(Call call, CallState state) {
    setState(() {
      _currentCall = call;
      if (state.state == CallStateEnum.ENDED || state.state == CallStateEnum.FAILED) {
        _currentCall = null;
        _localRenderer.srcObject = null;
        _remoteRenderer.srcObject = null;
      }
    });
  }

  @override
  void onCallStateChanged(Call call, CallState state) {
    if (state.state == CallStateEnum.STREAM) {
      if (call.stream != null) {
        _localRenderer.srcObject = call.stream;
      }
      if (call.remote_stream != null) {
        _remoteRenderer.srcObject = call.remote_stream;
      }
    }
  }

  @override void onNewMessage(SIPMessageRequest msg) {}
  @override void onNewReinvite(ReInvite event) {}
  @override void transportStateChanged(TransportState state) {}
  @override void onRegistrationStateChanged(RegistrationState state) {}
  @override void onNewInvite(ReInvite event) {}

  // ================= UI 介面 =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asterisk TLS 視訊通話')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('分機: $myExtension'),
                Text('狀態: $_registrationStatus', 
                  style: TextStyle(
                    color: _registrationStatus.contains('REGISTERED') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Colors.black,
                  child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  width: 100,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                    child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_currentCall != null && _currentCall!.state == CallStateEnum.PROGRESS) ...[
                  const Text('有人來電...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.green,
                        onPressed: _answerCall,
                        child: const Icon(Icons.call),
                      ),
                      FloatingActionButton(
                        backgroundColor: Colors.red,
                        onPressed: _hangup,
                        child: const Icon(Icons.call_end),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetExtController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '輸入目標分機 (例如: 9002)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FloatingActionButton(
                        backgroundColor: Colors.green,
                        onPressed: () => _makeCall(_targetExtController.text),
                        child: const Icon(Icons.video_call),
                      ),
                      const SizedBox(width: 10),
                      FloatingActionButton(
                        backgroundColor: Colors.red,
                        onPressed: _hangup,
                        child: const Icon(Icons.call_end),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}