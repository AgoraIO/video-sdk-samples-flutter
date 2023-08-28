import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_manager/agora_manager.dart';

class UiHelper {
  late AgoraManager _agoraManager;
  late VoidCallback _setStateCallback;

  void initializeUiHelper(
      AgoraManager agoraManager, VoidCallback setStateCallback) {
    _agoraManager = agoraManager;
    _setStateCallback = setStateCallback;
  }

  Future<void> leave() async {
    await _agoraManager.leave();
  }

  // Display local video preview
  Widget localPreview() {
    if (_agoraManager.isJoined && _agoraManager.isBroadcaster) {
      return Container(
          height: 240,
          decoration: BoxDecoration(border: Border.all()),
          margin: const EdgeInsets.only(bottom: 5),
          child: Center(child: _agoraManager.localVideoView()));
    } else if (!_agoraManager.isBroadcaster &&
        (_agoraManager.currentProduct == ProductName.interactiveLiveStreaming ||
            _agoraManager.currentProduct == ProductName.broadcastStreaming)) {
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
  Widget remoteVideo() {
    if (_agoraManager.isBroadcaster &&
        (_agoraManager.currentProduct == ProductName.interactiveLiveStreaming ||
            _agoraManager.currentProduct == ProductName.broadcastStreaming)) {
      return Container();
    }

    if (_agoraManager.remoteUid != null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(border: Border.all()),
        margin: const EdgeInsets.only(bottom: 5),
        child: Center(child: _agoraManager.remoteVideoView()),
      );
    } else {
      return Container(
          height: 240,
          decoration: BoxDecoration(border: Border.all()),
          margin: const EdgeInsets.only(bottom: 5),
          child: Center(
              child: Text(
                  _agoraManager.isJoined
                      ? 'Waiting for a remote user to join'
                      : 'Join a channel',
                  textAlign: TextAlign.center)));
    }
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

  // Set the client role when a radio button is selected
  void _handleRadioValueChange(bool? value) async {
    _agoraManager.isBroadcaster = (value == true);
    _setStateCallback();
    if (_agoraManager.isJoined) leave();
  }
}
