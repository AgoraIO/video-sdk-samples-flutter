import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AgoraManagerRawVideoAudio extends AgoraManagerAuthentication {
  late File _audioFile;
  late AudioFrameObserver audioFrameObserver;
  late VideoFrameObserver videoFrameObserver;
  bool isRecording = false;

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

  Future<void> write(AudioFrame audioFrame) async {
    // Write the raw audio frame to a file for playback
    if (!isJoined || !isRecording) {
      return;
    }
    if (audioFrame.buffer != null) {
      await _audioFile.writeAsBytes(audioFrame.buffer!.toList(),
          mode: FileMode.append, flush: true);
    }
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

    // Set up your video frame observer
    videoFrameObserver = VideoFrameObserver(
        onCaptureVideoFrame: (VideoSourceType videoSourceType, VideoFrame videoFrame) {
          // The video data that this callback gets has not been pre-processed
          // After processing, you can send the processed video data back
          // to the SDK through this callback
          debugPrint('[onCaptureVideoFrame] videoFrame: ${videoFrame.toJson()}');
        },
        onRenderVideoFrame: (String channelId, int remoteUid, VideoFrame videoFrame) {
          // Occurs each time the SDK receives a video frame sent by a remote user.
          // In this callback, you can get the video data before encoding.
          // You then process the data according to your particular scenario.
        }
    );

    agoraEngine!.getMediaEngine().registerVideoFrameObserver(videoFrameObserver);
  }

  Future<void> startAudioFrameRecord() async {
    isRecording = true;
    // Set the format of raw audio data.
    int sampleRate = 16000, numberOfChannels = 1, samplesPerCall = 1024;

    Directory appDocDir = Platform.isAndroid
        ? (await getExternalStorageDirectory())!
        : await getApplicationDocumentsDirectory();

    _audioFile = File(path.join(appDocDir.absolute.path, 'record_audio.raw'));
    if (await _audioFile.exists()) {

      await _audioFile.delete();
    }
    await _audioFile.create();
    messageCallback('onRecordAudioFrame file output to: ${_audioFile.absolute.path}');

    audioFrameObserver =  AudioFrameObserver(
        onRecordAudioFrame: (String channelId, AudioFrame audioFrame) async {
          // Gets the captured audio frame
          await write(audioFrame);
        },
        onPlaybackAudioFrame: (String channelId, AudioFrame audioFrame) {
          // Gets the audio frame for playback
        },
        onEarMonitoringAudioFrame: (AudioFrame audioFrame) {
          // Gets the in-ear monitoring audio frame.
        },
        onMixedAudioFrame: (String channelId, AudioFrame audioFrame) {
          // Retrieves the mixed captured and playback audio frame
        },
        onPlaybackAudioFrameBeforeMixing: (String channelId, int uid, AudioFrame audioFrame) {
          // Retrieves the audio frame of a specified user before mixing
        }
    );

    agoraEngine!.getMediaEngine().registerAudioFrameObserver(audioFrameObserver);

    await agoraEngine!.setPlaybackAudioFrameParameters(
        sampleRate: sampleRate,
        channel: numberOfChannels,
        mode: RawAudioFrameOpModeType.rawAudioFrameOpModeReadOnly,
        samplesPerCall: samplesPerCall);

    await agoraEngine!.setRecordingAudioFrameParameters(
        sampleRate: sampleRate,
        channel: numberOfChannels,
        mode: RawAudioFrameOpModeType.rawAudioFrameOpModeReadOnly,
        samplesPerCall: samplesPerCall);

  }

  void stopAudioFrameRecord() {
    isRecording = false;
    agoraEngine!.getMediaEngine().unregisterAudioFrameObserver(audioFrameObserver);
  }

  @override
  Future<void> leave() async {
    // Unregister the video frame observer
    agoraEngine!.getMediaEngine().unregisterVideoFrameObserver(videoFrameObserver);
    super.leave();
  }

}
