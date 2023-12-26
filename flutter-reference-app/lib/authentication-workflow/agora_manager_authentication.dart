import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
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
        );

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
    // Retrieve a token from the server
    try {
      config['rtcToken'] = await fetchToken(localUid, channelName);
      // Proceed with token usage or further operations
    } catch (e) {
      // Handle the exception or display an error message
      messageCallback('Error fetching token');
      return;
    }
    // Join a Video SDK channel
    return super.join(
        channelName: channelName,
        token: config['rtcToken'],
        clientRole: isBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience);
  }

  Future<String> fetchToken(int uid, String channelName) async {
    // Set the token role,
    // Use 1 for Host/Broadcaster, 2 for Subscriber/Audience
    int tokenRole = isBroadcaster ? 1 : 2;

    // Prepare the Url
    String url = '${config['serverUrl']}/rtc/$channelName/'
        '${tokenRole.toString()}/uid/${uid.toString()}'
        '?expiry=${config['tokenExpiryTime'].toString()}';

    // Send the http GET request
    final response = await http.get(Uri.parse(url));

    // Read the response
    if (response.statusCode == 200) { // The server returned an OK response
      // Parse the JSON.
      Map<String, dynamic> json = jsonDecode(response.body);
      String newToken = json['rtcToken'];
      // Return the token
      return newToken;
    } else {
      // Throw an exception.
      throw Exception(
          'Failed to fetch a token. Make sure that your server URL is valid');
    }
  }

  void renewToken() async {
    String token;

    try { // Retrieve a token from the server
      token = await fetchToken(localUid, channelName);
    } catch (e) {
      // Handle the exception
      messageCallback('Error fetching token');
      return;
    }

    // Renew the token
    agoraEngine!.renewToken(token);
    messageCallback("Token renewed");
  }

  @override
  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        messageCallback('Token expiring...');
        renewToken();
        // Notify the UI through the eventCallback
        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["token"] = token;
        eventCallback("onTokenPrivilegeWillExpire", eventArgs);
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

  Future<void> joinChannelWithToken([String? channelName]) async {
    String token='';
    channelName ??= this.channelName;

    if (isValidURL(config['serverUrl'])) { // A valid server url is available
      // Retrieve a token from the server
      token = await fetchToken(localUid, channelName);
    } else { // use the token from the config.json file
      token = config['rtcToken'];
    }

    return join(
        channelName: channelName,
        token: token,
        clientRole: (isBroadcaster) ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience
    );
  }

  bool isValidURL(String urlString) {
    Uri? uri = Uri.tryParse(urlString);
    return uri != null && uri.isAbsolute;
  }

}
