import 'dart:async';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

void main() => runApp(const MaterialApp(home: AuthenticationWorkflow()));

class AuthenticationWorkflow extends StatefulWidget {
  const AuthenticationWorkflow({Key? key}) : super(key: key);

  @override
  AuthenticationWorkflowState createState() => AuthenticationWorkflowState();
}

class AuthenticationWorkflowState extends State<AuthenticationWorkflow> with UiHelper {
  late AgoraManagerAuthentication agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  final channelTextController =
      TextEditingController(text: ''); // To access the TextField

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
            title: const Text('Authentication workflow'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              TextField(
                controller: channelTextController,
                decoration: const InputDecoration(
                    hintText: 'Type the channel name here'),
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

  Widget _radioButtons() {
    // Radio Buttons
    if (agoraManager.currentProduct == ProductName.interactiveLiveStreaming ||
        agoraManager.currentProduct == ProductName.broadcastStreaming) {
      return Align(
          alignment: Alignment.center,
          child: Row(children: <Widget>[
            Radio<bool>(
              value: true,
              groupValue: agoraManager.isBroadcaster,
              onChanged: (value) => _handleRadioValueChange(value),
            ),
            const Text('Host'),
            Radio<bool>(
              value: false,
              groupValue: agoraManager.isBroadcaster,
              onChanged: (value) => _handleRadioValueChange(value),
            ),
            const Text('Audience'),
          ]));
    } else {
      return Container();
    }
  }

  // Set the client role when a radio button is selected
  void _handleRadioValueChange(bool? value) async {
    setState(() {
      agoraManager.isBroadcaster = (value == true);
    });
    if (agoraManager.isJoined) leave();
  }

// Display local video preview
  Widget _localPreview() {
    if (agoraManager.isJoined && agoraManager.isBroadcaster) {
      return Container(
          height: 240,
          decoration: BoxDecoration(border: Border.all()),
          margin: const EdgeInsets.only(bottom: 5),
          child: Center(child: agoraManager.localVideoView()));
    } else if (!agoraManager.isBroadcaster &&
        (agoraManager.currentProduct == ProductName.interactiveLiveStreaming ||
            agoraManager.currentProduct == ProductName.broadcastStreaming)) {
      return Container();
    } else {
      return Container(
          height: 240,
          decoration: BoxDecoration(border: Border.all()),
          margin: const EdgeInsets.only(bottom: 16),
          child: const Center(
              child: Text('Join a channel', textAlign: TextAlign.center)));
    }
  }

// Display remote user's video
  Widget _remoteVideo() {
    if (agoraManager.isBroadcaster &&
        (agoraManager.currentProduct == ProductName.interactiveLiveStreaming ||
            agoraManager.currentProduct == ProductName.broadcastStreaming)) {
      return Container();
    }

    if (agoraManager.remoteUid != null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(border: Border.all()),
        margin: const EdgeInsets.only(bottom: 5),
        child: Center(child: agoraManager.remoteVideoView()),
      );
    } else {
      return Container(
          height: 240,
          decoration: BoxDecoration(border: Border.all()),
          margin: const EdgeInsets.only(bottom: 5),
          child: Center(
              child: Text(
                  agoraManager.isJoined
                      ? 'Waiting for a remote user to join'
                      : 'Join a channel',
                  textAlign: TextAlign.center)));
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
      initializeUiHelper(agoraManager, setStateCallback);
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
