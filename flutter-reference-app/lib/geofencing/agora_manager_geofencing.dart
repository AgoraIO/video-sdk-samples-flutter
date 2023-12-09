import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerGeofencing extends AgoraManagerAuthentication {
  AgoraManagerGeofencing({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerGeofencing
  }

  static Future<AgoraManagerGeofencing> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerGeofencing(
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

    // Define a set of areas using bitwise OR
    int myAreas = AreaCode.areaCodeEu.value() | AreaCode.areaCodeNa.value();

    await agoraEngine!
        .initialize(RtcEngineContext(areaCode: myAreas, appId: appId));

    messageCallback("Geofencing enabled");

    if (currentProduct != ProductName.voiceCalling) {
      await agoraEngine!.enableVideo();
    }

    // Register the event handler
    agoraEngine!.registerEventHandler(getEventHandler());
  }
}
