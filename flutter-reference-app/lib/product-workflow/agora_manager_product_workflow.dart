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

  void adjustVolume(VolumeTypes volumeParameter, int volume) {
    switch (volumeParameter) {
      case VolumeTypes.playbackSignalVolume:
        agoraEngine?.adjustPlaybackSignalVolume(volume);
        break;
      case VolumeTypes.recordingSignalVolume:
        agoraEngine?.adjustRecordingSignalVolume(volume);
        break;
      case VolumeTypes.userPlaybackSignalVolume:
        if (remoteUids.isNotEmpty) {
          int remoteUid = remoteUids.first; // the uid of the remote user
          agoraEngine?.adjustUserPlaybackSignalVolume(
              uid: remoteUid, volume: volume);
        }
        break;
      case VolumeTypes.audioMixingVolume:
        agoraEngine?.adjustAudioMixingVolume(volume);
        break;
      case VolumeTypes.audioMixingPlayoutVolume:
        agoraEngine?.adjustAudioMixingPlayoutVolume(volume);
        break;
      case VolumeTypes.audioMixingPublishVolume:
        agoraEngine?.adjustAudioMixingPublishVolume(volume);
        break;
      case VolumeTypes.customAudioPlayoutVolume:
        int trackId = 0; // use the id of your custom audio track
        agoraEngine?.adjustCustomAudioPlayoutVolume(
            trackId: trackId, volume: volume);
        break;
      case VolumeTypes.customAudioPublishVolume:
        int trackId = 0; // use the id of your custom audio track
        agoraEngine?.adjustCustomAudioPublishVolume(
            trackId: trackId, volume: volume);
        break;
    }
  }

  Future<void> startScreenShareWinMac() async {
    // Get the list of available windows and displays.
    List<ScreenCaptureSourceInfo> screenCaptureSourceList;
    screenCaptureSourceList = await agoraEngine!.getScreenCaptureSources(
        thumbSize: const SIZE(width: 360, height: 240),
        iconSize: const SIZE(width: 360, height: 240),
        includeScreen: false);

    // In a real-life app, you list the sources and let the user choose.
    // For this demo, get the sourceId of the last item in the list.
    int? sourceId = screenCaptureSourceList.last.sourceId ?? 0;

    // Share the entire screen or a particular window.
    if (screenCaptureSourceList.last.type == ScreenCaptureSourceType.screencapturesourcetypeScreen) {
      // The source is a screen
      agoraEngine!.startScreenCaptureByDisplayId(
          displayId: sourceId,
          regionRect: const Rectangle(),
          captureParams: const ScreenCaptureParameters(
            captureMouseCursor: true,
            frameRate: 30,
          ));
    } else {
      // The source is a window
      agoraEngine!.startScreenCaptureByWindowId(
          windowId: sourceId,
          regionRect: const Rectangle(),
          captureParams: const ScreenCaptureParameters(
            captureMouseCursor: true,
            frameRate: 30,
          ));
    }

    updateChannelMediaOptions(true);
  }

  Future<void> startScreenShare() async {
    agoraEngine?.startScreenCapture(const ScreenCaptureParameters2(
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

    agoraEngine?.updateChannelMediaOptions(options);
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

  void mute(bool muted) {
    // Stop or resume publishing the local audio stream
    agoraEngine?.muteLocalAudioStream(muted);
    // Stop or resume subscribing to the audio streams of all remote users
    agoraEngine?.muteAllRemoteAudioStreams(muted);
    // Stop or resume subscribing to the audio stream of a specified user
    // agoraEngine?.muteRemoteAudioStream(remoteUid, muted)
  }

  Future<void> stopScreenShare() async {
    await agoraEngine?.stopScreenCapture();
    updateChannelMediaOptions(false);
  }
}

enum VolumeTypes {
  playbackSignalVolume,
  recordingSignalVolume,
  userPlaybackSignalVolume,
  audioMixingVolume,
  audioMixingPlayoutVolume,
  audioMixingPublishVolume,
  customAudioPlayoutVolume,
  customAudioPublishVolume,
}
