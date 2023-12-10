import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'agora_manager_spatial_audio.dart';

class SpatialAudioScreen extends StatefulWidget {
  final ProductName selectedProduct;
  const SpatialAudioScreen({Key? key, required this.selectedProduct})
      : super(key: key);

  @override
  SpatialAudioScreenState createState() => SpatialAudioScreenState();
}

class SpatialAudioScreenState extends State<SpatialAudioScreen> with UiHelper {
  late AgoraManagerSpatialAudio agoraManager;
  bool isAgoraManagerInitialized = false;
  double front = 0.0, right = 0.0, top = 0.0;
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
            title: const Text('3D Spatial audio'),
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
              const SizedBox(height: 20),
              const Text('Move the sliders to update the remote user''s spatial position'),
              Slider(
                min: -20,
                max: 20,
                divisions: 20,
                value: front,
                label: 'Front: $front',
                onChanged: (value) {
                  setState(() {
                    front = value;
                  });
                  updatePosition();
                },
              ),
              Slider(
                min: -20,
                max: 20,
                divisions: 20,
                value: right,
                label: 'Right: $right',
                onChanged: (value) {
                  setState(() {
                    right = value;
                  });
                  updatePosition();
                },
              ),
              Slider(
                min: -20,
                max: 20,
                divisions: 20,
                value: top,
                label: 'Top: $top',
                onChanged: (value) {
                  setState(() {
                    top = value;
                  });
                  updatePosition();
                },
              ),
            ],
          )),
    );
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManagerSpatialAudio.create(
      currentProduct: widget.selectedProduct,
      messageCallback: showMessage,
      eventCallback: eventCallback,
    );

    setState(() {
      initializeUiHelper(agoraManager, setStateCallback);
      isAgoraManagerInitialized = true;
    });
  }

  Future<void> join() async {
    await agoraManager.joinChannelWithToken();
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

  void updatePosition() {
    if (agoraManager.remoteUids.isEmpty) return;
    agoraManager.updateRemotePosition(agoraManager.remoteUids.first, front, right , top);
  }

}
