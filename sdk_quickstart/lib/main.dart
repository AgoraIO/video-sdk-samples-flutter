import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_manager/agora_manager.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AgoraManager agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  bool _isJoined = false;
  int? _remoteUid;
  
  /*bool _isJoined {
    if (isAgoraManagerInitialized) {
      return agoraManager.isJoined;
    } else {
      return false;
    }
  } */

  // Build UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Get started with Video Calling'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              // Container for the local video
              Container(
                height: 240,
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: _localPreview()),
              ),
              const SizedBox(height: 10),
              //Container for the Remote video
              Container(
                height: 240,
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: _remoteVideo()),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed:
                      _isJoined ? () => {leave()} : () => {join()},
                  child: Text(_isJoined ? "Leave" : "Join"),
                ),
              ),
            ],
          )),
    );
  }

// Display local video preview
  Widget _localPreview() {
    if (_isJoined) {
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
    if (_remoteUid != null) {
      return agoraManager.remoteVideoView();
    } else {
      return Text(
        _isJoined ? 'Waiting for a remote user to join' : '',
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
    agoraManager = await AgoraManager.create(
      messageCallback: showMessage,
      eventCallback: eventCallback,
    );
    await agoraManager.setupVideoSDKEngine();

    setState(() {
      isAgoraManagerInitialized = true;
    });

  }

  Future<void> join() async {
    await agoraManager.join();
  }

  Future<void> leave() async {
    setState(() {
      _isJoined = false;
      _remoteUid = null;
    });
    await agoraManager.leave();
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
        if (eventArgs["reason"] == ConnectionChangedReasonType.connectionChangedLeaveChannel) {
          setState(() {
            _isJoined = false;
          });
        }
        break;

      case 'onJoinChannelSuccess':
        setState(() {
          _isJoined = true;
        });
        break;

      case 'onUserJoined':
        setState(() {
          _remoteUid = eventArgs["remoteUid"];
        });
        break;

      case 'onUserOffline':
        setState(() {
          _remoteUid = null;
        });
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
}
