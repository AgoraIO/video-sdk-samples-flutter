import 'dart:async';
import 'package:call_quality/agora_manager_call_quality.dart';
import 'package:flutter/material.dart';
import 'package:agora_manager/agora_manager.dart';
import 'package:agora_manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with UiHelper {
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
              localPreview(), // Widget for local video
              remoteVideo(), // Widget for Remote video
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
    if (agoraManager.remoteUid == null) return;
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

// Display local video preview
  Widget _localPreview() {
    if (agoraManager.isBroadcaster) {
      return agoraManager.localVideoView();
    } else {
      return const Text(
        'Join a channel',
        textAlign: TextAlign.center,
      );
    }
  }

// Display remote user's video
  Widget _remoteVideo() {
    if (agoraManager.remoteUid != null) {
      try {
        return Stack(
          children: [
            agoraManager.remoteVideoView(),
            Positioned(
              bottom: 10,
              left: 10,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  videoCaption,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      } catch (e) {
        showMessage("error!");
        return const Text('error');
      }
    } else {
      return Text(
        agoraManager.isJoined ? 'Waiting for a remote user to join' : '',
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManagerCallQuality.create(
      currentProduct: ProductName.interactiveLiveStreaming,
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
        if (stats.uid == agoraManager.remoteUid) {
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
