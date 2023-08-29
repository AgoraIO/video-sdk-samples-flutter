import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/ensure-channel-quality/agora_manager_call_quality.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class CallQualityScreen extends StatefulWidget {
  final ProductName selectedProduct;

  const CallQualityScreen({Key? key, required this.selectedProduct})
      : super(key: key);

  @override
  CallQualityScreenState createState() => CallQualityScreenState();
}

class CallQualityScreenState extends State<CallQualityScreen> with UiHelper {
  late AgoraManagerCallQuality agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  String videoCaption = "";
  bool isEchoTestRunning = false;

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
            title: const Text('Call quality best practice'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              mainVideoWithTextOverlay(), // The main video frame
              scrollVideoView(), // Scroll view with multiple videos
              radioButtons(), // Choose host or audience
              const SizedBox(height: 5),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: isEchoTestRunning
                      ? null // Disable the button
                      : agoraManager.isJoined
                          ? () => leave()
                          : () => join(),
                  child: Text(agoraManager.isJoined ? "Leave" : "Join"),
                ),
              ),
              ElevatedButton(
                onPressed: agoraManager.isJoined
                    ? null // Disable the button
                    : () => echoTest(),
                child: isEchoTestRunning
                    ? const Text("Stop Echo Test")
                    : const Text("Start Echo Test"),
              ),
              const SizedBox(height: 8),
              _networkStatus(),
            ],
          )),
    );
  }

  void echoTest() {
    if (isEchoTestRunning) {
      agoraManager.stopEchoTest();
      setState(() {
        isEchoTestRunning = false;
        //mainViewUid = -1;
      });
    } else {
      agoraManager.startEchoTest();
      setState(() {
        isEchoTestRunning = true;
        //mainViewUid = 0;
      });
    }
  }

  Widget _networkStatus() {
    Color statusColor;
    if (agoraManager.networkQuality > 0 && agoraManager.networkQuality < 3) {
      statusColor = Colors.green;
    } else if (agoraManager.networkQuality <= 4) {
      statusColor = Colors.yellow;
    } else if (agoraManager.networkQuality <= 6) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.grey;
    }

    return Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
      const Text("Network status: "),
      CircleAvatar(
        foregroundColor: Colors.grey,
        backgroundColor: statusColor,
        radius: 10,
        child: Text(agoraManager.networkQuality.toString()),
      )
    ]);
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManagerCallQuality.create(
      currentProduct: widget.selectedProduct,
      messageCallback: showMessage,
      eventCallback: eventCallback,
    );

    setState(() {
      initializeUiHelper(agoraManager, setStateCallback);
      isAgoraManagerInitialized = true;
    });

    // Start the probe test

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

  Widget mainVideoWithTextOverlay() {
    String overlayText = getOverlayText();
    return Stack(
      children: [
        mainVideoView(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(overlayText.isEmpty ? 0 : 0.3),
            padding: const EdgeInsets.all(8.0),
            child: Text(
              overlayText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  String getOverlayText() {
    if (agoraManager.isJoined) {
      return videoCaption;
    } else {
      return "";
    }
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

      case 'onRemoteVideoStats':
        RemoteVideoStats stats = eventArgs["stats"];
        setState(() {
          if (mainViewUid == stats.uid) {
            videoCaption = agoraManager.remoteVideoStatsSummary;
          } else {
            videoCaption = "";
          }
        });
        break;

      case 'onUserJoined':
        onUserJoined(eventArgs["remoteUid"]);
        break;

      case 'onUserOffline':
        onUserOffline(eventArgs["remoteUid"]);
        break;

      case 'onJoinChannelSuccess':
      case 'onLastmileQuality':
      case 'onNetworkQuality':
        setState(() {});
        break;
    }
  }

  @override
  void handleVideoTap(int remoteUid) {
    // Switch to low quality for the remote video going out of the main view
    if (mainViewUid > 0) {
      agoraManager.setVideoQuality(mainViewUid, false);
    }

    setState(() {
      // Switch video
      mainViewUid = remoteUid;
      videoCaption = "";
    });

    // Switch to high quality for the video in the main view
    if (remoteUid > 0) {
      agoraManager.setVideoQuality(remoteUid, true);
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
