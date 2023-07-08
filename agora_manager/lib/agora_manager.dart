library agora_manager;

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

enum ProductName {
  videoCalling,
  voiceCalling,
  interactiveLiveStreaming,
  broadcastStreaming
}

class AgoraManager {
  ProductName currentProduct = ProductName.videoCalling;
  String appId = "", token = "", channelName = "";
  int uid = 0;
  int? remoteUid; // uid of the remote user
  bool isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance

  Function(String message) messageCallback;
  Function(String eventName, Map<String, dynamic> eventArgs) eventCallback;

  AgoraManager._({
    required this.currentProduct,
    required this.messageCallback,
    required this.eventCallback,
  });

  static Future<AgoraManager> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManager._(
      currentProduct: currentProduct,
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

  AgoraVideoView remoteVideoView() {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: agoraEngine,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: channelName),
      ),
    );
  }

  AgoraVideoView localVideoView() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: agoraEngine,
        canvas: const VideoCanvas(uid: 0), // always set uid = 0 for local view
      ),
    );
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
        onConnectionStateChanged: (RtcConnection connection,
            ConnectionStateType state, ConnectionChangedReasonType reason) {
          //messageCallback('Connection state: ${state}, reason: ${reason}');
          if (reason ==
              ConnectionChangedReasonType.connectionChangedLeaveChannel) {
            remoteUid = null;
            isJoined = false;
          }
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

  Future<void> leave() async {
    remoteUid = null;
    isJoined = false;
    await agoraEngine.leaveChannel();
  }

  Future<void> dispose() async {
    await leave();
    agoraEngine.release();
  }
}
