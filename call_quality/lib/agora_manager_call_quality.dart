import 'package:agora_manager/agora_manager.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:authentication_workflow/agora_manager_authentication.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerCallQuality extends AgoraManagerAuthentication {
  int networkQuality = 0; // Quality index of the network connection
  int counter = 0; // Controls the frequency of notifications
  String qualityStatsSummary = "";

  AgoraManagerCallQuality({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
    eventCallback,
  }) : super(
    currentProduct: currentProduct,
    messageCallback: messageCallback,
    eventCallback: eventCallback,
  ) {
    // Additional initialization specific to AgoraManagerCallQuality
  }

  static Future<AgoraManagerCallQuality> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
    eventCallback,
  }) async {
    final manager = AgoraManagerCallQuality(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  @override
  Future<void> setupVideoSDKEngine() async {
    // Retrieve or request camera and microphone permissions
    await [Permission.microphone, Permission.camera].request();

    // Create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(appId: config['appId']));

    await agoraEngine.enableVideo();

    // Enable the dual stream mode
    agoraEngine.enableDualStreamMode(enabled: true);

    // Set audio profile and audio scenario.
    agoraEngine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom);

    // Set the video configuration
    VideoEncoderConfiguration videoConfig = const VideoEncoderConfiguration(
        mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
        frameRate: 10,
        bitrate: standardBitrate,
        dimensions: VideoDimensions(width: 640, height: 360),
        orientationMode: OrientationMode.orientationModeAdaptive,
        degradationPreference: DegradationPreference.maintainBalanced);

    // Apply the configuration
    agoraEngine.setVideoEncoderConfiguration(videoConfig);

    // Start the probe test
    startProbeTest();

    // Register the event handler
    agoraEngine.registerEventHandler(getEventHandler());
  }

  void startProbeTest() {
    // Configure the probe test
    LastmileProbeConfig config = const LastmileProbeConfig(
      probeUplink: true,
      probeDownlink: true,
      expectedUplinkBitrate: 100000,  // Range 100000-5000000 bps
      expectedDownlinkBitrate: 100000, // Range 100000-5000000 bps
    );
    agoraEngine.startLastmileProbeTest(config);
    messageCallback("Running the last mile probe test ...");
  }

  @override
  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      onConnectionStateChanged: (RtcConnection connection,
          ConnectionStateType state, ConnectionChangedReasonType reason) {
        messageCallback(
            "Connection state changed\n New state: ${state.name}\n Reason: ${reason.name}");
        super.getEventHandler().onConnectionStateChanged!(connection, state, reason);
      },
      onLastmileQuality: (QualityType quality) {
        networkQuality = quality.index;
        Map<String, dynamic> eventArgs = {};
        eventArgs["quality"] = quality;
        eventCallback("onLastmileQuality", eventArgs);
      },
      onLastmileProbeResult: (LastmileProbeResult result) {
        agoraEngine.stopLastmileProbeTest();
        // The result object contains the detailed test results that help you
        // manage call quality, for example, the down link jitter.
        messageCallback("Downlink jitter: ${result.downlinkReport?.jitter}");
      },
      onNetworkQuality: (RtcConnection connection, int remoteUid,
          QualityType txQuality, QualityType rxQuality) {
        // Use downlink network quality to update the network status
        networkQuality = rxQuality.index;

        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["remoteUid"] = remoteUid;
        eventArgs["txQuality"] = txQuality;
        eventArgs["rxQuality"] = rxQuality;
        eventCallback("onNetworkQuality", eventArgs);
      },
      onRtcStats: (RtcConnection connection, RtcStats stats) {
        counter += 1;
        String msg = "";

        if (counter == 5) {
          msg = "${stats.userCount} user(s)";
        } else if (counter == 10) {
          msg = "Packet loss rate: ${stats.rxPacketLossRate}";
          counter = 0;
        }
        if (msg.isNotEmpty) messageCallback(msg);
      },
      onRemoteVideoStateChanged: (RtcConnection connection,
          int remoteUid,
          RemoteVideoState state,
          RemoteVideoStateReason reason,
          int elapsed) {
        String msg = "Remote video state changed: \n Uid: $remoteUid"
            " \n NewState: $state\n reason: $reason\n elapsed: $elapsed";
        messageCallback(msg);
      },
      onRemoteVideoStats: (RtcConnection connection, RemoteVideoStats stats) {
        qualityStatsSummary =
        "Renderer frame rate: ${stats.rendererOutputFrameRate}"
            "\nReceived bitrate: ${stats.receivedBitrate}"
            "\nPublish duration: ${stats.publishDuration}"
            "\nFrame loss rate: ${stats.frameLossRate}";

        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["stats"] = stats;
        eventCallback("onRemoteVideoStats", eventArgs);
      },
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        super.getEventHandler().onTokenPrivilegeWillExpire!(connection, token);
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        super.getEventHandler().onJoinChannelSuccess!(connection, elapsed);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        super.getEventHandler().onUserJoined!(connection, remoteUid, elapsed);
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        super.getEventHandler().onUserOffline!(connection, remoteUid, reason);
      },
    );
  }

  void setVideoQuality(bool isHighQuality) {
    if (isHighQuality) {
      agoraEngine.setRemoteVideoStreamType(uid: remoteUid!,
          streamType: VideoStreamType.videoStreamHigh);
    } else {
      agoraEngine.setRemoteVideoStreamType(uid: remoteUid!,
          streamType: VideoStreamType.videoStreamLow);
    }
  }

}
