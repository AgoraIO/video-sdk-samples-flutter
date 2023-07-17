import 'dart:async';
import 'package:authentication_workflow/signaling_manager_authentication.dart';
import 'package:flutter/material.dart';
import 'package:agora_manager/agora_manager.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late AgoraManagerAuthentication agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  final channelTextController =
      TextEditingController(text: ''); // To access the TextField
  bool isBroadcaster = true;

  bool _isJoined() {
    return isAgoraManagerInitialized ? agoraManager.isJoined : false;
  }

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
              TextField(
                controller: channelTextController,
                decoration: const InputDecoration(
                    hintText: 'Type the channel name here'),
              ),
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
              _radioButtons(),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _isJoined() ? () => {leave()} : () => {join()},
                  child: Text(_isJoined() ? "Leave" : "Join"),
                ),
              ),
            ],
          )),
    );
  }

  Widget _radioButtons() {
    // Radio Buttons
    if (isAgoraManagerInitialized &&
        (agoraManager.currentProduct == ProductName.interactiveLiveStreaming ||
            agoraManager.currentProduct == ProductName.broadcastStreaming)) {
      return Row(children: <Widget>[
        Radio<bool>(
          value: true,
          groupValue: isBroadcaster,
          onChanged: (value) => _handleRadioValueChange(value),
        ),
        const Text('Host'),
        Radio<bool>(
          value: false,
          groupValue: isBroadcaster,
          onChanged: (value) => _handleRadioValueChange(value),
        ),
        const Text('Audience'),
      ]);
    } else {
      return Container();
    }
  }

  // Set the client role when a radio button is selected
  void _handleRadioValueChange(bool? value) async {
    setState(() {
      isBroadcaster = (value == true);
      agoraManager.isBroadcaster = isBroadcaster;
    });
    if (agoraManager.isJoined) leave();
  }

// Display local video preview
  Widget _localPreview() {
    if (_isJoined() && isBroadcaster) {
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
    if (isAgoraManagerInitialized && agoraManager.remoteUid != null) {
      try {
        return agoraManager.remoteVideoView();
      } catch (e) {
        showMessage("error!");
        return const Text('error');
      }
    } else {
      return Text(
        _isJoined() ? 'Waiting for a remote user to join' : '',
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
    agoraManager = await AgoraManagerAuthentication.create(
      currentProduct: ProductName.videoCalling,
      messageCallback: showMessage,
      eventCallback: eventCallback,
    );
    await agoraManager.setupVideoSDKEngine();

    setState(() {
      isAgoraManagerInitialized = true;
    });
  }

  Future<void> join() async {
    String channelName = channelTextController.text;
    if (channelName.isEmpty) {
      showMessage("Enter a channel name");
      return;
    } else {
      showMessage("Fetching a token ...");
    }
    await agoraManager.fetchTokenAndJoin(channelName);
  }

  Future<void> leave() async {
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

      case 'onTokenPrivilegeWillExpire':
        // Renew the token
        agoraManager.renewToken();
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