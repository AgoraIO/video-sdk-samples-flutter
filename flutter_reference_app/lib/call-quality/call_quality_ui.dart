import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/call-quality/agora_manager_call_quality.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class CallQualityScreen extends StatefulWidget {
  final ProductName selectedProduct;

  const CallQualityScreen({Key? key, required this.selectedProduct}) : super(key: key);

  @override
  CallQualityScreenState createState() => CallQualityScreenState();
}

class CallQualityScreenState extends State<CallQualityScreen> with UiHelper {
  late AgoraManagerCallQuality agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  bool isHighQuality = true; // Quality of the remote video stream being played
  String videoCaption = "";

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
            title: const Text('Call quality'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              _networkStatus(),
              const SizedBox(height: 8),
              ElevatedButton(
                child: isHighQuality
                    ? const Text("Switch to low quality")
                    : const Text("Switch to high quality"),
                onPressed: () => {changeVideoQuality()},
              ),
              mainVideoView(), // Widget for local video
              scrollVideoView(), // Widget for Remote video
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
            ],
          )),
    );
  }

  void changeVideoQuality() {
    if (agoraManager.remoteUids.isNotEmpty) return;
    agoraManager.setVideoQuality(!isHighQuality);

    setState(() {
      isHighQuality = !isHighQuality;
    });
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
        foregroundColor: Colors.black,
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
    await agoraManager.setupVideoSDKEngine();

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
    await agoraManager.dispose();
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

      case 'onRemoteVideoStats':
        RemoteVideoStats stats = eventArgs["stats"];
        if (stats.uid == agoraManager.remoteUids[0]) {
          setState(() {
            videoCaption = agoraManager.qualityStatsSummary;
          });
        }
        break;

      case 'onLastmileQuality':
      case 'onNetworkQuality':
        setState(() {});
        break;

      case 'onJoinChannelSuccess':
        setState(() {});
        break;

      case 'onUserJoined':
        setState(() {});
        break;

      case 'onUserOffline':
        setState(() {});
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
