import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerProductWorkflow extends AgoraManagerAuthentication {
  AgoraManagerProductWorkflow({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerProductWorkflow
  }

  static Future<AgoraManagerProductWorkflow> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerProductWorkflow(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  @override
  Future<void> setupAgoraEngine() async {
    // Retrieve or request camera and microphone permissions
    await [Permission.microphone, Permission.camera].request();

    // Create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();

    await agoraEngine!.initialize(RtcEngineContext(appId: appId));

    if (currentProduct != ProductName.voiceCalling) {
      await agoraEngine!.enableVideo();
    }

    // Register the event handler
    agoraEngine!.registerEventHandler(getEventHandler());
  }

  void adjustVolume(int volume) {
    agoraEngine!.adjustRecordingSignalVolume(volume);
  }

    Future<void> startScreenShare() async {

    agoraEngine!.startScreenCapture(const ScreenCaptureParameters2(
        captureAudio: true,
        audioParams: ScreenAudioParameters(
            sampleRate: 16000, channels: 2, captureSignalVolume: 100),
        captureVideo: true,
        videoParams: ScreenVideoParameters(
            dimensions: VideoDimensions(height: 1280, width: 720),
            frameRate: 15,
            bitrate: 600)));

    updateChannelMediaOptions(true);
  }

  void updateChannelMediaOptions(bool isScreenShared) {
    // Update channel media options to publish camera or screen capture streams
    ChannelMediaOptions options = ChannelMediaOptions(
      publishCameraTrack: !isScreenShared,
      publishMicrophoneTrack: !isScreenShared,
      publishScreenTrack: isScreenShared,
      publishScreenCaptureAudio: isScreenShared,
      publishScreenCaptureVideo: isScreenShared,
    );

    agoraEngine!.updateChannelMediaOptions(options);
  }

  AgoraVideoView getLocalScreenView() {
    return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: agoraEngine!,
          canvas: const VideoCanvas(
            uid: 0,
            sourceType: VideoSourceType.videoSourceScreen,
          ),
        ));
  }

  void mute(bool enableMute) {
    agoraEngine!.muteAllRemoteAudioStreams(enableMute);
  }

  Future<void> stopScreenShare() async {
    await agoraEngine!.stopScreenCapture();
    updateChannelMediaOptions(false);
  }
}
