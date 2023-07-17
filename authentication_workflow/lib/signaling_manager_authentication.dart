import 'package:agora_manager/agora_manager.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AgoraManagerAuthentication extends AgoraManager {
  AgoraManagerAuthentication({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super.protectedConstructor(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerAuthentication
  }

  static Future<AgoraManagerAuthentication> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerAuthentication(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  Future<void> fetchTokenAndJoin(channelName) async {
    config['rtcToken'] = await fetchToken(config['uid'], channelName);
    return super.join(
        channelName: channelName,
        token: config['rtcToken'],
        clientRole: isBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience);
  }

  Future<String> fetchToken(int uid, String channelName) async {
    int tokenRole = isBroadcaster
        ? 1
        : 2; // use 1 for Host/Broadcaster, 2 for Subscriber/Audience

    // Prepare the Url
    String url =
        '${config['serverUrl']}/rtc/$channelName/${tokenRole.toString()}/uid/${uid.toString()}?expiry=${config['tokenExpiryTime'].toString()}';

    // Send the request
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server returns an OK response, then parse the JSON.
      Map<String, dynamic> json = jsonDecode(response.body);
      String newToken = json['rtcToken'];
      // Update the config
      config['channelName'] = channelName;
      config['uid'] = uid;
      // Use the token to join a channel or renew an expiring token
      return newToken;
    } else {
      // Throw an exception.
      throw Exception(
          'Failed to fetch a token. Make sure that your server URL is valid');
    }
  }

  void renewToken() async {
    String token = await fetchToken(config['uid'], config['channelName']);
    // Renew the token
    agoraEngine.renewToken(token);
    messageCallback("Token renewed");
  }

  @override
  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        renewToken()
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
