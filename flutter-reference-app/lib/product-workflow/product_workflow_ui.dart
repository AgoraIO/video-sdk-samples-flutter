import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'agora_manager_product_workflow.dart';

class ProductWorkflowScreen extends StatefulWidget {
  final ProductName selectedProduct;
  const ProductWorkflowScreen({Key? key, required this.selectedProduct})
      : super(key: key);

  @override
  ProductWorkflowScreenState createState() => ProductWorkflowScreenState();
}

class ProductWorkflowScreenState extends State<ProductWorkflowScreen>
    with UiHelper {
  late AgoraManagerProductWorkflow agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  int volume = 100;
  bool isMuted = false;
  bool isScreenShared = false;

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
            title: const Text('Screen sharing, volume control and mute'),
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
              volumeControl(),
              ElevatedButton(
                onPressed: agoraManager.isJoined ? () => {shareScreen()} : null,
                child: Text(
                    isScreenShared ? "Stop screen sharing" : "Share screen"),
              ),
              screenSharePreview(),
            ],
          )),
    );
  }

  Widget volumeControl() {
    return Row(
      children: <Widget>[
        Checkbox(
            value: isMuted,
            onChanged: (isMuted) => {onMuteChecked(isMuted!)}
        ),
        const Text("Mute"),
        Expanded(
          child: Slider(
            min: 0,
            max: 200,
            divisions: 20,
            label: 'Volume: $volume',
            value: volume.toDouble(),
            onChanged: (value) => {onVolumeChanged(value)},
          ),
        ),
      ],
    );
  }

  Widget screenSharePreview() {
    if (isScreenShared) {
      return agoraManager.getLocalScreenView();
    } else {
     return Container();
    }
  }

  void shareScreen() {
    isScreenShared = !isScreenShared;

    if (isScreenShared) {
      agoraManager.startScreenShare();
    } else {
      agoraManager.stopScreenShare();
    }

    setState(() {

    });
  }

  onMuteChecked(bool value) {
    setState(() {
      isMuted = value;
      agoraManager.mute(isMuted);
    });
  }

  onVolumeChanged(double newValue) {
    setState(() {
      volume = newValue.toInt();
      agoraManager.adjustVolume(volume);
    });
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManagerProductWorkflow.create(
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
}
