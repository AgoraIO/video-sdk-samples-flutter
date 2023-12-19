import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';

class AgoraManagerCloudProxy extends AgoraManagerAuthentication {
  bool directConnectionFailed = false;

  AgoraManagerCloudProxy({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
    eventCallback,
  }) : super(
    currentProduct: currentProduct,
    messageCallback: messageCallback,
    eventCallback: eventCallback,
  ) {
    // Additional initialization specific to AgoraManagerCloudProxy
  }

  static Future<AgoraManagerCloudProxy> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
    eventCallback,
  }) async {
    final manager = AgoraManagerCloudProxy(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  @override
  Future<void> joinChannelWithToken([String? channelName]) async {
    // Check if a proxy connection is required
    if (directConnectionFailed) {
      // Start cloud proxy service and set automatic UDP mode.
      try {
        agoraEngine?.setCloudProxy(CloudProxyType.udpProxy);
        messageCallback("Proxy service setup successful");
      } catch (exception) {
        messageCallback("Proxy service setup failed with exception: $exception");
      }
    }
    return super.joinChannelWithToken(channelName);
  }

  @override
  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      // Occurs when the network connection state changes
      onConnectionStateChanged: (RtcConnection connection,
          ConnectionStateType state, ConnectionChangedReasonType reason) {
        if (state == ConnectionStateType.connectionStateFailed
            && reason == ConnectionChangedReasonType.connectionChangedJoinFailed) {
          directConnectionFailed = true;
          messageCallback("Join failed, reason: $reason");
        }
        super.getEventHandler().onConnectionStateChanged!(connection, state, reason);
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
