import 'dart:async';
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
  late AgoraManager agoraManager;
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
            title: const Text('Video SDK Quickstart'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
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

  @override
  void initState() {
    initialize();
    super.initState();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManager.create(
      currentProduct: ProductName.broadcastStreaming,
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
    await agoraManager.join();
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

      case 'onJoinChannelSuccess':
        setState(() {});
        break;

      case 'onUserJoined':
        setState(() {});
        break;

      case 'onUserOffline':
        setState(() {});
        break;

      default:
        // Handle unknown event or provide a default case
        showMessage('Event Name: $eventName, Event Args: $eventArgs');
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