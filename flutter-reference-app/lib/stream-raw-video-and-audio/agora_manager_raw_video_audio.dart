import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerRawVideoAudio extends AgoraManagerAuthentication {
  AgoraManagerRawVideoAudio({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerRawVideoAudio
  }

  static Future<AgoraManagerRawVideoAudio> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerRawVideoAudio(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  AudioFrameObserver audioFrameObserver = AudioFrameObserver(
      onRecordAudioFrame: (String channelId, AudioFrame audioFrame) {
        // Gets the captured audio frame
      },
      onPlaybackAudioFrame: (String channelId, AudioFrame audioFrame) {
        // Gets the audio frame for playback
        debugPrint('[onPlaybackAudioFrame] audioFrame: ${audioFrame.toJson()}');
      }
  );

  VideoFrameObserver videoFrameObserver = VideoFrameObserver(
      onCaptureVideoFrame: (VideoSourceType videoSourceType, VideoFrame videoFrame) {
        // The video data that this callback gets has not been pre-processed
        // After pre-processing, you can send the processed video data back
        // to the SDK through this callback
        debugPrint('[onCaptureVideoFrame] videoFrame: ${videoFrame.toJson()}');
      },
      onRenderVideoFrame: (String channelId, int remoteUid, VideoFrame videoFrame) {
        // Occurs each time the SDK receives a video frame sent by the remote user.
        // In this callback, you can get the video data before encoding.
        // You then process the data according to your particular scenario.
      }
  );

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

    // Set the format of raw audio data.
    int sampleRate = 16000, sampleNumOfChannels = 1, samplesPerCall = 1024;

    agoraEngine!.setRecordingAudioFrameParameters(
        sampleRate: sampleRate,
        channel: sampleNumOfChannels,
        mode: RawAudioFrameOpModeType.rawAudioFrameOpModeReadWrite,
        samplesPerCall: samplesPerCall);

    agoraEngine!.setPlaybackAudioFrameParameters(
        sampleRate: sampleRate,
        channel: sampleNumOfChannels,
        mode: RawAudioFrameOpModeType.rawAudioFrameOpModeReadWrite,
        samplesPerCall: samplesPerCall);

    agoraEngine!.setMixedAudioFrameParameters(
        sampleRate: sampleRate,
        channel: sampleNumOfChannels,
        samplesPerCall: samplesPerCall);

    agoraEngine!.getMediaEngine().registerAudioFrameObserver(audioFrameObserver);
    agoraEngine!.getMediaEngine().registerVideoFrameObserver(videoFrameObserver);
  }

  @override
  Future<void> leave() async {
    agoraEngine!.getMediaEngine().unregisterAudioFrameObserver(audioFrameObserver);
    agoraEngine!.getMediaEngine().unregisterVideoFrameObserver(videoFrameObserver);
    super.leave();
  }

}
