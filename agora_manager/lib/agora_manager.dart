library agora_manager;
import 'dart:convert';
import 'package:flutter/services.dart';

class AgoraManager {
  String appId = "", token = "", channelName = "";
  Function(String message) messageCallback;
  Function(String eventName, Map<String, dynamic> eventArgs) eventCallback;

  AgoraManager._({
    required this.messageCallback,
    required this.eventCallback,
  });

  static Future<AgoraManager> create({
    required Function(String message) messageCallback,
    required Function(String eventName, Map<String, dynamic> eventArgs) eventCallback,
  }) async {
    final manager = AgoraManager._(
      messageCallback: messageCallback,
      eventCallback: eventCallback,
    );

    await manager._initialize();
    return manager;
  }

  Future<void> _initialize() async {
    try {
      String configString = await rootBundle.loadString('packages/agora_manager/assets/config/config.json');
      Map<String, dynamic> configData = jsonDecode(configString);
      appId = configData['appId'];
      token = configData['token'];
    } catch (e) {
      messageCallback(e.toString());
      // Handle any errors that occur during the reading or parsing of the config file
    }
  }
}

/*
class AgoraManager {
  String appId="", token="", channelName = "";
  Function(String message) messageCallback;
  Function(String eventName, Map<String, dynamic> eventArgs) eventCallback;

  // Constructor
  AgoraManager({
    required this.messageCallback,
    required this.eventCallback,
  }) async {
    await readConfig();
  }

  Future<void> readConfig() async {
    try {
      String configString = await rootBundle.loadString('packages/agora_manager/assets/config/config.json');
      Map<String, dynamic> configData = jsonDecode(configString);
      
      appId = configData['appId'];
      token = configData['token'];
    } catch (e) {
      messageCallback(e.toString());
      // Handle any errors that occur during the reading or parsing of the config file
    }
  }
}
*/