import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';

class AgoraManagerMediaStreamEncryption extends AgoraManagerAuthentication {
  // A 32-byte string for encryption.
  String encryptionKey = "";
  // A 32-byte string in Base64 format for encryption.
  String encryptionSaltBase64 = "";

  AgoraManagerMediaStreamEncryption({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerMediaStreamEncryption
  }

  static Future<AgoraManagerMediaStreamEncryption> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerMediaStreamEncryption(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  @override
  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      // Occurs when the network connection state changes
      onConnectionStateChanged: (RtcConnection connection,
          ConnectionStateType state, ConnectionChangedReasonType reason) {
        super.getEventHandler().onConnectionStateChanged!(
            connection, state, reason);
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
