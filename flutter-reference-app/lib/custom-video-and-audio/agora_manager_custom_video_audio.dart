import 'package:image/image.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerCustomVideoAudio extends AgoraManagerAuthentication {
  Uint8List? _imageByteData;
  int? _imageWidth;
  int? _imageHeight;

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

    await agoraEngine!.getMediaEngine()
        .setExternalVideoSource(enabled: true, useTexture: false);

    if (currentProduct != ProductName.voiceCalling) {
      await agoraEngine!.enableVideo();
    }

    _loadImageByteData();

    // Register the event handler
    agoraEngine!.registerEventHandler(getEventHandler());
  }

  Future<void> _loadImageByteData() async {
    ByteData data = await rootBundle.load("assets/agora.png");
    Uint8List bytes =
    data.buffer.asUint8List(data.offsetInBytes,
        data.lengthInBytes);

    final image = await decodeImageFromList(bytes);

    final byteData =
    await image.toByteData(
        format: ImageByteFormat.rawStraightRgba);
    _imageByteData = byteData!.buffer.asUint8List();
    _imageWidth = image.width;
    _imageHeight = image.height;
    image.dispose();
  }

  Future<void> _pushVideoFrame() async {

    ExternalVideoFrame agoraFrame = ExternalVideoFrame(
        type: VideoBufferType.videoBufferRawData,
        format: VideoPixelFormat.videoPixelRgba,
        buffer: _imageByteData,
        stride: _imageWidth,
        height: _imageHeight,
        timestamp: DateTime.now().millisecondsSinceEpoch);

    await agoraEngine!.getMediaEngine().pushVideoFrame(
        frame: agoraFrame);
  }

}
