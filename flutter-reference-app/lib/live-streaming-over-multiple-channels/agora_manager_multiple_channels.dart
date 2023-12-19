import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerMultipleChannels extends AgoraManagerAuthentication {
  // Media relay
  String destinationChannelName = ""; // Name of the destination channel
  String destinationChannelToken = ""; // Access token for the destination channel
  int destinationChannelUid = 10; // Uid to identify the relay stream in the destination channel
  String sourceChannelToken = ""; // Access token for the source channel, Generate with the channelName and uid = 0.
  bool isMediaRelaying = false;
  ChannelMediaRelayState relayState = ChannelMediaRelayState.relayStateIdle;

  // Join a second channel
  late RtcEngineEx agoraEngineEx;
  late RtcConnection rtcSecondConnection; // Connection object for the second channel
  String secondChannelName = "demo2"; // Name of the second channel
  int secondChannelUid = 100; // User Id for the second channel
  String secondChannelToken = ""; // Access token for the second channel
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

  @override
  Future<void> initialize() async {
    await super.initialize();
    destinationChannelName = config["destinationChannelName"];
    destinationChannelUid = config["destinationChannelUid"];
    destinationChannelToken = config["destinationChannelToken"];
    sourceChannelToken = config["sourceChannelToken"];

    secondChannelName = config["secondChannelName"];
    secondChannelUid = config["secondChannelUid"];
    secondChannelToken = config["secondChannelToken"];
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
              channelName: destinationChannelName, // The name of the destination channel
              uid: destinationChannelUid, // The Uid to identify the relay stream in the destination channel
              token: destinationChannelToken // Token generated with the channelName and uid in destInfos
          )
        ],
        destCount: 1);

    // Start relaying media streams across channels
    agoraEngine?.startChannelMediaRelay(mediaRelayConfiguration);
  }

  Future<void> stopChannelRelay() async {
    agoraEngine?.stopChannelMediaRelay();
  }

  Future<void> joinSecondChannel() async {
    // Create an RtcEngineEx instance
    agoraEngineEx = createAgoraRtcEngineEx();
    await agoraEngineEx.initialize(RtcEngineContext(appId: appId));
    // Register the event handler
    agoraEngineEx.registerEventHandler(getEventHandler());

    // By default, the video module is disabled, call enableVideo to enable it.
    agoraEngineEx.enableVideo();

    ChannelMediaOptions mediaOptions;
    if (isBroadcaster) { // Host Role
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

    if (isValidURL(config['serverUrl'])) { // A valid server url is available
      // Retrieve a token from the server
      //secondChannelToken = "007eJxTYPga3lDaJR5pai6z4WDfBdWWwhS2L+V/Nnvd2GOSwnn62XIFBssUIxNLCwsLg1RLYxMzY6MkY4skg0Qzi7REozRDMyOjD1aNqQ2BjAyPduoxMTJAIIjPypCSmptvxMAAAGZCH7M=";
      secondChannelToken = await fetchToken(0, secondChannelName);
    } else { // use the token from the config.json file
      secondChannelToken = config['secondChannelToken'];
    }

    agoraEngineEx.joinChannelEx(
      token: secondChannelToken,
      connection: rtcSecondConnection,
      options: mediaOptions,
    );
  }

  void leaveSecondChannel() {
    agoraEngineEx.leaveChannelEx(
        connection: rtcSecondConnection
    );
    isSecondChannelJoined = false;
  }

  AgoraVideoView secondChannelVideo() {
    return AgoraVideoView(
      controller: VideoViewController.remote(
          rtcEngine: agoraEngineEx,
          canvas: VideoCanvas(
            uid: remoteUidSecondChannel,
            renderMode: RenderModeType.renderModeFit
          ),
          connection: rtcSecondConnection
      ),
    );
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
        if (connection.channelId == channelName) {
          super.getEventHandler().onConnectionStateChanged!(
              connection, state, reason);
        } else { // second channel
          if (reason ==
              ConnectionChangedReasonType.connectionChangedLeaveChannel) {
            remoteUidSecondChannel = null;
            isSecondChannelJoined = false;
          }
          Map<String, dynamic> eventArgs = {};
          eventCallback("secondChannelEvent", eventArgs);
        }
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        if (connection.channelId == channelName) {
          super.getEventHandler().onJoinChannelSuccess!(connection, elapsed);
        } else {
          messageCallback("Local user uid:${connection.localUid} joined the channel ${connection.channelId!}");
          isSecondChannelJoined = true;
          Map<String, dynamic> eventArgs = {};
          eventCallback("secondChannelEvent", eventArgs);
        }
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        if (connection.channelId == channelName) {
          super.getEventHandler().onUserJoined!(connection, remoteUid, elapsed);
        } else {
          remoteUidSecondChannel = remoteUid;
          Map<String, dynamic> eventArgs = {};
          eventCallback("secondChannelEvent", eventArgs);
        }
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        if (connection.channelId == channelName) {
          super.getEventHandler().onUserOffline!(connection, remoteUid, reason);
        } else {
          remoteUidSecondChannel = null;
          Map<String, dynamic> eventArgs = {};
          eventCallback("secondChannelEvent", eventArgs);
        }
      },
    );
  }
}
