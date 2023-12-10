import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';

class AgoraManagerSpatialAudio extends AgoraManagerAuthentication {
  late LocalSpatialAudioEngine localSpatial;

  AgoraManagerSpatialAudio({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
    eventCallback,
  }) : super(
    currentProduct: currentProduct,
    messageCallback: messageCallback,
    eventCallback: eventCallback,
  ) {
    // Additional initialization specific to AgoraManagerSpatialAudio
  }

  static Future<AgoraManagerSpatialAudio> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
    eventCallback,
  }) async {
    final manager = AgoraManagerSpatialAudio(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  void configureSpatialAudioEngine() async {
    // Enable spatial audio
    await agoraEngine!.enableSpatialAudio(true);

    // Get the spatial audio engine
    localSpatial = agoraEngine!.getLocalSpatialAudioEngine();

    // Initialize the spatial audio engine
    localSpatial.initialize();

    // Set the audio reception range of the local user in meters
    localSpatial.setAudioRecvRange(50);

    // Set the length of unit distance in meters
    localSpatial.setDistanceUnit(1);

    // Define the position of the local user
    var pos = [0.0, 0.0, 0.0];
    var axisForward = [1.0, 0.0, 0.0];
    var axisRight = [0.0, 1.0, 0.0];
    var axisUp = [0.0, 0.0, 1.0];

    // Set the position of the local user
    localSpatial.updateSelfPosition(
        position: pos, // The coordinates in the world coordinate system.
        axisForward: axisForward, // The unit vector of the x axis
        axisRight: axisRight, // The unit vector of the y axis
        axisUp: axisUp // The unit vector of the z axis
    );
  }

  void updateRemotePosition(int remoteUid, double front, double right, double top) {
    // Define the remote user's spatial position
    RemoteVoicePositionInfo positionInfo = RemoteVoicePositionInfo(
      position: [front, right, top],
      forward: [0.0, 0.0, -1.0],
    );

    // Update the spatial position of a remote user
    localSpatial.updateRemotePosition(
        uid: remoteUid,
        posInfo: positionInfo);
  }

  @override
  Future<void> setupAgoraEngine() async {
    await super.setupAgoraEngine();
    configureSpatialAudioEngine();
  }
}