import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'agora_manager_multiple_channels.dart';

class MultipleChannelsScreen extends StatefulWidget {
  final ProductName selectedProduct;
  const MultipleChannelsScreen({Key? key, required this.selectedProduct})
      : super(key: key);

  @override
  MultipleChannelsScreenState createState() => MultipleChannelsScreenState();
}

class MultipleChannelsScreenState extends State<MultipleChannelsScreen>
    with UiHelper {
  late AgoraManagerMultipleChannels agoraManager;
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
            title: const Text('MultipleChannels'),
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
              ElevatedButton(
                child: agoraManager.relayState == ChannelMediaRelayState.relayStateRunning
                    ? const Text("Stop Channel media relay")
                    : agoraManager.relayState == ChannelMediaRelayState.relayStateConnecting
                    ? const Text("Channel media relay connecting ...")
                    : const Text("Start channel media relay"),
                onPressed: () => {channelRelay()},
              ),
              ElevatedButton(
                  child: !agoraManager.isSecondChannelJoined
                      ? const Text("Join second channel")
                      : const Text("Leave second channel"),
                  onPressed:  () => {joinSecondChannel()}
              ),
              Container(
                height: 240,
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: _secondVideoPanel()),
              ),
            ],
          )),
    );
  }

  void channelRelay() async {
    if (agoraManager.isMediaRelaying) {
      agoraManager.stopChannelRelay();
    } else {
      agoraManager.startChannelRelay();
    }
  }

  void joinSecondChannel() async {

  }

  Widget _secondVideoPanel() {
    return const Text('Second video');
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManagerMultipleChannels.create(
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
      case "onChannelMediaRelayStateChanged":
        setState(() {

        });
        break;
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
