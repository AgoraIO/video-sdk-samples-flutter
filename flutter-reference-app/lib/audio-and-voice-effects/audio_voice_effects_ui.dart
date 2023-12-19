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
    'Voice effect: Adjust formant',
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
            title: const Text('Audio and voice effects'),
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
        agoraManager.startMixing(audioFilePath, false, 0, -1);
        showMessage("Mixing audio");
      } on Exception catch(e) {
        showMessage("Exception playing audio\n ${e.toString()}");
      }
    } else {
      agoraManager.stopMixing();
    }
  }

  void playSoundEffect() {
    if(isEffectPlaying){
      if (isEffectPaused){
        agoraManager.resumeEffect(soundEffectId);
        setState(() {
          isEffectPaused = false;
        });
      } else {
        agoraManager.pauseEffect(soundEffectId);
        setState(() {
          isEffectPaused = true;
        });
      }
    } else {
      setState(() {
        isEffectPlaying = true;
      });
      agoraManager.playEffect(soundEffectId, soundEffectFilePath);
    }
  }

  void applyVoiceEffect() {
    setState(() {
      voiceEffectIndex++;
    });

    if (voiceEffectIndex == 1) {
      agoraManager.setVoiceBeautifierPreset(VoiceBeautifierPreset.chatBeautifierMagnetic);
    } else if (voiceEffectIndex == 2) {
      agoraManager.setVoiceBeautifierPreset(VoiceBeautifierPreset.singingBeautifier);
    } else if (voiceEffectIndex == 3) {
      // Remove previous effect
      agoraManager.setVoiceBeautifierPreset(VoiceBeautifierPreset.voiceBeautifierOff);
      // Change voice formant
      agoraManager.setLocalVoiceFormant(0.6);
    } else if (voiceEffectIndex == 4) {
      // Remove previous effect
      agoraManager.setLocalVoiceFormant(0.0);
      // Apply a voice changer effect
      agoraManager.setAudioEffectPreset(AudioEffectPreset.voiceChangerEffectHulk);
    } else if (voiceEffectIndex == 5) {
      // Remove previous effect
      agoraManager.setAudioEffectPreset(AudioEffectPreset.audioEffectOff);
      // Apply a voice conversion preset
      agoraManager.setVoiceConversionPreset(VoiceConversionPreset.voiceChangerCartoon);
    } else if (voiceEffectIndex == 6) {
      // Remove previous effect
      agoraManager.setVoiceConversionPreset(VoiceConversionPreset.voiceConversionOff);
      // Set local voice equalization
      agoraManager.setLocalVoiceEqualization(
          AudioEqualizationBandFrequency.audioEqualizationBand1k,
          5
      );
      agoraManager.setLocalVoicePitch(0.5);
    } else if (voiceEffectIndex > 6) { // Remove all effects
      voiceEffectIndex = 0;
      // Remove voice equalization and pitch modification
      agoraManager.setLocalVoicePitch(1.0);
      agoraManager.setLocalVoiceEqualization(
          AudioEqualizationBandFrequency.audioEqualizationBand1k,
          0
      );
    }
  }

  void changeAudioRoute(bool newValue) {
    setState(() {
      isSwitched = newValue;
    });
    agoraManager.setAudioRoute(isSwitched);
  }

  void eventCallback(String eventName, Map<String, dynamic> eventArgs) {
    // Handle the event based on the event name and named arguments
    switch (eventName) {
      case "onAudioEffectFinished":
        setState(() {
          isEffectPlaying = false;
        });
        showMessage("Audio effect finished playing");
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
