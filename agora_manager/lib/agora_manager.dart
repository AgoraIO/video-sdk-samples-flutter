library agora_manager;

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManager {
  String appId = "", token = "", channelName = "";
  int uid = 0;
  int? remoteUid; // uid of the remote user
  bool isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance

  Function(String message) messageCallback;
  Function(String eventName, Map<String, dynamic> eventArgs) eventCallback;

  AgoraManager._({
    required this.messageCallback,
    required this.eventCallback,
  });

  static Future<AgoraManager> create({
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManager._(
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager._initialize();
    return manager;
  }

  Future<void> _initialize() async {
    try {
      String configString = await rootBundle
          .loadString('packages/agora_manager/assets/config/config.json');
      Map<String, dynamic> configData = jsonDecode(configString);
      appId = configData['appId'];
      token = configData['token'];
      channelName = configData['channelName'];
      uid = configData['uid'];
    } catch (e) {
      messageCallback(e.toString());
    }
  }

  Future<void> setupVideoSDKEngine() async {
    // retrieve or request camera and microphone permissions
    await [Permission.microphone, Permission.camera].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(appId: appId));

    await agoraEngine.enableVideo();

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state,
            ConnectionChangedReasonType reason){
          messageCallback('Connection state: ${state}, reason: ${reason}');
          Map<String, dynamic> eventArgs = {};
          eventArgs["connection"] = connection;
          eventArgs["state"] = state;
          eventArgs["reason"] = reason;
          eventCallback("onConnectionStateChanged", eventArgs);
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          isJoined = true;
          messageCallback(
              "Local user uid:${connection.localUid} joined the channel");
          Map<String, dynamic> eventArgs = {};
          eventArgs["connection"] = connection;
          eventArgs["elapsed"] = elapsed;
          eventCallback("onJoinChannelSuccess", eventArgs);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          this.remoteUid = remoteUid;
          messageCallback("Remote user uid:$remoteUid joined the channel");
          Map<String, dynamic> eventArgs = {};
          eventArgs["connection"] = connection;
          eventArgs["remoteUid"] = remoteUid;
          eventArgs["elapsed"] = elapsed;
          eventCallback("onUserJoined", eventArgs);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          this.remoteUid = null;
          messageCallback("Remote user uid:$remoteUid left the channel");
          Map<String, dynamic> eventArgs = {};
          eventArgs["connection"] = connection;
          eventArgs["remoteUid"] = remoteUid;
          eventArgs["reason"] = reason;
          eventCallback("onJoinChannelSuccess", eventArgs);
        },
      ),
    );
  }

  Future<void> join() async {
    await agoraEngine.startPreview();

    // Set channel options including the client role and channel profile
    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );

    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );
  }

  void leave() {
    if (isJoined) agoraEngine.leaveChannel();
    isJoined = false;
  }

  Future<void> dispose() async {
    leave();
    agoraEngine.release();
  }
}
