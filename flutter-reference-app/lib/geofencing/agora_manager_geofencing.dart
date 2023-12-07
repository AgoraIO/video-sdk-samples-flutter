import 'dart:ffi';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerGeofencing extends AgoraManagerAuthentication {
  bool directConnectionFailed = false;

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

    // Your app will only connect to Agora SD-RTN located in North America.
    // Define a set of flags using bitwise OR
    int myFlags = AreaCode.areaCodeGlob.value() | AreaCode.areaCodeCn.value() ;

    // Exclude a specific value using bitwise NOT and bitwise AND
    int excludedValue = myFlags & ~AreaCode.areaCodeIn.value();

    await agoraEngine!.initialize(RtcEngineContext(
        areaCode: AreaCode.areaCodeNa.value(),
        appId: appId
    ));

    if (currentProduct != ProductName.voiceCalling) {
      await agoraEngine!.enableVideo();
    }

    // Register the event handler
    agoraEngine!.registerEventHandler(getEventHandler());
  }

  @override
  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      // Occurs when the network connection state changes
      onConnectionStateChanged: (RtcConnection connection,
          ConnectionStateType state, ConnectionChangedReasonType reason) {
        if (state == ConnectionStateType.connectionStateFailed &&
            reason == ConnectionChangedReasonType.connectionChangedJoinFailed) {
          directConnectionFailed = true;
          messageCallback("Join failed, reason: $reason");
        }
        super.getEventHandler().onConnectionStateChanged!(
            connection, state, reason);
      },
      onProxyConnected: (String channel, int uid, ProxyType proxyType,
          String localProxyIp, int elapsed) {
        messageCallback("Connected to ${proxyType.toString()}");
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
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        super.getEventHandler().onUserOffline!(connection, remoteUid, reason);
      },
    );
  }
}
