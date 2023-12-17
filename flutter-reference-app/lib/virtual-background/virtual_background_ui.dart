import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'agora_manager_virtual_background.dart';

class VirtualBackgroundScreen extends StatefulWidget {
  final ProductName selectedProduct;
  const VirtualBackgroundScreen({Key? key, required this.selectedProduct})
      : super(key: key);

  @override
  VirtualBackgroundScreenState createState() => VirtualBackgroundScreenState();
}

class VirtualBackgroundScreenState extends State<VirtualBackgroundScreen>
    with UiHelper {
  late AgoraManagerVirtualBackground agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  int? selectedBackground = 0;

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
            title: const Text('Virtual background'),
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
              RadioListTile(
                title: const Text('No background'),
                value: 0,
                groupValue: selectedBackground,
                onChanged: agoraManager.isJoined ? setVirtualBackground : null,
              ),
              RadioListTile(
                title: const Text('Blur background'),
                value: 1,
                groupValue: selectedBackground,
                onChanged: agoraManager.isJoined ? setVirtualBackground : null,
              ),
              RadioListTile(
                title: const Text('Color background'),
                value: 2,
                groupValue: selectedBackground,
                onChanged: agoraManager.isJoined ? setVirtualBackground : null,
              ),
              RadioListTile(
                title: const Text('Image background'),
                value: 3,
                groupValue: selectedBackground,
                onChanged: agoraManager.isJoined ? setVirtualBackground : null,
              ),
            ],
          )),
    );
  }

  void setVirtualBackground(int? backgroundType) {

    setState(() {
      selectedBackground = backgroundType;
    });

    agoraManager.isFeatureAvailable().then((isFeatureAvailable) {
      if (!isFeatureAvailable) {
        showMessage(
            "Virtual background feature is not available on this device");
        return;
      }
    });

    // Set the type of virtual background
    if (backgroundType == 1) {
      agoraManager.setBlurBackground();
      showMessage("Setting blur background");
    } else if (backgroundType == 2) {
      // Set a solid background color
      agoraManager.setSolidBackground();
      showMessage("Setting color background");
    } else if (backgroundType == 3) {
      // Set a background image
      agoraManager.setImageBackground();
      showMessage("Setting image background");
    } else {
      agoraManager.removeBackground();
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManagerVirtualBackground.create(
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
