import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';

class UiHelper {
  late AgoraManager _agoraManager;
  late VoidCallback _setStateCallback;
  int mainViewUid = -1;
  List<int> scrollViewUids = [];

  void initializeUiHelper(
      AgoraManager agoraManager, VoidCallback setStateCallback) {
    _agoraManager = agoraManager;
    _setStateCallback = setStateCallback;
  }

  Future<void> leave() async {
    await _agoraManager.leave();
    mainViewUid = -1;
    scrollViewUids.clear();
  }

  // Display local video preview
  Widget mainVideoView() {
    if (_agoraManager.currentProduct == ProductName.voiceCalling) {
      return Container();
    } else if (_agoraManager.isJoined) {
      if (mainViewUid == -1 && _agoraManager.isBroadcaster) {
        // Initialize local video in the main view
        mainViewUid = 0;
      } else if (mainViewUid == -1) {
        return textContainer("Waiting for a host to join", 240);
      }
      return Container(
          height: 240,
          decoration: BoxDecoration(border: Border.all()),
          margin: const EdgeInsets.only(bottom: 5),
          child: Center(
              child: mainViewUid == 0
                  ? _agoraManager.localVideoView()
                  : _agoraManager.remoteVideoView(mainViewUid)));
    } else {
      return textContainer('Join a channel', 240);
    }
  }

  Widget textContainer(String text, double height) {
    return Container(
        height: height,
        decoration: BoxDecoration(border: Border.all()),
        margin: const EdgeInsets.only(bottom: 5),
        child: Center(child: Text(text, textAlign: TextAlign.center)));
  }

  // Display remote user's video
  Widget scrollVideoView() {
    if (_agoraManager == null
        || _agoraManager.currentProduct != ProductName.videoCalling) {
      return Container();
    } else if (_agoraManager.remoteUids.isEmpty) {
      return textContainer(
          _agoraManager.isJoined
              ? 'Waiting for a remote user to join'
              : 'Join a channel',
          120);
    } else if (_agoraManager.isBroadcaster &&
        (_agoraManager.currentProduct == ProductName.interactiveLiveStreaming ||
            _agoraManager.currentProduct == ProductName.broadcastStreaming)) {
      return Container();
    }

    if (_agoraManager.agoraEngine == null) return textContainer("", 240);

    // Create a list of Uids for videos in the scroll view
    scrollViewUids.clear();
    scrollViewUids.addAll(_agoraManager.remoteUids);
    scrollViewUids
        .remove(mainViewUid); // This video is displayed in the main view
    if (mainViewUid > 0) {
      scrollViewUids.add(0); // Add local video to scroll view
    }

    return Container(
      height: 120, // Set the desired height
      decoration: BoxDecoration(border: Border.all()),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: scrollViewUids.length,
        itemBuilder: (context, index) {
          final uid = scrollViewUids[index]; // Get the remoteUid
          return GestureDetector(
            onTap: () {
              // Handle the onTap event for the container
              handleVideoTap(uid);
            },
            child: Container(
              width: 120, // Set the desired width
              margin: const EdgeInsets.fromLTRB(0, 3, 5, 3),
              child: uid == 0
                  ? _agoraManager.localVideoView()
                  : _agoraManager.remoteVideoView(uid),
            ),
          );
        },
      ),
    );
  }

  void handleVideoTap(int remoteUid) {
    mainViewUid = remoteUid;
    _setStateCallback();
  }

  Widget radioButtons() {
    // Radio Buttons
    if (_agoraManager.currentProduct == ProductName.interactiveLiveStreaming ||
        _agoraManager.currentProduct == ProductName.broadcastStreaming) {
      return Row(children: <Widget>[
        Radio<bool>(
          value: true,
          groupValue: _agoraManager.isBroadcaster,
          onChanged: (value) => _handleRadioValueChange(value),
        ),
        const Text('Host'),
        Radio<bool>(
          value: false,
          groupValue: _agoraManager.isBroadcaster,
          onChanged: (value) => _handleRadioValueChange(value),
        ),
        const Text('Audience'),
      ]);
    } else {
      return Container();
    }
  }

  void onUserOffline(int remoteUid) {
    if (mainViewUid == remoteUid) {
      mainViewUid = -1;
    }
    _setStateCallback();
  }

  void onUserJoined(int remoteUid) {
    if (!_agoraManager.isBroadcaster) {
      mainViewUid = remoteUid;
    }
    _setStateCallback();
  }

  // Set the client role when a radio button is selected
  void _handleRadioValueChange(bool? value) async {
    _agoraManager.isBroadcaster = (value == true);
    _setStateCallback();
    if (_agoraManager.isJoined) leave();
  }
}
