import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'agora_manager_play_media.dart';

class PlayMediaScreen extends StatefulWidget {
  final ProductName selectedProduct;
  const PlayMediaScreen({Key? key, required this.selectedProduct})
      : super(key: key);

  @override
  PlayMediaScreenState createState() => PlayMediaScreenState();
}

class PlayMediaScreenState extends State<PlayMediaScreen> with UiHelper {
  late AgoraManagerPlayMedia agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  // Build UI
  @override
  Widget build(BuildContext context) {
    if (!isAgoraManagerInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Stream media to a channel'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              mainVideoView(), // The main video frame
              scrollVideoView(), // Scroll view with multiple videos
              radioButtons(), // Choose host or audience
              const SizedBox(height: 5),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed:
                      agoraManager.isJoined ? () => {leave()} : () => {join()},
                  child: Text(agoraManager.isJoined ? "Leave" : "Join"),
                ),
              ),
              _mediaPLayerButton(),
              Slider(
                  value: agoraManager.seekPos.toDouble(),
                  min: 0,
                  max: agoraManager.duration.toDouble(),
                  divisions: 100,
                  label: '${(agoraManager.seekPos / 1000.round())} s',
                  onChanged: (double value) {
                    agoraManager.seekPos = value.toInt();
                    agoraManager.seek(agoraManager.seekPos);
                    setState(() {});
                  }),
              _mediaPreview(),
            ],
          )),
    );
  }

  Widget _mediaPLayerButton() {
    String caption = "";

    if (!agoraManager.isUrlOpened) {
      caption = "Open media file";
    } else if (agoraManager.isPaused) {
      caption = "Resume playing media";
    } else if (agoraManager.isPlaying) {
      caption = "Pause playing media";
    } else {
      caption = "Play media file";
    }

    return ElevatedButton(
      onPressed: agoraManager.isJoined ? () => {playMedia()} : null,
      child: Text(caption),
    );
  }

  Future<void> join() async {
    await agoraManager.joinChannelWithToken();
  }

  void playMedia() async {
    if (!agoraManager.isUrlOpened) {
      await agoraManager.initializeMediaPlayer();
      // Open the media file
      agoraManager.openMediaFile();
    } else if (agoraManager.isPaused) {
      // Resume playing
      agoraManager.resumePlaying();
    } else if (agoraManager.isPlaying) {
      // Pause media player
      agoraManager.pausePlaying();
    } else {
      // Play the loaded media file
      // The functions returns an AgoraVideoView for displaying the video locally
      setState(() {
        agoraManager.playMediaFile();
      });
    }
  }

  Widget _mediaPreview() {
    if (agoraManager.isJoined && agoraManager.isPlaying) {
      return Container(
          height: 150,
          decoration: BoxDecoration(border: Border.all()),
          margin: const EdgeInsets.only(bottom: 5),
          child: Center(
              child: agoraManager.getPlayerView()
              )
        );
    } else {
      return Container();
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManagerPlayMedia.create(
      currentProduct: widget.selectedProduct,
      messageCallback: showMessage,
      eventCallback: eventCallback,
    );

    setState(() {
      initializeUiHelper(agoraManager, setStateCallback);
      isAgoraManagerInitialized = true;
    });
  }

  // Release the resources when you leave
  @override
  Future<void> dispose() async {
    agoraManager.dispose();
    super.dispose();
  }

  void eventCallback(String eventName, Map<String, dynamic> eventArgs) {
    // Handle the event based on the event name and named arguments
    switch (eventName) {

      case 'onPlayerSourceStateChanged':
        setState(() {});
        break;
      case 'onPositionChanged':
        setState(() {});
        break;

      case 'onConnectionStateChanged':
        // Connection state changed
        if (eventArgs["reason"] ==
            ConnectionChangedReasonType.connectionChangedLeaveChannel) {
          setState(() {});
        }
        break;

      case 'onJoinChannelSuccess':
        setState(() {});
        break;

      case 'onUserJoined':
        onUserJoined(eventArgs["remoteUid"]);
        break;

      case 'onUserOffline':
        onUserOffline(eventArgs["remoteUid"]);
        break;
    }
  }

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  void setStateCallback() {
    setState(() {});
  }
}
