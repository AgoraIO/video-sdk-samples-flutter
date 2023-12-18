import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerMultipleChannels extends AgoraManagerAuthentication {
  // Media relay
  String destChannelName = "demo2"; //"<name of the destination channel>";
  String destChannelToken = "007eJxTYJA3XzgpX9lBhT/F8VKw3QPXRTxN+iZ/zMxtnl8+dNbwVK0Cg2WKkYmlhYWFQaqlsYmZsVGSsUWSQaKZRVqiUZqhmZHRVbmG1IZARobfXrNZGRkgEMRnZUhJzc03YmAAAJDtHUI="; //"<access token for the destination channel>";
  int destUid = 10; // Uid to identify the relay stream in the destination channel
  String sourceChannelToken = "007eJxTYHjexO611O/vlhAmmaOzLOKOHe2pTU17++XoI0Mv4TTZ+WoKDJYpRiaWFhYWBqmWxiZmxkZJxhZJBolmFmmJRmmGZkZG/fINqQ2BjAw2F61YGRkgEMRnZ0hJzc03NDJmYAAAcvsemA=="; //"<access token for the source channel>"; // Generate with the channelName and uid = 0.
  bool isMediaRelaying = false;
  ChannelMediaRelayState relayState = ChannelMediaRelayState.relayStateIdle;

  // Join a second channel
  late RtcEngineEx agoraEngineEx;
  late RtcConnection rtcSecondConnection; // Connection object for the second channel
  String secondChannelName = "<name of the second channel>";
  int secondChannelUid = 100; // User Id for the second channel
  String secondChannelToken = "<access token for the second channel>";
  bool isSecondChannelJoined = false; // Track connection state of the second channel
  int? remoteUidSecondChannel; // User Id of the remote user on the second channel


  AgoraManagerMultipleChannels({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerMultipleChannels
  }

  static Future<AgoraManagerMultipleChannels> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerMultipleChannels(
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

    await agoraEngine!
        .initialize(RtcEngineContext(appId: appId));

    if (currentProduct != ProductName.voiceCalling) {
      await agoraEngine!.enableVideo();
    }

    // Register the event handler
    agoraEngine!.registerEventHandler(getEventHandler());
  }

  Future<void> startChannelRelay() async {
    // Define the channel media relay configuration
    ChannelMediaRelayConfiguration mediaRelayConfiguration =
    ChannelMediaRelayConfiguration(
        srcInfo: ChannelMediaInfo(
            channelName: channelName, // Default value is NULL, which means the SDK applies the name of the current channel
            uid: 0, // You must set it as 0 which means the SDK generates a random uid
            token: sourceChannelToken // token generated with the channelName and uid in srcInfo
        ), //
        destInfos: [
          ChannelMediaInfo(
              channelName: destChannelName, // The name of the destination channel
              uid: destUid, // The Uid to identify the relay stream in the destination channel
              token: destChannelToken // Token generated with the channelName and uid in destInfos
          )
        ],
        destCount: 1);

    // Start relaying media streams across channels
    agoraEngine?.startChannelMediaRelay(mediaRelayConfiguration);
  }

  Future<void> stopChannelRelay() async {
    agoraEngine?.stopChannelMediaRelay();
  }

  void joinSecondChannel() async {
    // Create an RtcEngineEx instance
    agoraEngineEx = createAgoraRtcEngineEx();
    await agoraEngineEx.initialize(RtcEngineContext(appId: appId));
    // Register the event handler
    agoraEngineEx.registerEventHandler(secondChannelEventHandler);
    // By default, the video module is disabled, call enableVideo to enable it.
    agoraEngineEx.enableVideo();

    if (isSecondChannelJoined) {
      agoraEngineEx.leaveChannelEx(
          connection: rtcSecondConnection
      );
      setState(() {
        isSecondChannelJoined = false;
      });
    } else {
      ChannelMediaOptions mediaOptions;
      if (_isHost) { // Host Role
        mediaOptions = const ChannelMediaOptions(
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting);
      } else { // Audience Role
        mediaOptions = const ChannelMediaOptions(
            autoSubscribeAudio: true,
            autoSubscribeVideo: true,
            clientRoleType: ClientRoleType.clientRoleAudience,
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting
        );
      }

      rtcSecondConnection = RtcConnection(
          channelId: secondChannelName,
          localUid: secondChannelUid
      );

      agoraEngine.joinChannelEx(
        token: secondChannelToken,
        connection: rtcSecondConnection,
        options: mediaOptions,
      );

      isSecondChannelJoined = true;
    }
  }

  @override
  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      onChannelMediaRelayStateChanged: (ChannelMediaRelayState state, ChannelMediaRelayError error) {
        relayState = state;
        // Notify the UI through the eventCallback
        Map<String, dynamic> eventArgs = {};
        eventArgs["state"] = state;
        eventArgs["error"] = error;
        eventCallback("onChannelMediaRelayStateChanged", eventArgs);

        if (state == ChannelMediaRelayState.relayStateRunning) {
          isMediaRelaying = true;
          messageCallback("Channel media relay running.");
        } else {
          isMediaRelaying = false;
          messageCallback("Relay state:\n$state\n ${error.toString()}") ;
        }
      },
      onChannelMediaRelayEvent: (ChannelMediaRelayEvent mediaRelayEvent) {
        // This example displays messages when relay events occur.
        // A production level app needs to handle these events properly.
        if (mediaRelayEvent == ChannelMediaRelayEvent.relayEventNetworkConnected) {
          messageCallback("Network connected");
        } else {
          messageCallback(mediaRelayEvent.toString());
        }
      },
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        super.getEventHandler().onTokenPrivilegeWillExpire!(connection, token);
      },
      onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
        super.getEventHandler().onConnectionStateChanged!(connection, state, reason);
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        super.getEventHandler().onJoinChannelSuccess!(connection, elapsed);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        super.getEventHandler().onUserJoined!(connection, remoteUid, elapsed);
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        super.getEventHandler().onUserOffline!(connection, remoteUid, reason);
      },
    );
  }
}
