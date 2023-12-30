import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerCustomVideoAudio extends AgoraManagerAuthentication {
  Uint8List? _imageByteData;
  int? _imageWidth;
  int? _imageHeight;
  int audioTrackId = -1;
  bool isAudioTrackSetup = false;

  AgoraManagerCustomVideoAudio({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerCustomVideoAudio
  }

  static Future<AgoraManagerCustomVideoAudio> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerCustomVideoAudio(
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

    // Register the event handler
    agoraEngine!.registerEventHandler(getEventHandler());

    await agoraEngine!
        .getMediaEngine()
        .setExternalVideoSource(enabled: true, useTexture: false);

    if (currentProduct != ProductName.voiceCalling) {
      await agoraEngine!.enableVideo();
    }

    await _loadImageByteData();

    await agoraEngine!
        .startPreview(sourceType: VideoSourceType.videoSourceCustom);
  }

  Future<void> setupCustomAudioTrack() async {
    // Create a custom audio track
    audioTrackId = await agoraEngine!.getMediaEngine().createCustomAudioTrack(
        trackType: AudioTrackType.audioTrackDirect,
        config: const AudioTrackConfig(
          enableLocalPlayback: true,
        ));

    // Set channel media options to publish the custom audio track
    ChannelMediaOptions channelMediaOptions = ChannelMediaOptions(
        publishCustomAudioTrackId: audioTrackId,
        publishMicrophoneTrack: false,
        publishCustomAudioTrack: true);

    // Update channel media options
    agoraEngine!.updateChannelMediaOptions(channelMediaOptions);
  }

  Future<void> _loadImageByteData() async {
    ByteData data = await rootBundle.load("assets/agora.png");
    Uint8List bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    ui.Image image = await decodeImageFromList(bytes);

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);

    _imageByteData = byteData!.buffer.asUint8List();
    _imageWidth = image.width;
    _imageHeight = image.height;
    image.dispose();
  }

  Future<void> pushVideoFrame() async {
    ExternalVideoFrame agoraFrame = ExternalVideoFrame(
        type: VideoBufferType.videoBufferRawData,
        format: VideoPixelFormat.videoPixelRgba,
        buffer: _imageByteData,
        stride: _imageWidth,
        height: _imageHeight,
        timestamp: DateTime.now().millisecondsSinceEpoch);

    await agoraEngine!.getMediaEngine().pushVideoFrame(frame: agoraFrame);
  }

  Future<void> pushAudioFrame() async {
    if (!isAudioTrackSetup) {
      await setupCustomAudioTrack();
      isAudioTrackSetup = true;
    }

    Uint8List buffer = Uint8List(100);
    // Read the custom audio into a buffer
    buffer = fillBuffer();

    // Create an audio frame from the buffer
    AudioFrame audioFrame = AudioFrame(
      type: AudioFrameType.frameTypePcm16,
      buffer: buffer, // data buffer of the audio frame.
      samplesPerChannel: 1024, // number of samples per channel
      channels: 2, // use 1 for mono, 2 for stereo
      bytesPerSample: BytesPerSample.twoBytesPerSample,
      samplesPerSec: 16000,
      renderTimeMs: DateTime.now().millisecondsSinceEpoch, // time stamp
    );

    // Push the audio frame
    await agoraEngine!.getMediaEngine().pushAudioFrame(
      frame: audioFrame,
      trackId: audioTrackId,
    );
  }

  Uint8List fillBuffer() {
    Uint8List buffer = Uint8List(100);
    // Function to fill the buffer with audio samples (e.g., a sine wave)
    const int sampleRate = 16000;
    const double frequency = 440.0; // Frequency of the sine wave in Hz
    const double amplitude = 0.5;
    const double twoPi = 2.0 * pi;

    for (int i = 0; i < buffer.length; i += 4) {
      double time = i / (4 * sampleRate);

      // Calculate samples for left and right channels of a stereo signal
      double leftValue = amplitude * sin(twoPi * frequency * time);
      double rightValue = amplitude * sin(twoPi * frequency * 2 * time);

      // Convert the double values to 16-bit signed integers
      int leftSample = (leftValue * 32767).toInt();
      int rightSample = (rightValue * 32767).toInt();

      // Write the interleaved samples to the buffer (assuming little-endian format)
      buffer[i] = leftSample & 0xFF;
      buffer[i + 1] = (leftSample >> 8) & 0xFF;
      buffer[i + 2] = rightSample & 0xFF;
      buffer[i + 3] = (rightSample >> 8) & 0xFF;
    }
    return buffer;
  }

  @override
  AgoraVideoView localVideoView() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: agoraEngine!,
        canvas: const VideoCanvas(
          uid: 0,
          mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
          renderMode: RenderModeType.renderModeFit,
          sourceType: VideoSourceType.videoSourceCustom,
        ), // Use uid = 0 for local view
      ),
    );
  }
}
