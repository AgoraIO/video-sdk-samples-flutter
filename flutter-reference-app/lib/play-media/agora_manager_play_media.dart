import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManagerPlayMedia extends AgoraManagerAuthentication {
  late final MediaPlayerController _mediaPlayerController;
  String mediaLocation = ""; // Set the location in the config file
  bool isUrlOpened = false; // Media file has been opened
  bool isPlaying = false; // Media file is playing
  bool isPaused = false; // Media player is paused
  int duration = 0; // Total duration of the loaded media file
  int seekPos = 0; // Current play position

  AgoraManagerPlayMedia({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerPlayMedia
  }

  static Future<AgoraManagerPlayMedia> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerPlayMedia(
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

  void openMediaFile() {
    mediaLocation = config['sampleMediaUrl'];
    _mediaPlayerController.open(url:mediaLocation, startPos:0);
  }

  @override
  Future<void> leave() async {
    // Dispose the media player
    _mediaPlayerController.dispose();

    isUrlOpened = false;
    isPlaying = false;
    isPaused = false;
    duration = 0;
    seekPos = 0;
    super.leave();


    agoraEngine = null;
  }

  void playMediaFile() {
    // Play the loaded media file
    _mediaPlayerController.play();
    isPlaying = true;
    updateChannelPublishOptions(true);
  }

  void pausePlaying() {
    _mediaPlayerController.pause();
    isPaused = true;
  }

  void resumePlaying() {
    _mediaPlayerController.resume();
    isPaused = false;
  }


  Future<void> initializeMediaPlayer() async {
    _mediaPlayerController= MediaPlayerController(
        rtcEngine: agoraEngine!,
        useAndroidSurfaceView: true,
        canvas: VideoCanvas(uid: localUid,
            sourceType: VideoSourceType.videoSourceMediaPlayer
        )
    );

    await _mediaPlayerController.initialize();

    _mediaPlayerController.registerPlayerSourceObserver(
      MediaPlayerSourceObserver(
        onCompleted: () {

        },
        onPlayerSourceStateChanged:
            (MediaPlayerState state, MediaPlayerError ec) async {
          messageCallback(state.name);

          if (state == MediaPlayerState.playerStateOpenCompleted) {
            // Media file opened successfully
            duration = await _mediaPlayerController.getDuration();
              isUrlOpened = true;
          } else if (state == MediaPlayerState.playerStatePlaybackAllLoopsCompleted) {
            // Media file finished playing
              isPlaying = false;
              seekPos = 0;
              // Restore camera and microphone streams
              updateChannelPublishOptions(isPlaying);
          }
          // Notify the UI
          Map<String, dynamic> eventArgs = {};
          // eventArgs["connection"] = connection;
          eventCallback("onPlayerSourceStateChanged", eventArgs);
        },
        onPositionChanged: (int position) {
            seekPos = position;
            // Notify the UI
            Map<String, dynamic> eventArgs = {};
            eventCallback("onPositionChanged", eventArgs);
        },
        onPlayerEvent:
            (MediaPlayerEvent eventCode, int elapsedTime, String message) {
          // Other events
        },
      ),
    );
  }

  void updateChannelPublishOptions(bool publishMediaPlayer) {
    ChannelMediaOptions channelOptions = ChannelMediaOptions(
        publishMediaPlayerAudioTrack: publishMediaPlayer,
        publishMediaPlayerVideoTrack: publishMediaPlayer,
        publishMicrophoneTrack: !publishMediaPlayer,
        publishCameraTrack: !publishMediaPlayer,
        publishMediaPlayerId: _mediaPlayerController.getMediaPlayerId());

    agoraEngine!.updateChannelMediaOptions(channelOptions);
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

  void seek(int seekPos) {
    _mediaPlayerController.seek(seekPos);
  }

  AgoraVideoView getPlayerView() {
    return AgoraVideoView(
      controller: _mediaPlayerController,
    );
  }

}
