import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';
import 'package:flutter_reference_app/agora-manager/ui_helper.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'agora_manager_audio_voice_effects.dart';

class AudioVoiceEffectsScreen extends StatefulWidget {
  final ProductName selectedProduct;
  const AudioVoiceEffectsScreen({Key? key, required this.selectedProduct})
      : super(key: key);

  @override
  AudioVoiceEffectsScreenState createState() => AudioVoiceEffectsScreenState();
}

class AudioVoiceEffectsScreenState extends State<AudioVoiceEffectsScreen>
    with UiHelper {
  late AgoraManagerAudioVoiceEffects agoraManager;
  bool isAgoraManagerInitialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  int soundEffectStatus = 0;
  int soundEffectId = 1; // Unique id for the sound effect file
  String soundEffectFilePath = // URL or path to the sound effect
      "https://www.soundjay.com/human/applause-01.mp3";
  String audioFilePath = // URL or path to the audio mixing file
      "https://www.kozco.com/tech/organfinale.mp3";

  int voiceEffectIndex = 0;
  bool isAudioPlaying = false; // Manage the audio mixing state
  bool isEffectPlaying = false;
  bool isEffectPaused = false;
  bool isSwitched = true; // Manage the audio route

  var effectCaptions = [
    'Apply voice effect',
    'Voice effect: Chat Beautifier',
    'Voice effect: Singing Beautifier',
    'Audio effect: Hulk',
    'Audio effect: Voice Changer',
    'Audio effect: Voice Equalization'
  ];

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
            title: const Text('AudioVoiceEffects'),
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
                onPressed:agoraManager.isJoined ? () => {audioMixing()} : null,
                child: Text(isAudioPlaying ? "Stop audio mixing"
                    : "Start audio mixing"),
              ),
              ElevatedButton(
                onPressed: agoraManager.isJoined ? () => {playSoundEffect()} : null,
                child: isEffectPlaying ?
                (isEffectPaused ? const Text("Resume audio effect")
                    : const Text("Pause audio effect"))
                    : const Text("Play audio effect"),
              ),
              ElevatedButton(
                onPressed: agoraManager.isJoined ? () => {applyVoiceEffect()} : null,
                child: Text(effectCaptions[voiceEffectIndex]),
              ),
              Row(children: [
                const Text("Enable speakerphone"),
                Switch(
                  value: isSwitched,
                  onChanged: (bool newValue) => {changeAudioRoute(newValue)},
                ),
              ]),
            ],
          )),
    );
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Set up an instance of AgoraManager
    agoraManager = await AgoraManagerAudioVoiceEffects.create(
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

  void audioMixing() {
    setState(() {
      isAudioPlaying = !isAudioPlaying;
    });

    if (isAudioPlaying) {
      try {
        agoraEngine.startAudioMixing(filePath: audioFilePath,
            loopback: false,
            replace: false,
            cycle: -1);
        showMessage("Mixing audio");
      } on Exception catch(e) {
        showMessage("Exception playing audio\n ${e.toString()}");
      }
    } else {
      agoraEngine.stopAudioMixing();
    }
  }

  void playSoundEffect() {
    if(isEffectPlaying){
      if (isEffectPaused){
        agoraEngine.resumeEffect(soundEffectId);
        setState(() {
          isEffectPaused = false;
        });
      } else {
        agoraEngine.pauseEffect(soundEffectId);
        setState(() {
          isEffectPaused = true;
        });
      }
    } else {
      setState(() {
        isEffectPlaying = true;
      });

      agoraEngine.playEffect(
          soundId: soundEffectId,
          filePath: soundEffectFilePath,
          publish: true,
          loopCount: 0,
          pitch: 1,
          pan: 0,
          gain: 100
      );
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
