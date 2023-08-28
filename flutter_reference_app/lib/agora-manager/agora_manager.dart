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
  late Map<String, dynamic> config;
  ProductName currentProduct = ProductName.videoCalling;
  int localUid = -1;
  String appId ="", channelName = "";
  List<int> remoteUids = []; // Uids of remote users in the channel
  bool isJoined = false; // Indicates if the local user has joined the channel
  bool isBroadcaster = true; // Client role
  RtcEngine? agoraEngine; // Agora engine instance

  Function(String message) messageCallback;
  Function(String eventName, Map<String, dynamic> eventArgs) eventCallback;

  AgoraManager.protectedConstructor({
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
    final manager = AgoraManager.protectedConstructor(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  Future<void> initialize() async {
    try {
      String configString = await rootBundle
          .loadString('assets/config/config.json');
      config = jsonDecode(configString);
      appId = config["appId"];
      channelName = config["channelName"];
      localUid = config["uid"];
    } catch (e) {
      messageCallback(e.toString());
    }
  }

  AgoraVideoView remoteVideoView(int remoteUid) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: agoraEngine!,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: channelName),
      ),
    );
  }

  AgoraVideoView localVideoView() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: agoraEngine!,
        canvas: const VideoCanvas(uid: 0), // Always set uid = 0 for local view
      ),
    );
  }

  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      onConnectionStateChanged: (RtcConnection connection,
          ConnectionStateType state, ConnectionChangedReasonType reason) {
        if (reason ==
            ConnectionChangedReasonType.connectionChangedLeaveChannel) {
          remoteUids.clear();
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
        remoteUids.add(remoteUid);
        messageCallback("Remote user uid:$remoteUid joined the channel");
        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["remoteUid"] = remoteUid;
        eventArgs["elapsed"] = elapsed;
        eventCallback("onUserJoined", eventArgs);
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        remoteUids.remove(remoteUid);
        messageCallback("Remote user uid:$remoteUid left the channel");
        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["remoteUid"] = remoteUid;
        eventArgs["reason"] = reason;
        eventCallback("onUserOffline", eventArgs);
      },
    );
  }

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

  Future<void> join({
    String channelName = '',
    String token = '',
    int uid = -1,
    ClientRoleType clientRole = ClientRoleType.clientRoleBroadcaster,
  }) async {
    channelName = (channelName.isEmpty) ? this.channelName : channelName;
    token = (token.isEmpty) ? config['rtcToken'] : token;
    uid = (uid == -1) ? localUid : uid;

    if (agoraEngine == null) await setupAgoraEngine();

    await agoraEngine!.startPreview();
    // Set channel options including the client role and channel profile
    ChannelMediaOptions options = ChannelMediaOptions(
      clientRoleType: clientRole,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );

    await agoraEngine!.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );
  }

  Future<void> leave() async {
    remoteUids.clear();
    isJoined = false;
    await agoraEngine!.leaveChannel();
    // Destroy the engine instance
    destroyAgoraEngine();
  }

  void destroyAgoraEngine() {
    // Release the RtcEngine instance to free up resources
    agoraEngine!.release();
    agoraEngine = null;
  }

  Future<void> dispose() async {
    await leave();
    agoraEngine!.release();
    agoraEngine = null;
  }
}
