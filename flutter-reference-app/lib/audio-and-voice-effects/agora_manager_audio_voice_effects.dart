import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_reference_app/authentication-workflow/agora_manager_authentication.dart';
import 'package:flutter_reference_app/agora-manager/agora_manager.dart';

class AgoraManagerAudioVoiceEffects extends AgoraManagerAuthentication {
  AgoraManagerAudioVoiceEffects({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) : super(
          currentProduct: currentProduct,
          messageCallback: messageCallback,
          eventCallback: eventCallback,
        ) {
    // Additional initialization specific to AgoraManagerAudioVoiceEffects
  }

  static Future<AgoraManagerAudioVoiceEffects> create({
    required ProductName currentProduct,
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs)
        eventCallback,
  }) async {
    final manager = AgoraManagerAudioVoiceEffects(
      currentProduct: currentProduct,
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager.initialize();
    return manager;
  }

  @override
  Future<void> setupAgoraEngine() async {
    super.setupAgoraEngine();

    // Specify the audio profile and scenario
    agoraEngine?.setAudioProfile(profile: AudioProfileType.audioProfileMusicHighQualityStereo);
    agoraEngine?.setAudioScenario(AudioScenarioType.audioScenarioGameStreaming);
  }

  void startMixing(String filePath, bool loopback, int startPos, int cycle) {
    agoraEngine?.startAudioMixing(
        filePath: filePath,
        loopback: loopback,
        startPos: startPos,
        cycle: cycle);
    }

  void stopMixing() {
    agoraEngine?.stopAudioMixing();
  }

  void resumeEffect(int soundEffectId) {
    agoraEngine?.resumeEffect(soundEffectId);
  }

  void pauseEffect(int soundEffectId) {
    agoraEngine?.pauseEffect(soundEffectId);
  }

  void playEffect (int soundEffectId, String soundEffectFilePath) {

    agoraEngine?.preloadEffect(soundId: soundEffectId, filePath: soundEffectFilePath);

    agoraEngine?.playEffect(
        soundId: soundEffectId,
        filePath: soundEffectFilePath,
        publish: true,
        loopCount: 0,
        pitch: 1,
        pan: 0,
        gain: 100
    );
  }

  void setVoiceBeautifierPreset(VoiceBeautifierPreset voiceBeautifierPreset) {
    // Use a preset value, for example VoiceBeautifierPreset.chatBeautifierMagnetic
    agoraEngine?.setVoiceBeautifierPreset(voiceBeautifierPreset);
  }

  void setAudioEffectPreset(AudioEffectPreset audioEffectPreset) {
    // Use a preset value, for example AudioEffectPreset.voiceChangerEffectHulk
    agoraEngine?.setAudioEffectPreset(audioEffectPreset);
  }

  void setVoiceConversionPreset(VoiceConversionPreset voiceConversionPreset) {
    // Use a preset value, for example VoiceConversionPreset.voiceChangerCartoon
    agoraEngine?.setVoiceConversionPreset(voiceConversionPreset);
  }

  void setLocalVoiceEqualization(AudioEqualizationBandFrequency bandFrequency, int bandGain) {
    agoraEngine?.setLocalVoiceEqualization(
      // Sets local voice equalization.
        bandFrequency: bandFrequency, // Center frequency of the band, for example AudioEqualizationBandFrequency.audioEqualizationBand4k
        bandGain: bandGain // Sets the gain of each band between -15 and 15 dB, default value is 0.
    );
  }

  void setLocalVoicePitch(double voicePitch) {
    // The value range is [0.5,2.0] default value is 1.0
    agoraEngine?.setLocalVoicePitch(voicePitch);
  }

  void setLocalVoiceFormant(double formantRatio) {
    // Range is [-1.0, 1.0], [giant, child] default value is 0
    agoraEngine?.setLocalVoiceFormant(formantRatio);
  }

  void setAudioRoute(bool enableSpeakerPhone) {
    // Disable the default audio route
    agoraEngine?.setDefaultAudioRouteToSpeakerphone(false);
    // Enable or disable the speakerphone temporarily
    agoraEngine?.setEnableSpeakerphone(enableSpeakerPhone);
  }

  @override
  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      onAudioEffectFinished: (int soundId) {
        // Audio effect finished playing
        agoraEngine?.stopEffect(soundId);
        // Notify the UI
        Map<String, dynamic> eventArgs = {};
        eventArgs["soundId"] = soundId;
        eventCallback("onAudioEffectFinished", eventArgs);
      },
      onAudioMixingStateChanged: (AudioMixingStateType state,
          AudioMixingReasonType reason) {
        // Occurs when the playback state of the audio file changes
      },
      onAudioRoutingChanged: (int routing) {
        // Handle audio the routing change
      },
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        super.getEventHandler().onTokenPrivilegeWillExpire!(connection, token);
      },
      onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
        super.getEventHandler().onConnectionStateChanged!(connection, state, reason);
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        super.getEventHandler().onJoinChannelSuccess!(connection, elapsed);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        super.getEventHandler().onUserJoined!(connection, remoteUid, elapsed);
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        super.getEventHandler().onUserOffline!(connection, remoteUid, reason);
      },
    );
  }
}
